//
//  ContentView.swift
//  github graphql swiftui
//
//  Created by 矢島良乙 on 2025/05/23.
//

import SwiftUI
import GitHubSchema

struct ContentView: View {
    
    @State private var searchText: String = ""
    
    @State private var repositories: [GetRepositoriesQuery.Data.Search.Node.AsRepository] = []
    
    @State private var endCursor: String?
    @State private var hasNextPage = false
    
    private let apollo = GraphQLClient.shared.apollo
    
    @State private var fetch: DispatchWorkItem?
    
    @State private var isShowAlert = false
    @State private var alertMessage = ""
    
    @State private var isShowingSheet = false
    
    @State private var loadingNextPage = false
    
    var body: some View {
        
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
                    if repository == repositories.last {
                        loadNextPage()
                    }
                }
            }
        }
        .listStyle(.plain)
        .searchable(text: $searchText)
        .onChange(of: searchText) { text in
            hasNextPage = false
            
            fetch?.cancel()
            fetch = DispatchWorkItem() { [self] in
                apollo.fetch(query: GitHubSchema.GetRepositoriesQuery(query: GraphQLNullable(stringLiteral: searchText), after: .none)) { [self] result in
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
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: fetch!)
        }.toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    isShowingSheet = true
                }) {
                    Image(systemName: "gearshape")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(destination: AdvancedSearchView()) {
                    Image(systemName: "text.page.badge.magnifyingglass")
                }
            }
        }.alert("エラー", isPresented: $isShowAlert) {
            
        } message: {
            Text(alertMessage)
        }.sheet(isPresented: $isShowingSheet) {
            SettingView(isShowingSheet: $isShowingSheet)
        }
        .navigationBarTitle("検索")
    }
    
    private func loadNextPage() {
        guard hasNextPage, !loadingNextPage else { return }
        loadingNextPage = true
        let endCursorNullable: GraphQLNullable<String> = self.endCursor ?? .none
        apollo.fetch(query: GitHubSchema.GetRepositoriesQuery(query: GraphQLNullable(stringLiteral: searchText), after: endCursorNullable)) { [self] result in
            guard let data = try? result.get().data else { return }
            repositories.append(contentsOf: (data.search.nodes?.compactMap(\.?.asRepository))!)
            endCursor = data.search.pageInfo.endCursor
            hasNextPage = data.search.pageInfo.hasNextPage
            loadingNextPage = false
        }
    }
    
}

#Preview {
    NavigationStack {
        ContentView()
    }
}
