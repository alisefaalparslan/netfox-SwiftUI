//
//  InfoView.swift
//
//  Created by alisefaalparslan on 5.07.2025.
//

import SwiftUI

struct InfoView: View {
    @State private var infoText: AttributedString = AttributedString("Loading...")

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text(infoText)
                    .font(.system(size: 13))
                    .padding()

                HStack {
                    Spacer()
                }
            }
        }
        .navigationTitle("Info")
        .onAppear {
            loadInfo()
        }
    }

    private func loadInfo() {
        NFXDebugInfo.getNFXIP { ip in
            DispatchQueue.main.async {
                let text = generateInfoString(ip)
                infoText = text
            }
        }
    }

    private func generateInfoString(_ ipAddress: String) -> AttributedString {
        var string = ""
        string += "[App name] \n\(NFXDebugInfo.getNFXAppName())\n\n"
        string += "[App version] \n\(NFXDebugInfo.getNFXAppVersionNumber()) (build \(NFXDebugInfo.getNFXAppBuildNumber()))\n\n"
        string += "[App bundle identifier] \n\(NFXDebugInfo.getNFXBundleIdentifier())\n\n"
        string += "[Device OS] \niOS \(NFXDebugInfo.getNFXOSVersion())\n\n"
        string += "[Device type] \n\(NFXDebugInfo.getNFXDeviceType())\n\n"
        string += "[Device screen resolution] \n\(NFXDebugInfo.getNFXDeviceScreenResolution())\n\n"
        string += "[Device IP address] \n\(ipAddress)\n\n"

        return formatNFXString(string)
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
}

#Preview {
    InfoView()
}
