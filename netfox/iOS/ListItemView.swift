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
        if status == 999 { return .NFXGray44Color }
        if (200...299).contains(status) { return .NFXGreenColor }
        if (300...399).contains(status) { return .NFXOrangeColor }
        return .NFXRedColor
    }

    private var methodColor: Color {
        switch model.requestMethod?.uppercased() {
        case "GET": return .blue
        case "POST": return .NFXGreenColor
        case "PUT", "PATCH": return .NFXOrangeColor
        case "DELETE": return .NFXRedColor
        default: return .secondary
        }
    }

    private var durationText: String {
        guard let interval = model.timeInterval else { return "-" }
        if interval < 1.0 {
            return "\(Int(interval * 1000))ms"
        } else {
            return String(format: "%.2fs", interval)
        }
    }

    private var sizeDisplayText: String {
        let length = Int64(model.responseBodyLength ?? 0)
        return ByteCountFormatter.string(fromByteCount: length, countStyle: .file)
    }

    private var pathText: String {
        guard let url = model.requestURL, let host = model.requestHost else { return model.requestURL ?? "" }
        if let range = url.range(of: host) {
            let path = url[range.upperBound...]
            return path.isEmpty ? "/" : String(path)
        }
        return url
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // 1. Status Column
            VStack(spacing: 4) {
                Text("\(model.responseStatus ?? 0)")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 28)
                    .background(statusColor)
                    .cornerRadius(6)
                
                Text(model.requestMethod ?? "-")
                    .font(.system(size: 10, weight: .black))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .foregroundColor(methodColor)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(methodColor.opacity(0.1))
                    .cornerRadius(4)
            }
            .frame(width: 44)

            // 2. Info Column
            VStack(alignment: .leading, spacing: 4) {
                Text(model.requestHost ?? "Unknown Host")
                    .font(.system(size: 14, weight: .bold))
                    .lineLimit(1)
                    .foregroundColor(.primary)

                Text(pathText)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(2)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 3) {                
                    Image(systemName: typeIconName)
                        .font(.system(size: 10, weight: .medium))

                    Text(model.shortTypeString)
                        .font(.system(size: 10, weight: .medium))
                    if let type = model.responseType, !type.isEmpty {
                        Text("•")
                        Text(type.lowercased())
                            .font(.system(size: 10))
                    }
                }
                .foregroundColor(.secondary.opacity(0.8))
                .padding(.top, 2)
            }
            .padding(.leading, 8)

            Spacer()

            // 3. Metrics Column
            VStack(alignment: .trailing, spacing: 4) {
                Text(durationText)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(durationColor)
                
                Text(sizeDisplayText)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text(model.requestTime ?? "--:--")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.6))
            }
        }
        .padding(.vertical, 4)
    }

    private var durationColor: Color {
        guard let interval = model.timeInterval else { return .secondary }
        if interval < 0.2 { return .NFXGreenColor }
        if interval < 1.0 { return .primary }
        return .NFXRedColor
    }

    private var typeIconName: String {
        switch model.shortType {
        case .JSON: return "ellipsis.curlybraces"
        case .XML: return "chevron.left.forwardslash.chevron.right"
        case .HTML: return "globe"
        case .IMAGE: return "photo"
        case .OTHER: return "doc.text"
        }
    }
}


extension UIFont {
    var toFont: Font { Font(self) }
}

