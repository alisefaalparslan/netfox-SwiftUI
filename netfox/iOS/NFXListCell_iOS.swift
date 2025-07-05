//
//  NFXListCell.swift
//  netfox
//
//  Copyright © 2016 netfox. All rights reserved.
//

import Foundation
import SwiftUI

struct NFXListCellView: View {
    let url: String
    let status: Int
    let timeInterval: Float
    let requestTime: String
    let type: String
    let method: String
    let isNew: Bool

    private var statusColor: Color {
        if status == 999 {
            return Color.NFXGray44Color
        } else if status < 400, status >= 300 {
            return Color.NFXOrangeColor
        } else if status < 400 {
            return Color.NFXGreenColor
        } else {
            return Color.NFXRedColor
        }
    }

    private var timeIntervalText: String {
        timeInterval == 999 ? "-" : String(format: "%.2f", timeInterval)
    }

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 5) {
                Spacer()
                Text(requestTime)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                Text(timeIntervalText)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 5)
            .background(statusColor)
            .cornerRadius(5)

            VStack(alignment: .leading, spacing: 6) {
                Text(url)
                    .font(.system(size: 13, weight: .regular))
                    .lineLimit(3)
                HStack(spacing: 8) {
                    Text(method)
                        .font(.system(size: 12, weight: .bold))
                        .opacity(0.8)
                    Text(type)
                        .font(.system(size: 10, weight: .regular))
                        .opacity(0.8)
                    Spacer()
                }
            }
            .padding(.leading, 5)

            Spacer()
        }
    }
}


extension UIFont {
    var toFont: Font { Font(self) }
}

#Preview {
    VStack {
        Spacer()
        NFXListCellView(
             url: "https://api.example.com/data/123https://api.example.com/data/123https://api.example.com/data/123https://api.example.com/data/123https://api.example.com/data/123",
             status: 200,
             timeInterval: 0.150, // Time in seconds, e.g., 150ms
             requestTime: "10:30",
             type: "JSON",
             method: "GET",
             isNew: true
         )
        .frame(width: 300, height: 100)
        Spacer()
    }
}
