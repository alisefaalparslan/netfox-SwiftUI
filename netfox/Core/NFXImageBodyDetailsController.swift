//
//  NFXImageBodyDetailsController.swift
//  netfox
//
//  Copyright © 2016 netfox. All rights reserved.
//

import Foundation
import UIKit

enum NFXBodyType: Int {
    case request  = 0
    case response = 1
}

import SwiftUI

struct NFXImageBodyDetailsView: View {
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
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .background(Color.NFXGray95Color.ignoresSafeArea())
        .navigationTitle("Image preview")
    }
}
