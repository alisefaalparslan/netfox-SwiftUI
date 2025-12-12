//
//  PerformanceMonitoringSettingsView.swift
//  netfox
//
//  Created by alisefa on 14.07.2025.
//  Copyright © 2025 kasketis. All rights reserved.
//

import SwiftUI

struct PerformanceMonitoringSettingsView: View {

    @StateObject private var store = NFXHTTPModelManager.shared.sharedMonitorConfig

    var body: some View {
        List {
            Section {

                Toggle(isOn: $store.isActive) {
                    Text("Active:")
                }

                Toggle(isOn: $store.isActiveOnAppStart) {
                    Text("Active on app start:")
                }
            }

            MetricSectionView(
                metricName: "CPU",
                isMonitoring: $store.cpuMonitoringEnabled,
                showAvg: $store.cpuShowAvg,
                showMax: $store.cpuShowMax,
                showMin: $store.cpuShowMin,
                interval: $store.cpuCheckInterval
            )

            MetricSectionView(
                metricName: "MEM",
                isMonitoring: $store.memMonitoringEnabled,
                showAvg: $store.memShowAvg,
                showMax: $store.memShowMax,
                showMin: $store.memShowMin,
                interval: $store.memCheckInterval
            )

            MetricSectionView(
                metricName: "FPS",
                isMonitoring: $store.fpsMonitoringEnabled,
                showAvg: $store.fpsShowAvg,
                showMax: $store.fpsShowMax,
                showMin: $store.fpsShowMin,
                interval: $store.fpsCheckInterval
            )

            Section {

                Text("Preview").font(.headline)

                VStack(alignment: .leading) {
                    Toggle(isOn: $store.isCollapsedVertical) {
                        Text("Collapse Vertical")
                    }

                    Toggle(isOn: $store.isCollapsedHorizontal) {
                        Text("Collapse Horizontal")
                    }
                }

                HStack {
                    Spacer()
                    PerformanceMonitoringView(isPreviewMode: true)
                        .padding(.top, 50)
                        .padding(.bottom, 20)
                    Spacer()
                }
            }            
            .listRowBackground(Color.primary.opacity(0.2))
        }
    }
}

struct MetricSectionView: View {
    let metricName: String

    @Binding var isMonitoring: Bool
    @Binding var showAvg: Bool
    @Binding var showMax: Bool
    @Binding var showMin: Bool
    @Binding var interval: Double

    @State private var textValue: String = ""

    var body: some View {
        Section {
            Text(metricName).font(.headline)

            Toggle(isOn: $isMonitoring) {
                Text("Monitoring state:")
            }

            Toggle(isOn: $showAvg) {
                Text("Show avg:")
            }

            Toggle(isOn: $showMax) {
                Text("Show max:")
            }

            Toggle(isOn: $showMin) {
                Text("Show min:")
            }

            HStack {
                Text("Check interval (sec):")
                Spacer()
                TextField("0.0", text: $textValue)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 100)
                    .disabled(!isMonitoring)
                    .onChange(of: textValue) { newValue in
                        if let doubleValue = Double(newValue) {
                            interval = doubleValue
                        }
                    }
                    .onAppear {
                        textValue = String(format: "%.1f", interval)
                    }
            }
        }
    }
}

final class NetfoxSettingsStore: ObservableObject {
    private let defaults: UserDefaults

    @Published var isActiveOnAppStart: Bool {
        didSet { defaults.set(isActiveOnAppStart, forKey: "isActiveOnAppStart") }
    }

    @Published var isActive: Bool

    @Published var isCollapsedVertical: Bool {
        didSet { defaults.set(isCollapsedVertical, forKey: "isCollapsedVertical") }
    }

    @Published var isCollapsedHorizontal: Bool {
        didSet { defaults.set(isCollapsedHorizontal, forKey: "isCollapsedHorizontal") }
    }

    @Published var cpuMonitoringEnabled: Bool {
        didSet { defaults.set(cpuMonitoringEnabled, forKey: "cpuMonitoringEnabled") }
    }
    @Published var cpuShowAvg: Bool {
        didSet { defaults.set(cpuShowAvg, forKey: "cpuShowAvg") }
    }
    @Published var cpuShowMax: Bool {
        didSet { defaults.set(cpuShowMax, forKey: "cpuShowMax") }
    }
    @Published var cpuShowMin: Bool {
        didSet { defaults.set(cpuShowMin, forKey: "cpuShowMin") }
    }
    @Published var cpuCheckInterval: Double {
        didSet { defaults.set(cpuCheckInterval, forKey: "cpuCheckInterval") }
    }

