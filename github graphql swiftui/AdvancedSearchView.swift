//
//  AdvancedSearchView.swift
//  github graphql swiftui
//
//  Created by 矢島良乙 on 2025/05/27.
//

import SwiftUI
import Collections

struct QueryType {
    let label: String
    let query: String
    let number: Bool
}

struct AdvancedSearchView: View {
    
    let queryTypes: [QueryType] = [
        .init(label: "Name", query: "in:name ", number: false),
        .init(label: "User", query: "user:", number: false),
        .init(label: "Language", query: "language:", number: false),
        .init(label: "Star", query: "stars:", number: true),
        .init(label: "Fork", query: "forks:", number: true),
        .init(label: "Organization", query: "org:", number: false),
    ]
    
    let numPopUps: OrderedDictionary<String, String> = ["より大きい": ">", "以上": ">=", "と同じ": "", "以下": "<=", "未満": "<"]
    
    @State private var queryValues: [String: String] = [:]
    @State private var popupSelections: [String: String] = [:]
    
    @State private var isShowAlert = false
    
    @State private var builtQueries: [String] = []
    
    private func initializePopupSelections() {
        for query in queryTypes where query.number {
            popupSelections[query.query] = "以上" // "以上" をデフォルト選択肢として設定
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(queryTypes, id: \.query) { query in
                HStack(spacing: 8) {
                    Text(query.label)
                        .font(.body)
                    
                    TextField("", text: Binding(
                        get: { queryValues[query.query] ?? "" },
                        set: { queryValues[query.query] = $0 }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(query.number ? .numberPad : .default)
                    .frame(maxWidth: .infinity)
                    
                    if query.number {
                        Menu {
                            Picker("選択", selection: $popupSelections[query.query]) {
                                ForEach(Array(numPopUps.keys), id: \.self) { key in
                                    Button(action: {
                                        popupSelections[query.query] = key
                                    }) {
                                        Text(key)
                                    }.tag(key)
                                }
                            }
                            .pickerStyle(.inline)
                        } label: {
                            Text(popupSelections[query.query] ?? numPopUps.keys.first!)
                                .padding(6)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(6)
                        }
                    }
                }
            }
            
            NavigationLink(destination: AdvancedSearchResultView(queries: builtQueries)) {
                Text("検索")
            }
            .disabled(builtQueries.isEmpty)
            
        }
        .padding()
        .onAppear {
            initializePopupSelections()
        }
        .onChange(of: queryValues) { newValue in
            var queries: [String] = []
            
            for query in queryTypes {
                let value = newValue[query.query] ?? ""
                if !value.isEmpty {
                    if query.number {
                        let popupKey = popupSelections[query.query] ?? ""
                        let op = numPopUps[popupKey] ?? ""
                        queries.append("\(query.query)\(op)\(value)")
                    } else {
                        queries.append("\(query.query)\(value)")
                    }
                }
            }
            
            builtQueries = queries
        }
        
    }
}

#Preview {
    AdvancedSearchView()
}
