//
//  IssuesView.swift
//  github graphql swiftui
//
//  Created by 矢島良乙 on 2025/05/23.
//

import SwiftUI
import GitHubSchema
import MarkdownUI

struct IssuesView: View {
    
    var repositoryId: ID!
    
    @State var issues: [GetIssuesByRepositoryIDQuery.Data.Node.AsRepository.Issues.Node] = []
    
    @State private var endCursor: String?
    @State private var hasNextPage = false
    
    var repositoryName: String!
    
    private let apollo = GraphQLClient.shared.apollo
    
    @State private var loadingNextPage = false
    
    @State private var isShowingSheet: Bool = false
    
    @State private var initialLoading = true
    
    var body: some View {
        VStack {
            if initialLoading {
                ProgressView("Loading...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
            } else {
                if issues.isEmpty {
                    Text("No data")
                } else {
                    List(issues, id: \.id) { issue in
                        NavigationLink(destination: IssueDetailView(issueId: issue.id, titleText: issue.title, auther: issue.author?.login ?? "")) {
                            VStack{
                                Markdown(issue.title)
                                    .foregroundStyle(.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text(issue.author?.login ?? "")
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .onAppear {
                                if issue == issues.last {
                                    loadNextPage()
                                }
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    isShowingSheet = true
                }) {
                    Image(systemName: "square.and.pencil")
                }
            }
        }
        .sheet(isPresented: $isShowingSheet) {
            CreateIssueView(repositoryId: repositoryId, isShowingSheet: $isShowingSheet, onComplete: { updated in
                if updated { reload() }
            })
        }
        .onAppear {
            loadingNextPage = true
            apollo.fetch(query: GitHubSchema.GetIssuesByRepositoryIDQuery(id: repositoryId, after: .none), cachePolicy: .fetchIgnoringCacheData) { [self] result in
                guard let data = try? result.get().data else { return }
                issues = (data.node?.asRepository?.issues.nodes?.compactMap(\.!))!
                endCursor = data.node?.asRepository?.issues.pageInfo.endCursor
                hasNextPage = data.node?.asRepository?.issues.pageInfo.hasNextPage ?? false
                loadingNextPage = false
                initialLoading = false
            }
        }
        .navigationBarTitle(repositoryName + " issues")
    }
    
    private func loadNextPage() {
        guard hasNextPage, !loadingNextPage else { return }
        loadingNextPage = true
        let endCursorNullable: GraphQLNullable<String> = self.endCursor ?? .none
        apollo.fetch(query: GitHubSchema.GetIssuesByRepositoryIDQuery(id: repositoryId, after: endCursorNullable)) { [self] result in
            guard let data = try? result.get().data else { return }
            issues.append(contentsOf: (data.node?.asRepository?.issues.nodes?.compactMap(\.!))!)
            endCursor = data.node?.asRepository?.issues.pageInfo.endCursor
            hasNextPage = data.node?.asRepository?.issues.pageInfo.hasNextPage ?? false
            loadingNextPage = false
        }
    }
    
    private func reload() {
        hasNextPage = false
        loadingNextPage = true
        apollo.fetch(query: GitHubSchema.GetIssuesByRepositoryIDQuery(id: repositoryId, after: .none), cachePolicy: .fetchIgnoringCacheData) { [self] result in
            guard let data = try? result.get().data else { return }
            issues = (data.node?.asRepository?.issues.nodes?.compactMap(\.!))!
            endCursor = data.node?.asRepository?.issues.pageInfo.endCursor
            hasNextPage = data.node?.asRepository?.issues.pageInfo.hasNextPage ?? false
            print(issues.count)
            loadingNextPage = false
        }
    }
}
