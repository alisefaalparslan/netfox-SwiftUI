//
//  DetailsView.swift
//
//  Created by alisefaalparslan on 5.07.2025.
//

import Foundation
import UIKit
import MessageUI

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l > r
    default:
        return rhs < lhs
    }
}

import SwiftUI
import UniformTypeIdentifiers

struct DetailsView: View {
    @State private var selectedTab: DetailsTab = .info
    @State private var shareContent: String? = nil
    @State private var showShareSheet = false
    @State private var showResponseBodyDetails = false
    @State private var showRequestBodyDetails = false

    let selectedModel: NFXHTTPModel

    enum DetailsTab: String, CaseIterable, Identifiable {
        case info = "Info"
        case request = "Request"
        case response = "Response"

        var id: String { rawValue }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Picker("Details", selection: $selectedTab) {
                ForEach(DetailsTab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 8)

            Divider()
                .padding()

            ScrollView {
                VStack(alignment: .leading) {
                    Text(getAttributedString(for: selectedTab))
                        .font(.system(size: 13))
                        .padding()
                        .onLongPressGesture {
                            UIPasteboard.general.string = getClipboardString(for: selectedTab)
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
//                        .contextMenu {
//                            Button("Copy") {
//                                UIPasteboard.general.string = getClipboardString(for: selectedTab).description
//                            }
//                        }

                    if selectedTab == .request {
                        if selectedModel.requestBodyLength > 1024 {
                            Button("Show request body") {
                                showRequestBodyDetails = true
                            }
                            .padding()
                        }
                    } else if selectedTab == .response {
                        if selectedModel.responseBodyLength > 1024 {
                            Button("Show response body") {
                                showResponseBodyDetails = true
                            }
                            .padding()
                        }
                    }
                    HStack {
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Details")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Simple Log") { shareLog(full: false) }
                    Button("Full Log") { shareLog(full: true) }
                    if let curl = selectedModel.requestCurl {
                        Button("Export request as curl") {
                            shareCurl(curl)
                        }
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let shareContent = shareContent {
                ShareSheet(activityItems: [shareContent])
            }
        }
        .navigationDestination(isPresented: $showResponseBodyDetails) {
            switch selectedModel.shortType {
            case .IMAGE:
                ImageBodyDetailsView(bodyType: .response, selectedModel: selectedModel)
            default:
                RawBodyDetailsView(bodyType: .response, selectedModel: selectedModel)
            }
        }
        .navigationDestination(isPresented: $showRequestBodyDetails) {
            switch selectedModel.shortType {
            case .IMAGE:
                ImageBodyDetailsView(bodyType: .request, selectedModel: selectedModel)
            default:
                RawBodyDetailsView(bodyType: .request, selectedModel: selectedModel)
            }
        }
    }
}

// MARK: - Helpers

extension DetailsView {
    func getAttributedString(for tab: DetailsTab) -> AttributedString {
        let string: String
        switch tab {
        case .info:
            string = getInfoStringFromObject(selectedModel)
        case .request:
            string = getRequestStringFromObject(selectedModel)
        case .response:
            string = getResponseStringFromObject(selectedModel)
        }
        return formatNFXString(string)
    }

    func getClipboardString(for tab: DetailsTab) -> String {
        let string: String
        switch tab {
        case .info:
            string = getInfoStringFromObject(selectedModel)
        case .request:
            string = getRequestStringFromObject(selectedModel)
        case .response:
            string = getResponseStringFromObject(selectedModel)
        }
        return string
    }

    func getInfoStringFromObject(_ object: NFXHTTPModel) -> String {
        var s = ""
        s += "[URL] \n\(object.requestURL ?? "")\n\n"
        s += "[Method] \n\(object.requestMethod ?? "")\n\n"
        if !object.noResponse {
            s += "[Status] \n\(object.responseStatus ?? 999)\n\n"
        }
        s += "[Request date] \n\(object.requestDate ?? Date())\n\n"
        if !object.noResponse {
            s += "[Response date] \n\(object.responseDate ?? Date())\n\n"
            s += "[Time interval] \n\(object.timeInterval?.description ?? "")\n\n"
        }
        s += "[Timeout] \n\(object.requestTimeout?.description ?? "")\n\n"
        s += "[Cache policy] \n\(object.requestCachePolicy ?? "")\n\n"
        return s
    }

    func getRequestStringFromObject(_ object: NFXHTTPModel) -> String {
        var s = "-- Headers --\n\n"
        if let headers = object.requestHeaders, !headers.isEmpty {
            for (key, val) in headers {
                s += "[\(key)] \n\(val)\n\n"
            }
        } else {
            s += "Request headers are empty\n\n"
        }
        s += "\n-- Body --\n\n"
        if object.requestBodyLength == 0 {
            s += "Request body is empty\n"
        } else if object.requestBodyLength > 1024 {
            s += "Too long to show. If you want to see it, please tap the following button\n"
        } else {
            s += object.getRequestBody() + "\n"
        }
        return s
    }

    func getResponseStringFromObject(_ object: NFXHTTPModel) -> String {
        guard !object.noResponse else { return "No response" }
        var s = "-- Headers --\n\n"
        if let headers = object.responseHeaders, !headers.isEmpty {
            for (key, val) in headers {
                s += "[\(key)] \n\(val)\n\n"
            }
        } else {
            s += "Response headers are empty\n\n"
        }
        s += "\n-- Body --\n\n"
        if object.responseBodyLength == 0 {
            s += "Response body is empty\n"
        } else if object.responseBodyLength > 1024 {
            s += "Too long to show. If you want to see it, please tap the following button\n"
        } else {
            s += object.getResponseBody() + "\n"
        }
        return s
    }

    func formatNFXString(_ string: String) -> AttributedString {
        var attr = AttributedString(string)
        let patterns = [
            ("(-- Body --|-- Headers --)", Color.NFXOrangeColor, Font.system(size: 14, weight: .bold)),
            ("\\[.+?\\]", Color.primary, Font.system(size: 13, weight: .bold))
        ]
        for (pattern, color, font) in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let nsString = NSString(string: string)
                let matches = regex.matches(in: string, range: NSRange(location: 0, length: nsString.length))
                for match in matches {
                    if let range = Range(match.range, in: attr) {
                        attr[range].foregroundColor = color
                        attr[range].font = font
                    }
                }
            }
        }
        return attr
    }

    func shareLog(full: Bool) {
        var content = "** INFO **\n\(getInfoStringFromObject(selectedModel))\n\n"
        content += "** REQUEST **\n\(getRequestStringFromObject(selectedModel))\n\n"
        content += "** RESPONSE **\n\(getResponseStringFromObject(selectedModel))\n\n"
        content += "logged via netfox - https://github.com/kasketis/netfox\n"
        if full {
            if let requestFile = try? String(contentsOf: selectedModel.getRequestBodyFileURL(), encoding: .utf8) {
                content += requestFile
            }
            if let responseFile = try? String(contentsOf: selectedModel.getResponseBodyFileURL(), encoding: .utf8) {
                content += responseFile
            }
        }
        shareContent = content
        showShareSheet = true
    }

    func shareCurl(_ curl: String) {
        shareContent = curl
        showShareSheet = true
    }
}

import SwiftUI

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}


#Preview {
    DetailsView(
        selectedModel: NFXHTTPModel.mock
    )
}