    @Published var memMonitoringEnabled: Bool {
        didSet { defaults.set(memMonitoringEnabled, forKey: "memMonitoringEnabled") }
    }
    @Published var memShowAvg: Bool {
        didSet { defaults.set(memShowAvg, forKey: "memShowAvg") }
    }
    @Published var memShowMax: Bool {
        didSet { defaults.set(memShowMax, forKey: "memShowMax") }
    }
    @Published var memShowMin: Bool {
        didSet { defaults.set(memShowMin, forKey: "memShowMin") }
    }
    @Published var memCheckInterval: Double {
        didSet { defaults.set(memCheckInterval, forKey: "memCheckInterval") }
    }

    @Published var fpsMonitoringEnabled: Bool {
        didSet { defaults.set(fpsMonitoringEnabled, forKey: "fpsMonitoringEnabled") }
    }
    @Published var fpsShowAvg: Bool {
        didSet { defaults.set(fpsShowAvg, forKey: "fpsShowAvg") }
    }
    @Published var fpsShowMax: Bool {
        didSet { defaults.set(fpsShowMax, forKey: "fpsShowMax") }
    }
    @Published var fpsShowMin: Bool {
        didSet { defaults.set(fpsShowMin, forKey: "fpsShowMin") }
    }
    @Published var fpsCheckInterval: Double {
        didSet { defaults.set(fpsCheckInterval, forKey: "fpsCheckInterval") }
    }

    init() {
        defaults = UserDefaults(suiteName: "netfox") ?? .standard

        let isActiveOnAppStart = NetfoxSettingsStore.getBool("isActiveOnAppStart", default: false)
        self.isActiveOnAppStart = isActiveOnAppStart

        if isActiveOnAppStart {
            isActive = true
        } else {
            isActive = false
        }
        
        isCollapsedVertical = NetfoxSettingsStore.getBool("isCollapsedVertical")
        isCollapsedHorizontal = NetfoxSettingsStore.getBool("isCollapsedHorizontal")

        cpuMonitoringEnabled = NetfoxSettingsStore.getBool("cpuMonitoringEnabled")
        cpuShowAvg = NetfoxSettingsStore.getBool("cpuShowAvg")
        cpuShowMax = NetfoxSettingsStore.getBool("cpuShowMax")
        cpuShowMin = NetfoxSettingsStore.getBool("cpuShowMin")
        cpuCheckInterval = NetfoxSettingsStore.getDouble("cpuCheckInterval")

        memMonitoringEnabled = NetfoxSettingsStore.getBool("memMonitoringEnabled")
        memShowAvg = NetfoxSettingsStore.getBool("memShowAvg")
        memShowMax = NetfoxSettingsStore.getBool("memShowMax")
        memShowMin = NetfoxSettingsStore.getBool("memShowMin")
        memCheckInterval = NetfoxSettingsStore.getDouble("memCheckInterval")

        fpsMonitoringEnabled = NetfoxSettingsStore.getBool("fpsMonitoringEnabled")
        fpsShowAvg = NetfoxSettingsStore.getBool("fpsShowAvg")
        fpsShowMax = NetfoxSettingsStore.getBool("fpsShowMax")
        fpsShowMin = NetfoxSettingsStore.getBool("fpsShowMin")
        fpsCheckInterval = NetfoxSettingsStore.getDouble("fpsCheckInterval", default: 0.5)
    }

    static func getBool(_ key: String, default defaultValue: Bool = true) -> Bool {
        let defaults = UserDefaults(suiteName: "netfox") ?? .standard
        if defaults.object(forKey: key) == nil {
            defaults.set(defaultValue, forKey: key)
            return defaultValue
        }
        return defaults.bool(forKey: key)
    }

    static func getDouble(_ key: String, default defaultValue: Double = 1.0) -> Double {
        let defaults = UserDefaults(suiteName: "netfox") ?? .standard
        let value = defaults.double(forKey: key)
        if value == 0 {
            defaults.set(defaultValue, forKey: key)
            return defaultValue
        }
        return value
    }
}

#Preview {
    PerformanceMonitoringSettingsView()
}
