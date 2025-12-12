//
//  RawBodyDetailsView.swift
//
//  Created by alisefaalparslan on 5.07.2025.
//

import SwiftUI

struct RawBodyDetailsView: View {
    let bodyType: NFXBodyType
    let selectedModel: NFXHTTPModel

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
            CreativeCopyButton(textToCopy: bodyText)
                .padding()

            Text(bodyText)
                .font(.system(size: 13, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .navigationTitle("Body details")
    }
}
