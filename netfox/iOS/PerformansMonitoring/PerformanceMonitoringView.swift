//
//  DeviceStats.swift
//  netfox
//
//  Created by alisefa on 14.07.2025.
//  Copyright © 2025 kasketis. All rights reserved.
//


import SwiftUI
import Combine

public struct PerformanceMonitoringView: View {
    @State private var offset = CGSize(width: 20, height: 50)
    @GestureState private var dragOffset = CGSize.zero
    @State private var viewModel = PerformanceMonitoringViewModel()

    @State var isPreviewMode = false

    public init() {}

    public init(isPreviewMode: Bool) {
        self._isPreviewMode = .init(initialValue: isPreviewMode)
    }

    public var body: some View {
        Group {
            if viewModel.isActive {

                Group {
                    if isPreviewMode {
                        content
                    } else {
                        content
                            .offset(x: offset.width + dragOffset.width,
                                    y: offset.height + dragOffset.height)
                            .gesture(
                                DragGesture()
                                    .updating($dragOffset) { value, state, _ in
                                        state = value.translation
                                    }
                                    .onEnded { value in
                                        offset.width += value.translation.width
                                        offset.height += value.translation.height
                                    }
                            )
                            .transition(.scale.combined(with: .opacity))
                            .animation(.spring(), value: viewModel.store.isActive)
                    }
                }
                .onAppear {
                    viewModel.start()
                }
            } else {
                Color.clear
                    .onAppear {
                        viewModel.stop()
                    }
            }
        }
    }

    private var content: some View {
        VStack(spacing: 8) {
            // Header: Thermal & Network
            if !viewModel.store.isCollapsedVertical {
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "thermometer.medium")
                        Text(thermalStateText)
                    }
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(thermalColor)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(thermalColor.opacity(0.1))
                    .cornerRadius(4)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "network")
                        Text("\(viewModel.activeRequests)")
                    }
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
                }
                .frame(minWidth: 140)
            }

            HStack(alignment: .top, spacing: 12) {
                metricSection(title: "CPU", icon: "cpu", value: viewModel.cpuUsage, 
                              max: viewModel.cpuMax, min: viewModel.cpuMin, avg: viewModel.cpuAvg,
                              format: "%.1f%%", history: viewModel.cpuHistory, color: .green, 
                              resetAction: viewModel.resetCPU)
                
                Divider().frame(height: viewModel.store.isCollapsedVertical ? 20 : 60)
                
                metricSection(title: "MEM", icon: "memorychip", value: viewModel.memoryUsage, 
                              max: viewModel.memoryMax, min: viewModel.memoryMin, avg: viewModel.memoryAvg,
                              format: "%.0f", history: viewModel.memoryHistory, color: .blue, 
                              resetAction: viewModel.resetMEM)
                
                Divider().frame(height: viewModel.store.isCollapsedVertical ? 20 : 60)
                
                metricSection(title: "FPS", icon: "hertz.rate", value: viewModel.fpsUsage, 
                              max: viewModel.fpsMax, min: viewModel.fpsMin, avg: viewModel.fpsAvg,
                              format: "%.0f", history: viewModel.fpsHistory, color: .orange, 
                              resetAction: viewModel.resetFPS)
            }
        }
        .padding(10)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        .fixedSize()
        .overlay(alignment: .top) {
            controlButtons
        }
    }

    private func metricSection(title: String, icon: String, value: Double, max: Double, min: Double, avg: Double, format: String, history: [Double], color: Color, resetAction: @escaping () -> Void) -> some View {
        VStack(alignment: .center, spacing: 4) {
            if !viewModel.store.isCollapsedHorizontal {
                Label(title, systemImage: icon)
                    .font(.system(size: 8, weight: .black))
                    .foregroundColor(.secondary)
            }
            
            Text(String(format: format, value))
                .font(.system(size: 11, weight: .bold, design: .monospaced))
            
            if !viewModel.store.isCollapsedVertical {
                Sparkline(data: history, color: color)
                    .frame(width: 40, height: 15)
                
                VStack(spacing: 0) {
                    if showStat(for: title, type: .max) {
                        Text("M:\(String(format: format, max))")
                    }
                    if showStat(for: title, type: .min) {
                        Text("m:\(String(format: format, min == .infinity ? 0 : min))")
                    }
                    if showStat(for: title, type: .avg) {
                        Text("a:\(String(format: format, avg))")
                    }
                }
                .font(.system(size: 7, design: .monospaced))
                .foregroundColor(.secondary)
                
                Button(action: resetAction) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary.opacity(0.3))
                }
            }
        }
        .frame(minWidth: 40)
    }

    private enum StatType { case max, min, avg }
    private func showStat(for title: String, type: StatType) -> Bool {
        switch title {
        case "CPU":
            switch type {
            case .max: return viewModel.store.cpuShowMax
            case .min: return viewModel.store.cpuShowMin
            case .avg: return viewModel.store.cpuShowAvg
            }
        case "MEM":
            switch type {
            case .max: return viewModel.store.memShowMax
            case .min: return viewModel.store.memShowMin
            case .avg: return viewModel.store.memShowAvg
            }
        case "FPS":
            switch type {
            case .max: return viewModel.store.fpsShowMax
            case .min: return viewModel.store.fpsShowMin
            case .avg: return viewModel.store.fpsShowAvg
            }
        default: return false
        }
    }

    private var controlButtons: some View {
        HStack(spacing: 12) {
            Button { withAnimation { viewModel.store.isCollapsedVertical.toggle() } } label: {
                Image(systemName: viewModel.store.isCollapsedVertical ? "chevron.down.circle.fill" : "chevron.up.circle.fill")
            }
            
            Button { withAnimation { NFX.sharedInstance().show() } } label: {
                Image(systemName: "gearshape.circle.fill")
            }
            
            Button { 
                withAnimation { 
                    viewModel.store.isActive = false
                    viewModel.stop()
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
            }
        }
//        .symbolScheme(.hierarchical)
        .font(.system(size: 16))
        .padding(.top, -25)
        .opacity(isPreviewMode ? 0 : 1)
    }

    private var thermalStateText: String {
        switch viewModel.thermalState {
        case .nominal: return "NOMINAL"
        case .fair: return "FAIR"
        case .serious: return "SERIOUS"
        case .critical: return "CRITICAL"
        @unknown default: return "UNKNOWN"
        }
    }

    private var thermalColor: Color {
        switch viewModel.thermalState {
        case .nominal: return .green
        case .fair: return .yellow
        case .serious: return .orange
        case .critical: return .red
        @unknown default: return .gray
        }
    }
}

struct Sparkline: View {
    let data: [Double]
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                guard data.count > 1 else { return }
                
                let max = data.max() ?? 1
                let min = data.min() ?? 0
                let range = max - min == 0 ? 1 : max - min
                
                let stepX = geometry.size.width / CGFloat(data.count - 1)
                
                for i in 0..<data.count {
                    let x = CGFloat(i) * stepX
                    let y = geometry.size.height - CGFloat((data[i] - min) / range) * geometry.size.height
                    
                    if i == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(color, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
        }
    }
}

#Preview {
    PerformanceMonitoringView()
}
