//
//  NFXSettingsController_iOS.swift
//  netfox
//
//  Copyright © 2016 netfox. All rights reserved.
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

struct NFXSettingsView: View {
    @State private var filters = NFXHTTPModelManager.shared.filters
    @State private var isLoggingEnabled = NFX.sharedInstance().isEnabled()
    @State private var showClearConfirmation = false
    @State private var showMailView = false
    @State private var mailData: Data?
    @State private var showInfo = false
    @State private var showStatistics = false
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
                        Text("Share Session Logs")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(Color.NFXGreenColor)
                            .font(.system(size: 16))
                    }
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
            .sheet(isPresented: $showMailView) {
                if let mailData = mailData {
                    MailView(data: mailData)
                }
            }
            .sheet(isPresented: $showInfo) {
                NFXInfoView()
            }
            .sheet(isPresented: $showStatistics) {
                NFXStatisticsView()
            }
        }
    }

    private func shareSessionLogs() {
        if let sessionLogData = try? Data(contentsOf: NFXPath.sessionLogURL) {
            mailData = sessionLogData
            showMailView = true
        }
    }
}

import SwiftUI
import MessageUI

struct MailView: UIViewControllerRepresentable {
    let data: Data

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        func mailComposeController(_ controller: MFMailComposeViewController,
                                   didFinishWith result: MFMailComposeResult,
                                   error: Error?) {
            controller.dismiss(animated: true)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let mail = MFMailComposeViewController()
        mail.mailComposeDelegate = context.coordinator
        mail.setSubject("netfox log - Session Log \(Date())")
        mail.addAttachmentData(data, mimeType: "text/plain", fileName: NFXPath.sessionLogName)
        return mail
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
}

