//
//  ListItemView.swift
//
//  Created by alisefaalparslan on 5.07.2025.
//

import Foundation
import SwiftUI

struct ListItemView: View {

    var model: NFXHTTPModel

    private var statusColor: Color {
        let status = model.responseStatus ?? 999
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
        String(format: "%.2f", model.timeInterval ?? 999)
    }

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 5) {
                Spacer()
                Text(model.requestTimeSecond ?? "-")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                Text(timeIntervalText)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white)
                Text(model.responseTimeSecond ?? "-")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 5)
            .background(statusColor)
            .cornerRadius(5)

            VStack(alignment: .leading, spacing: 6) {
                Text(model.requestURL ?? "")
                    .font(.system(size: 13, weight: .regular))
                    .lineLimit(4)
                HStack(spacing: 8) {
                    Text(model.requestMethod ?? "-")
                        .font(.system(size: 12, weight: .bold))
                        .opacity(0.9)
                    Text(model.responseType ?? "-")
                        .lineLimit(1)
                        .font(.system(size: 10, weight: .regular))
                        .opacity(0.8)
                    Spacer()
                }

                HStack {
                    if let reqBod = model.requestBodyLength, reqBod > 0 {
                        Text("Request Body")
                            .font(.system(size: 9, weight: .regular))
                            .opacity(0.7)
                    }

                    if let resBod = model.responseBodyLength, resBod > 0 {
                        Text("Response Body")
                            .font(.system(size: 9, weight: .regular))
                            .opacity(0.7)
                    }

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

