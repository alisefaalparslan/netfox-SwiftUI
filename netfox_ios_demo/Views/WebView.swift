//
//  WebViewController.swift
//  netfox_ios_demo
//
//  Created by Nathan Jangula on 10/12/17.
//  Copyright © 2017 kasketis. All rights reserved.
//

import SwiftUI
import WebKit

class WebViewController: UIViewController {

    let webView = UIWebView()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let url = URL(string: "https://github.com/kasketis/netfox")!
        webView.loadRequest(URLRequest(url: url))
    }
}

struct WebView: UIViewControllerRepresentable {

    func makeUIViewController(context: Context) -> WebViewController {
        let vc = WebViewController()
        return vc
    }

    func updateUIViewController(_ uiViewController: WebViewController, context: Context) {
        // Nothing to update
    }
}
