//
//  PerformanceMonitoringViewModel.swift
//  netfox
//
//  Created by alisefa on 14.07.2025.
//  Copyright © 2025 kasketis. All rights reserved.
//

import Foundation

@Observable
@MainActor
final class PerformanceMonitoringViewModel {
    var memoryUsage: Double = 0
    var memoryMax: Double = 0
    var memoryMin: Double = .infinity
    var memoryAvg: Double = 0
    var memoryHistory: [Double] = []

    var cpuUsage: Double = 0
    var cpuMax: Double = 0
    var cpuMin: Double = .infinity
    var cpuAvg: Double = 0
    var cpuHistory: [Double] = []

    var fpsUsage: Double = 0
    var fpsMax: Double = 0
    var fpsMin: Double = .infinity
    var fpsAvg: Double = 0
    var fpsHistory: [Double] = []

    var thermalState: ProcessInfo.ThermalState = .nominal
    var activeRequests: Int = 0

    var isActive: Bool {
        get { store.isActive }
        set { store.isActive = newValue }
    }

    private var memoryCount: Double = 0
    private var cpuCount: Double = 0
    private var fpsCount: Double = 0
    private let historyLimit = 30

    private var monitoringTasks: [Task<Void, Never>] = []
    private var nfxSubscription: Subscription<[NFXHTTPModel]>?
    private let fpsMonitor = FPSMonitor()

    var store = NFXHTTPModelManager.shared.sharedMonitorConfig

    func start() {
        stop()

        thermalState = ProcessInfo.processInfo.thermalState
        monitoringTasks.append(Task {
            for await _ in NotificationCenter.default.notifications(named: ProcessInfo.thermalStateDidChangeNotification) {
                self.thermalState = ProcessInfo.processInfo.thermalState
            }
        })

        nfxSubscription = NFXHTTPModelManager.shared.publisher.subscribe { [weak self] models in
            Task { @MainActor in
                self?.activeRequests = models.filter { $0.responseTime == nil }.count
            }
        }
        activeRequests = NFXHTTPModelManager.shared.filteredModels.filter { $0.responseTime == nil }.count

        if store.memMonitoringEnabled {
            monitoringTasks.append(Task {
                while !Task.isCancelled {
                    self.updateMemory()
                    try? await Task.sleep(nanoseconds: UInt64(store.memCheckInterval * 1_000_000_000))
                }
            })
        }

        if store.cpuMonitoringEnabled {
            monitoringTasks.append(Task {
                while !Task.isCancelled {
                    self.updateCPU()
                    try? await Task.sleep(nanoseconds: UInt64(store.cpuCheckInterval * 1_000_000_000))
                }
            })
        }

        if store.fpsMonitoringEnabled {
            fpsMonitor.fpsUpdateHandler = { [weak self] fps in
                guard let self = self else { return }
                Task { @MainActor in
                    self.fpsUsage = fps
                    self.addToHistory(val: fps, history: &self.fpsHistory)

                    if self.store.fpsShowMax {
                        self.fpsMax = max(self.fpsMax, fps)
                    }

                    if self.store.fpsShowMin {
                        self.fpsMin = min(self.fpsMin, fps)
                    }

                    if self.store.fpsShowAvg {
                        self.fpsCount += 1
                        self.fpsAvg = (self.fpsAvg * (self.fpsCount - 1) + fps) / self.fpsCount
                    }
                }
            }
            fpsMonitor.start(with: store.fpsCheckInterval)
        }
    }

    private func addToHistory(val: Double, history: inout [Double]) {
        history.append(val)
        if history.count > historyLimit {
            history.removeFirst()
        }
    }

    func stop() {
        monitoringTasks.forEach { $0.cancel() }
        monitoringTasks.removeAll()
        nfxSubscription?.cancel()
        nfxSubscription = nil
        fpsMonitor.stop()
    }

    private func updateMemory() {
        let mem = getMemoryUsage() ?? 0
        memoryUsage = mem
        addToHistory(val: mem, history: &memoryHistory)

        if store.memShowMax {
            memoryMax = max(memoryMax, mem)
        }

        if store.memShowMin {
            memoryMin = min(memoryMin, mem)
        }

        if store.memShowAvg {
            memoryCount += 1
            memoryAvg = (memoryAvg * (memoryCount - 1) + mem) / memoryCount
        }
    }

    private func updateCPU() {
        let cpu = getCPUUsage() ?? 0
        cpuUsage = cpu
        addToHistory(val: cpu, history: &cpuHistory)

        if store.cpuShowMax {
            cpuMax = max(cpuMax, cpu)
        }

        if store.cpuShowMin {
            cpuMin = min(cpuMin, cpu)
        }

        if store.cpuShowAvg {
            cpuCount += 1
            cpuAvg = (cpuAvg * (cpuCount - 1) + cpu) / cpuCount
        }
    }

    func resetCPU() {
        cpuMax = 0
        cpuMin = .infinity
        cpuAvg = 0
        cpuCount = 0
        cpuHistory.removeAll()
    }

    func resetMEM() {
        memoryMax = 0
        memoryMin = .infinity
        memoryAvg = 0
        memoryCount = 0
        memoryHistory.removeAll()
    }

    func resetFPS() {
        fpsMax = 0
        fpsMin = .infinity
        fpsAvg = 0
        fpsCount = 0
        fpsHistory.removeAll()
    }
}
