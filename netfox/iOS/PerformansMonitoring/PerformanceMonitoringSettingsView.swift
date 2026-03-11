//
//  PerformanceMonitoringSettingsView.swift
//  netfox
//
//  Created by alisefa on 14.07.2025.
//  Copyright © 2025 kasketis. All rights reserved.
//

import SwiftUI

struct PerformanceMonitoringSettingsView: View {
    private var store = NFXHTTPModelManager.shared.sharedMonitorConfig

    var body: some View {
        @Bindable var store = store
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
                type: .cpu,
                store: store
            )

            MetricSectionView(
                metricName: "MEM",
                type: .mem,
                store: store
            )

            MetricSectionView(
                metricName: "FPS",
                type: .fps,
                store: store
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
    enum MetricType { case cpu, mem, fps }
    
    let metricName: String
    let type: MetricType
    @Bindable var store: NetfoxSettingsStore

    @State private var textValue: String = ""

    var body: some View {
        Section {
            Text(metricName).font(.headline)

            Toggle(isOn: binding(for: .isMonitoring)) {
                Text("Monitoring state:")
            }

            Toggle(isOn: binding(for: .showAvg)) {
                Text("Show avg:")
            }

            Toggle(isOn: binding(for: .showMax)) {
                Text("Show max:")
            }

            Toggle(isOn: binding(for: .showMin)) {
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
                            setInterval(doubleValue)
                        }
                    }
                    .onAppear {
                        textValue = String(format: "%.1f", interval)
                    }
            }
        }
    }
    
    private var isMonitoring: Bool {
        switch type {
        case .cpu: return store.cpuMonitoringEnabled
        case .mem: return store.memMonitoringEnabled
        case .fps: return store.fpsMonitoringEnabled
        }
    }
    
    private var interval: Double {
        switch type {
        case .cpu: return store.cpuCheckInterval
        case .mem: return store.memCheckInterval
        case .fps: return store.fpsCheckInterval
        }
    }
    
    private func setInterval(_ val: Double) {
        switch type {
        case .cpu: store.cpuCheckInterval = val
        case .mem: store.memCheckInterval = val
        case .fps: store.fpsCheckInterval = val
        }
    }
    
    private enum PropertyType { case isMonitoring, showAvg, showMax, showMin }
    
    private func binding(for prop: PropertyType) -> Binding<Bool> {
        switch type {
        case .cpu:
            switch prop {
            case .isMonitoring: return $store.cpuMonitoringEnabled
            case .showAvg: return $store.cpuShowAvg
            case .showMax: return $store.cpuShowMax
            case .showMin: return $store.cpuShowMin
            }
        case .mem:
            switch prop {
            case .isMonitoring: return $store.memMonitoringEnabled
            case .showAvg: return $store.memShowAvg
            case .showMax: return $store.memShowMax
            case .showMin: return $store.memShowMin
            }
        case .fps:
            switch prop {
            case .isMonitoring: return $store.fpsMonitoringEnabled
            case .showAvg: return $store.fpsShowAvg
            case .showMax: return $store.fpsShowMax
            case .showMin: return $store.fpsShowMin
            }
        }
    }
}

@Observable
final class NetfoxSettingsStore {
    private let defaults: UserDefaults

    var isActiveOnAppStart: Bool {
        didSet { defaults.set(isActiveOnAppStart, forKey: "isActiveOnAppStart") }
    }

    var isActive: Bool

    var isCollapsedVertical: Bool {
        didSet { defaults.set(isCollapsedVertical, forKey: "isCollapsedVertical") }
    }

    var isCollapsedHorizontal: Bool {
        didSet { defaults.set(isCollapsedHorizontal, forKey: "isCollapsedHorizontal") }
    }

    var cpuMonitoringEnabled: Bool {
        didSet { defaults.set(cpuMonitoringEnabled, forKey: "cpuMonitoringEnabled") }
    }
    var cpuShowAvg: Bool {
        didSet { defaults.set(cpuShowAvg, forKey: "cpuShowAvg") }
    }
    var cpuShowMax: Bool {
        didSet { defaults.set(cpuShowMax, forKey: "cpuShowMax") }
    }
    var cpuShowMin: Bool {
        didSet { defaults.set(cpuShowMin, forKey: "cpuShowMin") }
    }
    var cpuCheckInterval: Double {
        didSet { defaults.set(cpuCheckInterval, forKey: "cpuCheckInterval") }
    }

    var memMonitoringEnabled: Bool {
        didSet { defaults.set(memMonitoringEnabled, forKey: "memMonitoringEnabled") }
    }
    var memShowAvg: Bool {
        didSet { defaults.set(memShowAvg, forKey: "memShowAvg") }
    }
    var memShowMax: Bool {
        didSet { defaults.set(memShowMax, forKey: "memShowMax") }
    }
    var memShowMin: Bool {
        didSet { defaults.set(memShowMin, forKey: "memShowMin") }
    }
    var memCheckInterval: Double {
        didSet { defaults.set(memCheckInterval, forKey: "memCheckInterval") }
    }

    var fpsMonitoringEnabled: Bool {
        didSet { defaults.set(fpsMonitoringEnabled, forKey: "fpsMonitoringEnabled") }
    }
    var fpsShowAvg: Bool {
        didSet { defaults.set(fpsShowAvg, forKey: "fpsShowAvg") }
    }
    var fpsShowMax: Bool {
        didSet { defaults.set(fpsShowMax, forKey: "fpsShowMax") }
    }
    var fpsShowMin: Bool {
        didSet { defaults.set(fpsShowMin, forKey: "fpsShowMin") }
    }
    var fpsCheckInterval: Double {
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

        isActive = true

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
