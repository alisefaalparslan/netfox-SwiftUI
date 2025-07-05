//
//  NFXStatisticsController_iOS.swift
//  netfox
//
//  Copyright © 2016 netfox. All rights reserved.
//

import SwiftUI

struct NFXStatisticsView: View {
    @State private var report: AttributedString = ""
    @State private var totalModels = 0
    @State private var successfulRequests = 0
    @State private var failedRequests = 0
    @State private var totalRequestSize = 0
    @State private var totalResponseSize = 0
    @State private var totalResponseTime: Float = 0
    @State private var fastestResponseTime: Float = 999
    @State private var slowestResponseTime: Float = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text(report)
                    .font(.system(size: 13))
                    .padding()

                HStack {
                    Spacer()
                }
            }
        }
        .navigationTitle("Statistics")
        .onAppear {
            NFXHTTPModelManager.shared.publisher.subscribe { models in
                generateStatistics(models)
                report = getReportString()
            }
            let models = NFXHTTPModelManager.shared.filteredModels
            generateStatistics(models)
            report = getReportString()
        }
    }

    private func generateStatistics(_ models: [NFXHTTPModel]) {
        clearStatistics()
        totalModels = models.count

        for model in models {
            if model.isSuccessful() {
                successfulRequests += 1
            } else {
                failedRequests += 1
            }

            if let length = model.requestBodyLength {
                totalRequestSize += length
            }
            if let length = model.responseBodyLength {
                totalResponseSize += length
            }
            if let interval = model.timeInterval {
                totalResponseTime += interval
                if interval < fastestResponseTime {
                    fastestResponseTime = interval
                }
                if interval > slowestResponseTime {
                    slowestResponseTime = interval
                }
            }
        }
    }

    private func clearStatistics() {
        totalModels = 0
        successfulRequests = 0
        failedRequests = 0
        totalRequestSize = 0
        totalResponseSize = 0
        totalResponseTime = 0
        fastestResponseTime = 999
        slowestResponseTime = 0
    }

    private func getReportString() -> AttributedString {
        var string = ""
        string += "[Total requests] \n\(totalModels)\n\n"
        string += "[Successful requests] \n\(successfulRequests)\n\n"
        string += "[Failed requests] \n\(failedRequests)\n\n"
        string += "[Total request size] \n\(Float(totalRequestSize) / 1024) KB\n\n"
        if totalModels == 0 {
            string += "[Avg request size] \n0.0 KB\n\n"
        } else {
            string += "[Avg request size] \n\(Float(totalRequestSize) / Float(totalModels) / 1024) KB\n\n"
        }
        string += "[Total response size] \n\(Float(totalResponseSize) / 1024) KB\n\n"
        if totalModels == 0 {
            string += "[Avg response size] \n0.0 KB\n\n"
        } else {
            string += "[Avg response size] \n\(Float(totalResponseSize) / Float(totalModels) / 1024) KB\n\n"
        }
        if totalModels == 0 {
            string += "[Avg response time] \n0.0s\n\n"
            string += "[Fastest response time] \n0.0s\n\n"
        } else {
            string += "[Avg response time] \n\(Float(totalResponseTime) / Float(totalModels))s\n\n"
            if fastestResponseTime == 999 {
                string += "[Fastest response time] \n0.0s\n\n"
            } else {
                string += "[Fastest response time] \n\(fastestResponseTime)s\n\n"
            }
        }
        string += "[Slowest response time] \n\(slowestResponseTime)s\n\n"

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
    NFXStatisticsView()
}
