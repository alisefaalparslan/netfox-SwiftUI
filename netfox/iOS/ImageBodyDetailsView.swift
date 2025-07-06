//
//  ImageBodyDetailsView.swift
//
//  Created by alisefaalparslan on 5.07.2025.
//

import Foundation
import UIKit

enum NFXBodyType: Int {
    case request  = 0
    case response = 1
}

import SwiftUI

struct ImageBodyDetailsView: View {
    let bodyType: NFXBodyType
    let selectedModel: NFXHTTPModel

    var decodedImage: UIImage? {
        let base64String: String = {
            switch bodyType {
            case .request:
                return selectedModel.getRequestBody()
            case .response:
                return selectedModel.getResponseBody()
            }
        }()

        guard let data = Data(base64Encoded: base64String, options: .ignoreUnknownCharacters) else {
            return nil
        }

        return UIImage(data: data)
    }

    var body: some View {
        ScrollView([.vertical, .horizontal]) {
            if let uiImage = decodedImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(10)
            } else {
                Text("Unable to decode image")
                    .padding()
            }
        }
        .navigationTitle("Image preview")
    }
}
