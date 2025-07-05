//
//  ListItemView.swift
//
//  Created by alisefaalparslan on 5.07.2025.
//

import Foundation
import SwiftUI

struct ListItemView: View {
    let url: String
    let status: Int
    let timeInterval: Float
    let type: String
    let method: String
    let requestTime: String
    let responseTime: String

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
                Text(responseTime)
                    .font(.system(size: 13, weight: .regular))
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

