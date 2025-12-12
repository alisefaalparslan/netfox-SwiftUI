//
//  SettingsView.swift
//
//  Created by alisefaalparslan on 5.07.2025.
//

import UIKit
import MessageUI

//class NFXSettingsController_iOS: NSObject {
//    func shareSessionLogsPressed() {
//        if (MFMailComposeViewController.canSendMail()) {
//            let mailComposer = MFMailComposeViewController()
//            mailComposer.mailComposeDelegate = self
//            
//            mailComposer.setSubject("netfox log - Session Log \(NSDate())")
//            if let sessionLogData = try? Data(contentsOf: NFXPath.sessionLogURL) {
//                mailComposer.addAttachmentData(sessionLogData as Data, mimeType: "text/plain", fileName: NFXPath.sessionLogName)
//            }
//            
//            present(mailComposer, animated: true, completion: nil)
//        }
//    }
//    
//    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
//        dismiss(animated: true, completion: nil)
//    }
//}

import SwiftUI
import MessageUI

struct SettingsView: View {
    @State private var filters = NFXHTTPModelManager.shared.filters
    @State private var isLoggingEnabled = NFX.sharedInstance().isEnabled()
    @State private var showClearConfirmation = false
    @State private var showInfo = false
    @State private var showStatistics = false
    @State private var isSessionLogGenerating = false
    @Environment(\.presentationMode) private var presentationMode

    private let tableData = HTTPModelShortType.allCases

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle("Logging", isOn: $isLoggingEnabled)
                        .onChange(of: isLoggingEnabled) { value in
                            if value {
                                NFX.sharedInstance().enable()
                            } else {
                                NFX.sharedInstance().disable()
                            }
                        }
                }

                Section(header: Text("Select the types of responses that you want to see").font(.caption).multilineTextAlignment(.center)) {
                    ForEach(tableData.indices, id: \.self) { index in
                        Button(action: {
                            filters[index].toggle()
                        }) {
                            HStack {
                                Text(tableData[index].rawValue)
                                Spacer()
                                if filters[index] {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                }

                Section {
                    Button(action: shareSessionLogs) {

                        if isSessionLogGenerating {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Share Session Logs")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(Color.NFXGreenColor)
                                .font(.system(size: 16))
                        }
                    }
                    .disabled(isSessionLogGenerating)
                }

                Section {
                    Button(action: { showClearConfirmation = true }) {
                        Text("Clear data")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(Color.NFXRedColor)
                            .font(.system(size: 16))
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: { showStatistics = true }) {
                            Image(systemName: "chart.line.uptrend.xyaxis.circle")
                        }
                        Button(action: { showInfo = true }) {
                            Image(systemName: "info.circle")
                        }
                    }
                }
            }
            .confirmationDialog("Clear data?", isPresented: $showClearConfirmation, titleVisibility: .visible) {
                Button("Yes", role: .destructive) {
                    NFX.sharedInstance().clearOldData()
                }
                Button("Cancel", role: .cancel) {}
            }
            .onAppear {
                filters = NFXHTTPModelManager.shared.filters
                isLoggingEnabled = NFX.sharedInstance().isEnabled()
            }
            .onDisappear {
                NFXHTTPModelManager.shared.filters = filters
            }
            .sheet(isPresented: $showInfo) {
                InfoView()
            }
            .sheet(isPresented: $showStatistics) {
                StatisticsView()
            }
        }
    }

    private func shareSessionLogs() {
        DispatchQueue.global(qos: .utility).async {
            guard let data = try? Data(contentsOf: NFXPath.sessionLogURL) else {
                print("❌ session.log not found")
                return
            }

            DispatchQueue.main.async {
                ShareHelper.presentShareSheet(with: data, fileName: "session.log")
                self.isSessionLogGenerating = false

            }
        }
    }
}

import UIKit

enum ShareHelper {
    static func presentShareSheet(with data: Data, fileName: String) {
        // Create temp file URL
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(fileName)

        // Write data to temp file
        do {
            try data.write(to: tempURL, options: .atomic)
        } catch {
            print("❌ Failed to write temp log file: \(error)")
            return
        }

        // Prepare activity controller
        let activityVC = UIActivityViewController(
            activityItems: [tempURL],
            applicationActivities: nil
        )

        // Present on top-most UIViewController
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.keyWindow,
              let topVC = window.rootViewController?.topMostViewController()
        else {
            print("❌ Failed to find top view controller!")
            return
        }

        topVC.present(activityVC, animated: true)
    }
}

extension UIViewController {
    func topMostViewController() -> UIViewController {
        if let presented = self.presentedViewController {
            return presented.topMostViewController()
        }

        if let nav = self as? UINavigationController {
            return nav.visibleViewController?.topMostViewController() ?? nav
        }

        if let tab = self as? UITabBarController {
            return tab.selectedViewController?.topMostViewController() ?? tab
        }

        return self
    }
}

extension UIWindowScene {
    var keyWindow: UIWindow? {
        self.windows.first(where: { $0.isKeyWindow })
    }
}
