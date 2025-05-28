//
//  SettingView.swift
//  github graphql swiftui
//
//  Created by 矢島良乙 on 2025/05/23.
//

import SwiftUI

struct SettingView: View {
    
    @Binding var isShowingSheet: Bool
    
    @AppStorage("accessToken") var accessToken = ""
    
    var body: some View {
        NavigationStack {
            Text("Github Personal Access Token")
            TextField("Github Personal Access Token", text: $accessToken)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: {
                            isShowingSheet = false
                        }) {
                            Text("完了")
                        }
                    }
                }
                .navigationBarTitle("設定")
        }
    }
}

#Preview {
    PreviewWrapper()
}

private struct PreviewWrapper: View {
    @State private var isShowingSheet = true

    var body: some View {
        SettingView(isShowingSheet: $isShowingSheet)
    }
}
