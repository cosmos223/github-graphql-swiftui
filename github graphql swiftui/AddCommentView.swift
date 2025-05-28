//
//  AddCommentView.swift
//  github graphql swiftui
//
//  Created by 矢島良乙 on 2025/05/24.
//

import SwiftUI
import GitHubSchema
import MarkdownUI

struct AddCommentView: View {
    
    @Binding var isShowingSheet: Bool
    
    var issueId: ID!
    
    private let apollo = GraphQLClient.shared.apollo
    
    @State private var bodyText: String = ""
    
    @State private var isShowAlert = false
    @State private var closeSheetAlertClosed: Bool = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    var onComplete: (_ updated: Bool) -> Void
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let isVertical = geometry.size.height > geometry.size.width
                
                Group {
                    if isVertical {
                        VStack {
                            content
                        }
                    } else {
                        HStack {
                            content
                        }
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
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
                        guard !bodyText.isEmpty else {
                            alertTitle = "エラー"
                            alertMessage = "入力してください"
                            isShowAlert = true
                            return
                        }
                        apollo.perform(mutation: GitHubSchema.AddCommentMutation(id: issueId, body: bodyText)) { result in
                            switch result {
                            case .success(let value):
                                alertTitle = ""
                                alertMessage = "追加されました"
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
                        Text("追加")
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
            .navigationTitle("コメント追加")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    var content: some View {
        Group {
            TextEditor(text: $bodyText)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.opaqueSeparator), lineWidth: 1)
                )
                .padding(.horizontal)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            ScrollView {
                Markdown(bodyText)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
//                    .markdownTheme(.gitHub)
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    PreviewWrapper()
}

private struct PreviewWrapper: View {
    @State private var isShowingSheet = true
    
    var body: some View {
        AddCommentView(isShowingSheet: $isShowingSheet, onComplete: { updated in })
    }
}
