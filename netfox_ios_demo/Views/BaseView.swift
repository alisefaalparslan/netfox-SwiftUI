//
//  WKWebViewController.swift
//  netfox_ios_demo
//
//  Created by Nathan Jangula on 9/14/18.
//  Copyright © 2017 kasketis. All rights reserved.
//

import SwiftUI

struct BaseView: View {
    var body: some View {
        TabView {
            WebView(url: URL(string: "https://github.com/kasketis/netfox")!)
                .tabItem {
                    Label("Web", systemImage: "globe")
                }

            JokeView()
                .tabItem {
                    Label("Jokes", systemImage: "text.bubble")
                }

            ImageView()
                .tabItem {
                    Label("Images", systemImage: "photo.on.rectangle")
                }
        }
    }
}
