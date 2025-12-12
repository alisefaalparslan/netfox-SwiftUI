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
        .onDisappear {
            print("asdasdasd")
        }        
    }

    private var content: some View {
        HStack {

            VStack(alignment: .center, spacing: 2) {
                if !viewModel.store.isCollapsedHorizontal {
                    Text("X")
                        .font(.caption)
                }
                Text("Cur:")
                    .font(.caption)
                if viewModel.store.isCollapsedVertical {

                    Text("Max:").font(.caption2)
                    Text("Min:").font(.caption2)
                    Text("Avg:").font(.caption2)
                    Image(systemName: "xmark.circle.fill")
                        .padding(.top, 5)
                        .foregroundStyle(.clear)

                }
            }

            Divider().frame(height: 20)

            debugMetricView(title: "CPU", value: viewModel.cpuUsage,
                            max: viewModel.cpuMax, min: viewModel.cpuMin, avg: viewModel.cpuAvg,
                            format: "%0.1f%%")

            Divider().frame(height: 20)

            debugMetricView(title: "MEM", value: viewModel.memoryUsage,
                            max: viewModel.memoryMax, min: viewModel.memoryMin, avg: viewModel.memoryAvg,
                            format: "%0.1f")

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

                Button {
                    if !isPreviewMode {
                        withAnimation { NFX.sharedInstance().show() }
                    }
                } label: {
                    Image(systemName: "gearshape.circle")
                        .frame(width: 30, height: 30)
                }
            }
            .padding(.top, -35)
        }
        .overlay(alignment: .topTrailing) {
            Button {
                if !isPreviewMode {
                    withAnimation {
                        viewModel.store.isActive = false
                        viewModel.stop()
                    }
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .frame(width: 30, height: 30)
            }
            .padding(.top, -35)
        }

    }

    private func debugMetricView(title: String, value: Double, max: Double, min: Double, avg: Double, format: String) -> some View {
        VStack(alignment: .center, spacing: 2) {

            if !viewModel.store.isCollapsedHorizontal {
                Text("\(title)")
                    .font(.caption)
            }
            Text(String(format: format, value))
                .font(.caption)
            if viewModel.store.isCollapsedVertical {

                if title == "FPS" {
                    if viewModel.store.fpsShowMax {
                        Text("\(String(format: format, max))").font(.caption2)
                    }
                    if viewModel.store.fpsShowMin {
                        Text("\(String(format: format, min))").font(.caption2)
                    }
                    if viewModel.store.fpsShowAvg {
                        Text("\(String(format: format, avg))").font(.caption2)
                    }

                    Image(systemName: "xmark.circle.fill")
                        .padding(.top, 5)
                        .onTapGesture {
                            viewModel.resetFPS()
                        }


                } else if title == "MEM" {

                    if viewModel.store.memShowMax {
                        Text("\(String(format: format, max))").font(.caption2)
                    }
                    if viewModel.store.memShowMin {
                        Text("\(String(format: format, min))").font(.caption2)
                    }
                    if viewModel.store.memShowAvg {
                        Text("\(String(format: format, avg))").font(.caption2)
                    }

                    Image(systemName: "xmark.circle.fill")
                        .padding(.top, 5)
                        .onTapGesture {
                            viewModel.resetMEM()
                        }

                } else if title == "CPU" {

                    if viewModel.store.cpuShowMax {
                        Text("\(String(format: format, max))").font(.caption2)
                    }
                    if viewModel.store.cpuShowMin {
                        Text("\(String(format: format, min))").font(.caption2)
                    }
                    if viewModel.store.cpuShowAvg {
                        Text("\(String(format: format, avg))").font(.caption2)
                    }

                    Image(systemName: "xmark.circle.fill")
                        .padding(.top, 5)
                        .onTapGesture {
                            viewModel.resetCPU()
                        }
                }
            }
        }
        .frame(width: 40)
    }
}



#Preview {
    PerformanceMonitoringView()
}
