//
//  ImageViewController.swift
//  netfox_ios_demo
//
//  Created by Nathan Jangula on 10/12/17.
//  Copyright © 2017 kasketis. All rights reserved.
//

import SwiftUI

struct ImageView: View {
    @State private var items: [GridItemModel] = []
    @State private var columns: [[GridItemModel]] = [[], []]

    private let columnCount = 2
    private let itemsPerColumn = 20

    var body: some View {
        ScrollView {
            HStack(alignment: .top, spacing: 12) {
                ForEach(0..<columnCount, id: \.self) { column in
                    LazyVStack(spacing: 12) {
                        ForEach(columns[column]) { item in
                            AsyncImageView(url: item.url)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
            }
            .padding()
        }
        .onAppear {
            loadItems()
            distributeIntoColumns()
        }
    }

    private func loadItems() {
        // total = 2 * 20 = 40 images
        let total = columnCount * itemsPerColumn

        items = (0..<total).map { _ in
            let width = Int.random(in: 200...400)
            let height = Int.random(in: 200...500)
            let url = URL(string: "https://picsum.photos/\(width)/\(height)")!
            return GridItemModel(url: url)
        }
    }

    private func distributeIntoColumns() {
        var col0: [GridItemModel] = []
        var col1: [GridItemModel] = []

        for (index, item) in items.enumerated() {
            if index % 2 == 0 {
                col0.append(item)
            } else {
                col1.append(item)
            }
        }

        columns = [col0, col1]
    }
}

// MARK: - Async Image Loader (URLSession Compatible)
struct AsyncImageView: View {
    @State private var image: UIImage?
    let url: URL

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 200)
                    .onAppear { load() }
            }
        }
    }

    private func load() {
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard
                error == nil,
                let data = data,
                let img = UIImage(data: data)
            else { return }

            DispatchQueue.main.async {
                self.image = img
            }
        }.resume()
    }
}

// MARK: - Model
struct GridItemModel: Identifiable {
    let id = UUID()
    let url: URL
}
