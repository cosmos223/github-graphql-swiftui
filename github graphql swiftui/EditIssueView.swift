//
//  EditIssueView.swift
//  github graphql swiftui
//
//  Created by 矢島良乙 on 2025/05/26.
//

import SwiftUI
import GitHubSchema

struct EditIssueView: View {
    
    var issueId: ID!
    
    @Environment(\.dismiss) private var dismiss
    
    @State var titleText: String
    @State var bodyText: String = ""
    
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
            .navigationTitle("編集")
            .alert(alertTitle, isPresented: $isShowAlert) {
                if closeSheetAlertClosed {
                    Button("OK") {
                        onComplete(true)
                        dismiss()
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
                        apollo.perform(mutation: GitHubSchema.UpdateIssueMutation(id: issueId, title: titleText, body: body)) { result in
                            switch result {
                            case .success(let value):
                                alertTitle = ""
                                alertMessage = "編集が保存されました"
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
                        Text("保存")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        onComplete(false)
                        dismiss()
                    }) {
                        Text("キャンセル")
                    }
                }
            }
        }
    }
}
