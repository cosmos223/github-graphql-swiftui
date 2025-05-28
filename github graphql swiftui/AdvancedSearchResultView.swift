//
//  AdvancedSearchResultView.swift
//  github graphql swiftui
//
//  Created by 矢島良乙 on 2025/05/27.
//

import SwiftUI
import GitHubSchema

struct AdvancedSearchResultView: View {
    
    var queries: [String]
    
    @State private var repositories: [GetRepositoriesQuery.Data.Search.Node.AsRepository] = []
    
    @State private var endCursor: String?
    @State private var hasNextPage = false
    
    private let apollo = GraphQLClient.shared.apollo
    
    @State private var fetch: DispatchWorkItem?
    
    @State private var isShowAlert = false
    @State private var alertMessage = ""
    
    @State private var isShowingSheet = false
    
    @State private var loadingNextPage = false
    @State private var initialLoading = true
    
    var body: some View {
        VStack {
            if initialLoading {
                // ローディング画面
                ProgressView("Loading...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
            } else {
                if repositories.isEmpty {
                    Text("No data")
                } else {
                    List(repositories, id: \.id) { repository in
                        NavigationLink(destination: IssuesView(repositoryId: repository.id, repositoryName: repository.nameWithOwner)) {
                            VStack{
                                Text(repository.nameWithOwner)
                                    .foregroundStyle(.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text(repository.description ?? "")
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .onAppear {
                                // 最後の要素であれば次のページを読み込む
                                if repository == repositories.last {
                                    loadNextPage()
                                }
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            apollo.fetch(query: GitHubSchema.GetRepositoriesQuery(query: GraphQLNullable(stringLiteral: queries.joined(separator: " ")), after: .none)) { [self] result in
                switch result {
                case .success(let value):
                    guard let data = value.data else { return }
                    repositories = (data.search.nodes?.compactMap(\.?.asRepository))!
                    endCursor = data.search.pageInfo.endCursor
                    hasNextPage = data.search.pageInfo.hasNextPage
                    print(repositories)
                case .failure(let error):
                    alertMessage = error.localizedDescription
                    isShowAlert = true
                }
                initialLoading = false
            }
        }
        .listStyle(.plain)
        .alert("エラー", isPresented: $isShowAlert) {
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $isShowingSheet) {
            SettingView(isShowingSheet: $isShowingSheet)
        }
        .navigationBarTitle("検索結果")
    }
    
    private func loadNextPage() {
        guard hasNextPage, !loadingNextPage else { return }
        loadingNextPage = true
        let endCursorNullable: GraphQLNullable<String> = self.endCursor ?? .none
        apollo.fetch(query: GitHubSchema.GetRepositoriesQuery(query: GraphQLNullable(stringLiteral: queries.joined(separator: " ")), after: endCursorNullable)) { [self] result in
            guard let data = try? result.get().data else { return }
            repositories.append(contentsOf: (data.search.nodes?.compactMap(\.?.asRepository))!)
            endCursor = data.search.pageInfo.endCursor
            hasNextPage = data.search.pageInfo.hasNextPage
            loadingNextPage = false
        }
    }
}

#Preview {
    AdvancedSearchResultView(queries: [])
}
