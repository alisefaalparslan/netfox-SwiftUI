//
//  TextViewController.swift
//  netfox_ios_demo
//
//  Created by Nathan Jangula on 10/12/17.
//  Copyright © 2017 kasketis. All rights reserved.
//

import SwiftUI

struct JokeView: View {
    @State private var joke: String = "Press refresh to load a joke..."
    @State private var isLoading = false
    private let url = URL(string: "https://api.chucknorris.io/jokes/random")!

    var body: some View {
        VStack(spacing: 20) {
            ScrollView {
                Text(joke)
                    .font(.title3)
                    .padding()
            }

            Button(action: loadJoke) {
                HStack {
                    if isLoading { ProgressView() }
                    Text("Refresh Joke")
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(12)
            }
        }
        .padding()
        .onAppear {
            loadJoke()
        }
    }

    private func loadJoke() {
        isLoading = true

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        URLSession.shared.dataTask(with: request) { data, response, error in
            defer { DispatchQueue.main.async { isLoading = false } }

            if let error = error {
                updateJoke("Error: \(error.localizedDescription)")
                return
            }

            guard let http = response as? HTTPURLResponse else {
                updateJoke("Invalid response")
                return
            }

            guard (200..<300).contains(http.statusCode) else {
                updateJoke("Error: \(http.statusCode)")
                return
            }

            guard let data = data else {
                updateJoke("No data")
                return
            }

            if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let value = json["value"] as? String {
                updateJoke(value)
            } else {
                updateJoke("Invalid JSON")
            }

        }.resume()
    }

    private func updateJoke(_ newValue: String) {
        DispatchQueue.main.async {
            self.joke = newValue
        }
    }
}

