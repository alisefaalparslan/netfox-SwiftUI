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
    @StateObject private var viewModel = PerformanceMonitoringViewModel()

    @State var isPreviewMode = false

    public init() {}

    public init(isPreviewMode: Bool) {
        self._isPreviewMode = .init(initialValue: isPreviewMode)
    }

    public var body: some View {
        Group {
            if viewModel.store.isActive {

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
            } else {
                Color.clear
            }
        }
        .onAppear {
            viewModel.start()
        }
        .onDisappear {
            viewModel.stop()
        }
    }

    private var content: some View {
        HStack(spacing: 10) {
            debugMetricView(title: "CPU", value: viewModel.cpuUsage,
                            max: viewModel.cpuMax, min: viewModel.cpuMin, avg: viewModel.cpuAvg,
                            format: "%0.1f%%")

            Divider().frame(height: 20)

            debugMetricView(title: "MEM", value: viewModel.memoryUsage,
                            max: viewModel.memoryMax, min: viewModel.memoryMin, avg: viewModel.memoryAvg,
                            format: "%0.1f MB")

            Divider().frame(height: 20)

            debugMetricView(title: "FPS", value: viewModel.fpsUsage,
                            max: viewModel.fpsMax, min: viewModel.fpsMin, avg: viewModel.fpsAvg,
                            format: "%0.0f")

        }
        .padding(10)
        .background(.ultraThickMaterial)
        .cornerRadius(12)
        .overlay(alignment: .topLeading) {
            HStack(spacing: 0) {
                Button {
                    if !isPreviewMode {
                        withAnimation { viewModel.store.isCollapsedVertical.toggle() }
                    }
                } label: {
                    Image(systemName: "arrow.up.and.down.circle")
                        .frame(width: 30, height: 30)
                }
                Button {
                    if !isPreviewMode {
                        withAnimation { viewModel.store.isCollapsedHorizontal.toggle() }
                    }
                } label: {
                    Image(systemName: "arrow.left.and.right.circle")
                        .frame(width: 30, height: 30)
                }
            }
            .padding(.top, -35)
        }
        .overlay(alignment: .topTrailing) {
            Button {
                if !isPreviewMode {
                    withAnimation { viewModel.store.isActive = false }
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .frame(width: 30, height: 30)
            }
            .padding(.top, -35)
        }

    }

    private func debugMetricView(title: String, value: Double, max: Double, min: Double, avg: Double, format: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(viewModel.store.isCollapsedHorizontal ? String(format: format, value) : "\(title): \(String(format: format, value))")
                .font(.caption)
            if viewModel.store.isCollapsedVertical {

                if title == "FPS" {
                    if viewModel.store.fpsShowMax {
                        Text("Max: \(String(format: format, max))").font(.caption2)
                    }
                    if viewModel.store.fpsShowMin {
                        Text("Min: \(String(format: format, min))").font(.caption2)
                    }
                    if viewModel.store.fpsShowAvg {
                        Text("Avg: \(String(format: format, avg))").font(.caption2)
                    }

                } else if title == "MEM" {

                    if viewModel.store.memShowMax {
                        Text("Max: \(String(format: format, max))").font(.caption2)
                    }
                    if viewModel.store.memShowMin {
                        Text("Min: \(String(format: format, min))").font(.caption2)
                    }
                    if viewModel.store.memShowAvg {
                        Text("Avg: \(String(format: format, avg))").font(.caption2)
                    }

                } else if title == "CPU" {

                    if viewModel.store.cpuShowMax {
                        Text("Max: \(String(format: format, max))").font(.caption2)
                    }
                    if viewModel.store.cpuShowMin {
                        Text("Min: \(String(format: format, min))").font(.caption2)
                    }
                    if viewModel.store.cpuShowAvg {
                        Text("Avg: \(String(format: format, avg))").font(.caption2)
                    }
                }
            }
        }
        .frame(minWidth: 40)
    }
}



#Preview {
    PerformanceMonitoringView()
}
