//
//  NFXRequestChartView.swift
//  netfox
//
//  Created by antigravity on 11.03.2026.
//

import SwiftUI
import Charts

struct NFXRequestChartView: View {
    let models: [NFXHTTPModel]
    @Environment(\.dismiss) var dismiss
    
    @State private var chartMode: ChartMode = .timeline
    @State private var selectedModelHash: String?

    enum ChartMode: String, CaseIterable, Identifiable {
        case timeline = "Timeline"
        case duration = "Duration"
        var id: String { self.rawValue }
    }

    // Group models by host to ensure we have colors for them
    private var chartData: [NFXHTTPModel] {
        models.filter { $0.requestDate != nil && $0.timeInterval != nil }
              .sorted { ($0.requestDate ?? Date.distantPast) < ($1.requestDate ?? Date.distantPast) }
    }
    
    private var selectedModel: NFXHTTPModel? {
        chartData.first { $0.randomHash == selectedModelHash }
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if chartData.isEmpty {
                            ContentUnavailableView("No Data", systemImage: "chart.bar.xaxis", description: Text("No requests with timing information available."))
                        } else {
                            Chart(chartData, id: \.randomHash) { model in
                                if let startDate = model.requestDate, let duration = model.timeInterval {
                                    if chartMode == .timeline {
                                        let endDate = startDate.addingTimeInterval(Double(duration))
                                        BarMark(
                                            xStart: .value("Start", startDate),
                                            xEnd: .value("End", endDate),
                                            y: .value("Request", model.randomHash)
                                        )
                                        .foregroundStyle(by: .value("Host", model.requestHost ?? "Unknown"))
                                        .cornerRadius(4)
                                        .opacity(selectedModelHash == nil || selectedModelHash == model.randomHash ? 1.0 : 0.3)
                                    } else {
                                        BarMark(
                                            x: .value("Duration", duration),
                                            y: .value("Request", model.randomHash)
                                        )
                                        .foregroundStyle(by: .value("Host", model.requestHost ?? "Unknown"))
                                        .cornerRadius(4)
                                        .opacity(selectedModelHash == nil || selectedModelHash == model.randomHash ? 1.0 : 0.3)
                                    }
                                }
                            }
                            .chartYAxis(.hidden)
                            .chartYScale(domain: chartData.map { $0.randomHash }) // Explicit order
                            .chartXAxis {
                                if chartMode == .timeline {
                                    AxisMarks(preset: .extended, values: .automatic) { _ in
                                        AxisValueLabel()
                                        AxisGridLine()
                                        AxisTick()
                                    }
                                } else {
                                    AxisMarks(preset: .extended, values: .automatic) { value in
                                        AxisValueLabel {
                                            if let duration = value.as(Float.self) {
                                                Text(String(format: "%.2fs", duration))
                                            }
                                        }
                                        AxisGridLine()
                                        AxisTick()
                                    }
                                }
                            }
                            .chartLegend(position: .bottom, alignment: .leading)
                            .chartYSelection(value: $selectedModelHash)
                            .frame(height: CGFloat(max(300, chartData.count * 22)))
                            .padding()
                            .chartOverlay { proxy in
                                Color.clear
                                    .onTapGesture { location in
                                        if let hash: String = proxy.value(atY: location.y) {
                                            selectedModelHash = (selectedModelHash == hash) ? nil : hash
                                        } else {
                                            selectedModelHash = nil
                                        }
                                    }
                            }
                        }
                    }
                }
                
                if let model = selectedModel {
                    SelectionInfoCard(model: model)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding()
                        .onTapGesture {
                            // Close when tapping and opening
                        }
                }
            }
            .navigationTitle("Request Timeline")

            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Picker("Mode", selection: $chartMode) {
                        ForEach(ChartMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 160)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SelectionInfoCard: View {
    let model: NFXHTTPModel
    
    var body: some View {
        NavigationLink(destination: DetailsView(selectedModel: model)) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(model.requestMethod ?? "-")
                            .font(.system(size: 10, weight: .black))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.1))
                            .cornerRadius(4)
                        
                        Text("\(model.responseStatus ?? 0)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(statusColor)
                        
                        Spacer()
                        
                        Text(durationText)
                            .font(.system(size: 10, weight: .semibold))
                    }
                    
                    Text(model.requestHost ?? "Unknown")
                        .font(.system(size: 12, weight: .bold))
                        .lineLimit(1)
                    
                    Text(model.requestURL ?? "")
                        .font(.system(size: 10))
                        .lineLimit(1)
                        .foregroundColor(.secondary)
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(12)
            .shadow(radius: 5)
        }
        .buttonStyle(.plain)
    }
    
    private var durationText: String {
        guard let interval = model.timeInterval else { return "-" }
        return interval < 1.0 ? "\(Int(interval * 1000))ms" : String(format: "%.2fs", interval)
    }
    
    private var statusColor: Color {
        let status = model.responseStatus ?? 0
        if (200...299).contains(status) { return .NFXGreenColor }
        if (400...599).contains(status) { return .NFXRedColor }
        return .NFXOrangeColor
    }
}
