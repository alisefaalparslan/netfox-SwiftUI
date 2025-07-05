//
//  RawBodyDetailsView.swift
//
//  Created by alisefaalparslan on 5.07.2025.
//

import SwiftUI

struct RawBodyDetailsView: View {
    let bodyType: NFXBodyType
    let selectedModel: NFXHTTPModel
    @State private var showCopyAlert = false

    private var bodyText: String {
        switch bodyType {
        case .request:
            return selectedModel.getRequestBody()
        case .response:
            return selectedModel.getResponseBody()
        }
    }

    var body: some View {
        ScrollView {
            Text(bodyText)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(Color.NFXGray44Color)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .contextMenu {
                    Button(action: {
                        UIPasteboard.general.string = bodyText
                        showCopyAlert = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            showCopyAlert = false
                        }
                    }) {
                        Label("Copy Text", systemImage: "doc.on.doc")
                    }
                }
        }
        .background(Color.NFXGray95Color.ignoresSafeArea())
        .navigationTitle("Body details")
        .overlay(
            Group {
                if showCopyAlert {
                    Text("Text Copied!")
                        .font(.caption)
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                        .transition(.opacity)
                        .padding()
                }
            },
            alignment: .top
        )
    }
}
