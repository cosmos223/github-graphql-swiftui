//
//  IssueDetailView.swift
//  github graphql swiftui
//
//  Created by 矢島良乙 on 2025/05/23.
//

import SwiftUI
import GitHubSchema
import MarkdownUI

struct EditComment: Identifiable {
    let id = UUID()
    let commentId: ID
    let commentBody: String
}

struct EditIssue: Identifiable {
    let id = UUID()
    let issueTitle: String
    let issueBody: String
}

struct IssueDetailView: View {
    
    @Environment(\.presentationMode) var presentationMode
    
    var issueId: ID!
    
    private let apollo = GraphQLClient.shared.apollo
    
    @State var titleText: String!
    @State var bodyMarkdown: String?
    @State var auther: String?
    @State var autherAvatorURL: URI?
    
    @State private var canUpdate: Bool?
    @State private var canDelete: Bool?
    
    @State var loading = true
    
    @State var comments: [GetIssueAndCommentsByIDQuery.Data.Node.AsIssue.Comments.Node] = []
    
    @State private var isShowingSheet = false
    
    @State private var isShowAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var alertOkAction: (() -> Void)?
    
    @State private var isShowCommentDeleteAlert = false
    @State private var targetCommentId: ID!
    @State private var targetComment: EditComment?
    
    @State private var isShowIssueDeleteAlert = false
    
