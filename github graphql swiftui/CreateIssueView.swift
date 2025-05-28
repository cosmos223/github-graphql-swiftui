//
//  CreateIssueView.swift
//  github graphql swiftui
//
//  Created by 矢島良乙 on 2025/05/24.
//

import SwiftUI
import GitHubSchema

struct CreateIssueView: View {
    
    var repositoryId: ID!
    
    @Binding var isShowingSheet: Bool
    
    @State private var titleText = ""
    @State private var bodyText = ""
    
    @State private var isShowAlert = false
    @State private var closeSheetAlertClosed: Bool = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    var onComplete: (_ updated: Bool) -> Void
    
    private let apollo = GraphQLClient.shared.apollo
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("タイトル", text: $titleText)
                TextField("本文", text: $bodyText, axis: .vertical)
//                TextEditor(text: $bodyText)
                
            }
            .navigationTitle("新規 Issue")
            .alert(alertTitle, isPresented: $isShowAlert) {
                if closeSheetAlertClosed {
                    Button("OK") {
                        onComplete(true)
                        isShowingSheet = false
                    }
                }
            } message: {
                Text(alertMessage)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        guard !titleText.isEmpty else {
                            alertTitle = "エラー"
                            alertMessage = "タイトルは必須項目です。"
                            isShowAlert = true
                            return
                        }
                        let body: GraphQLNullable<String> = .init(stringLiteral: bodyText)
                        apollo.perform(mutation: GitHubSchema.CreateIssueMutation(repositoryId: repositoryId, title: titleText, body: body)) { result in
                            switch result {
                            case .success(let value):
                                alertTitle = ""
                                alertMessage = "作成されました"
                                closeSheetAlertClosed = true
                                isShowAlert = true
                            case .failure(let error):
                                print("Error fetching issues: \(error)")
                                alertTitle = "エラー"
                                alertMessage = error.localizedDescription
                                isShowAlert = true
                            }
                        }
                    }) {
                        Text("作成")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        onComplete(false)
                        isShowingSheet = false
                    }) {
                        Text("キャンセル")
                    }
                }
            }
        }
    }
}

#Preview {
    PreviewWrapper()
}

private struct PreviewWrapper: View {
    @State private var isShowingSheet = true

    var body: some View {
        CreateIssueView(isShowingSheet: $isShowingSheet, onComplete: {updated in })
    }
}
