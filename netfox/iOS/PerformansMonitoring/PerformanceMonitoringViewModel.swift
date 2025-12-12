//
//  PerformanceMonitoringViewModel.swift
//  netfox
//
//  Created by alisefa on 14.07.2025.
//  Copyright © 2025 kasketis. All rights reserved.
//

import Foundation
import Combine

final class PerformanceMonitoringViewModel: ObservableObject {
    @Published var memoryUsage: Double = 0
    @Published var memoryMax: Double = 0
    @Published var memoryMin: Double = .infinity
    @Published var memoryAvg: Double = 0

    @Published var cpuUsage: Double = 0
    @Published var cpuMax: Double = 0
    @Published var cpuMin: Double = .infinity
    @Published var cpuAvg: Double = 0

    @Published var fpsUsage: Double = 0
    @Published var fpsMax: Double = 0
    @Published var fpsMin: Double = .infinity
    @Published var fpsAvg: Double = 0

    @Published var isActive: Bool = NFXHTTPModelManager.shared.sharedMonitorConfig.isActive

    private var memoryCount: Double = 0
    private var cpuCount: Double = 0
    private var fpsCount: Double = 0

    private var cancellables = Set<AnyCancellable>()
    private let fpsMonitor = FPSMonitor()

    @Published var store = NFXHTTPModelManager.shared.sharedMonitorConfig

    func start() {
        if store.memMonitoringEnabled {
            Timer.publish(every: store.memCheckInterval, on: .main, in: .common)
                .autoconnect()
                .sink { [weak self] _ in self?.updateMemory() }
                .store(in: &cancellables)
        }

        if store.cpuMonitoringEnabled {
            Timer.publish(every: store.cpuCheckInterval, on: .main, in: .common)
                .autoconnect()
                .sink { [weak self] _ in self?.updateCPU() }
                .store(in: &cancellables)
        }

        if store.fpsMonitoringEnabled {
            fpsMonitor.fpsUpdateHandler = { [weak self] fps in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.fpsUsage = fps

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

        store.$isActive
            .sink { newValue in
                self.isActive = newValue
            }
            .store(in: &cancellables)
    }

    func stop() {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        fpsMonitor.stop()

        store.$isActive
            .sink { newValue in
                self.isActive = newValue
            }
            .store(in: &cancellables)
    }

    private func updateMemory() {
        let mem = getMemoryUsage() ?? 0
        memoryUsage = mem

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
    }

    func resetMEM() {
        memoryMax = 0
        memoryMin = .infinity
        memoryAvg = 0
        memoryCount = 0
    }

    func resetFPS() {
        fpsMax = 0
        fpsMin = .infinity
        fpsAvg = 0
        fpsCount = 0
    }
}