    @State private var issueTitleAndBody: EditIssue?
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 8) {
                
                // 第一のデータ構造に基づくView
                GroupBox {
                    HStack {
                        Text(auther ?? "")
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Divider()
                    if let bodyMarkdown = bodyMarkdown {
                        Markdown(bodyMarkdown.isEmpty ? "_No description provided._" : bodyMarkdown)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Markdown("loading...")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .backgroundStyle(Color(.systemBackground))
                
                // 第二のデータ構造に基づくView
                ForEach(comments, id: \.id) { comment in
                    commentView(comment: comment)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .alert(alertTitle, isPresented: $isShowAlert) {
            if alertOkAction != nil {
                Button("OK") {
                    alertOkAction!()
                    alertOkAction = nil
                }
            }
        } message: {
            Text(alertMessage)
        }
        .alert("このコメントを削除しますか。", isPresented: $isShowCommentDeleteAlert) {
            Button("はい", role: .destructive) {
                apollo.perform(mutation: GitHubSchema.DeleteIssueCommentMutation(id: targetCommentId)) { result in
                    switch result {
                    case .success(_):
                        alertTitle = ""
                        alertMessage = "削除されました"
                        alertOkAction = {
                            comments.removeAll { $0.id == targetCommentId }
                        }
                        isShowAlert = true
                    case .failure(let error):
                        alertTitle = "エラー"
                        alertMessage = error.localizedDescription
                        isShowAlert = true
                    }
                }
            }
            Button("いいえ", role: .cancel) {}
        } message: {
            Text("この操作は取り消せません。")
        }
        .alert("このIssueを削除しますか。", isPresented: $isShowIssueDeleteAlert) {
            Button("はい", role: .destructive) {
                apollo.perform(mutation: GitHubSchema.DeleteIssueMutation(issueId: issueId)) { result in
                    switch result {
                    case .success(_):
                        alertTitle = ""
                        alertMessage = "削除されました"
                        alertOkAction = {
                            presentationMode.wrappedValue.dismiss()
                        }
                        isShowAlert = true
                    case .failure(let error):
                        alertTitle = "エラー"
                        alertMessage = error.localizedDescription
                        isShowAlert = true
                    }
                }
            }
            Button("いいえ", role: .cancel) {}
        } message: {
            Text("この操作は取り消せません。")
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    isShowingSheet = true
                }) {
                    Image(systemName: "square.and.pencil")
                }
                .disabled(loading)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if let canUpdate = canUpdate, canUpdate {
                        Button(action: {
                            issueTitleAndBody = EditIssue(issueTitle: titleText, issueBody: bodyMarkdown ?? "")
                        }) {
                            HStack {
                                Image(systemName: "pencil")
                                Text("編集")
                            }
                        }
                    }
                    if let canDelete = canDelete, canDelete {
                        Button(action: {
                            isShowIssueDeleteAlert = true
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("削除")
                            }
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
                .disabled(!(canUpdate ?? false) && !(canDelete ?? false))
            }
        }
        .sheet(isPresented: $isShowingSheet, content: addCommentSheet)
        .sheet(item: $targetComment) { target in
            EditCommentView(commentId: target.commentId, bodyText: target.commentBody, onComplete: { updated in
                if updated {
                    reload()
                }
            })
        }
        .sheet(item: $issueTitleAndBody, content: editIssueSheet)
        .navigationTitle(titleText)
        .onAppear {
            loading = true
            apollo.fetch(query: GitHubSchema.GetIssueAndCommentsByIDQuery(id: issueId, after: nil), cachePolicy: .fetchIgnoringCacheData) { [self] result in
                guard let data = try? result.get().data else { return }
                titleText = data.node?.asIssue?.title
                bodyMarkdown = data.node?.asIssue?.body ?? ""
                comments = (data.node?.asIssue?.comments.nodes?.compactMap(\.!))!
                print(comments)
                auther = data.node?.asIssue?.author?.login
                autherAvatorURL = data.node?.asIssue?.author?.avatarUrl
                
                canUpdate = data.node?.asIssue?.viewerCanUpdate
                canDelete = data.node?.asIssue?.viewerCanDelete
                
                loading = false
            }
        }
    }
    
    @ViewBuilder
    private func editIssueSheet(issue: EditIssue) -> some View {
        EditIssueView(issueId: issueId, titleText: issue.issueTitle, bodyText: issue.issueBody, onComplete: { updated in
            if updated {
                reload()
            }
        })
    }
    
    @ViewBuilder
    private func addCommentSheet() -> some View {
        AddCommentView(isShowingSheet: $isShowingSheet, issueId: issueId, onComplete: { updated in
            if updated {
                reload()
            }
        })
    }
    
    @ViewBuilder
    private func commentView(comment: GetIssueAndCommentsByIDQuery.Data.Node.AsIssue.Comments.Node) -> some View {
        GroupBox {
            HStack {
                Text(comment.author?.login ?? "")
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
                commentMenu(comment: comment)
            }
            Divider()
            Markdown(comment.body)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .backgroundStyle(Color(.systemBackground))
    }

    @ViewBuilder
    private func commentMenu(comment: GetIssueAndCommentsByIDQuery.Data.Node.AsIssue.Comments.Node) -> some View {
        Menu {
            if comment.viewerCanUpdate {
                Button(action: {
                    targetComment = EditComment(commentId: comment.id, commentBody: comment.body)
                }) {
                    Label("編集", systemImage: "pencil")
                }
            }
            if comment.viewerCanDelete {
                Button(action: {
                    targetCommentId = comment.id
                    isShowCommentDeleteAlert = true
                }) {
                    Label("削除", systemImage: "trash")
                }
            }
        } label: {
            Image(systemName: "ellipsis")
        }
        .disabled(!comment.viewerCanUpdate && !comment.viewerCanDelete)
    }
    
    private func reload() {
        apollo.fetch(query: GitHubSchema.GetIssueAndCommentsByIDQuery(id: issueId, after: nil), cachePolicy: .fetchIgnoringCacheData) { [self] result in
            guard let data = try? result.get().data else { return }
            titleText = data.node?.asIssue?.title
            bodyMarkdown = data.node?.asIssue?.body ?? ""
            comments = (data.node?.asIssue?.comments.nodes?.compactMap(\.!))!
            print(comments)
            auther = data.node?.asIssue?.author?.login
            autherAvatorURL = data.node?.asIssue?.author?.avatarUrl
        }
    }

}
