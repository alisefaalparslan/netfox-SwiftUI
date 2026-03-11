//
//  NFXHTTPModelManager.swift
//  netfox
//
//  Copyright © 2016 netfox. All rights reserved.
//

import Foundation


final class NFXHTTPModelManager: NSObject {
    
    static let shared = NFXHTTPModelManager()
    
    let publisher = Publisher<[NFXHTTPModel]>()
       
    /// Not thread safe. Use only from main thread/queue
    private(set) var models = [NFXHTTPModel]() {
        didSet {
            scheduleNotification()
        }
    }
    
    /// Not thread safe. Use only from main thread/queue
    var filters = [Bool](repeating: true, count: HTTPModelShortType.allCases.count) {
        didSet {
            _cachedFilteredModels = nil
            scheduleNotification()
        }
    }

    var ignoredDomains: [String] = []
    var selectedStatus: FiltersStatusType = .all
    var selectedSortByDurationTime: FiltersSortByTimeType = .clear
    var selectedSortByStartTime: FiltersSortByTimeType = .clear
    var selectedSortByFinishTime: FiltersSortByTimeType = .clear

    var sharedMonitorConfig = NetfoxSettingsStore()

    private var _cachedFilteredModels: [NFXHTTPModel]?
    
    /// Not thread safe. Use only from main thread/queue
    var filteredModels: [NFXHTTPModel] {
        if let cached = _cachedFilteredModels {
            return cached
        }
        let filteredTypes = Set(getCachedFilterTypes())
        let result = models.filter { filteredTypes.contains($0.shortType) }
        _cachedFilteredModels = result
        return result
    }
    
    private var notificationPending = false
    
    private func scheduleNotification() {
        guard !notificationPending else { return }
        notificationPending = true
        
        // Throttle notifications to main thread to avoid UI overload
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            self.notificationPending = false
            self._cachedFilteredModels = nil // Reset cache
            self.notifySubscribers()
        }
    }
    
    /// Thread safe
    func add(_ obj: NFXHTTPModel) {
        DispatchQueue.main.async {
            self.models.append(obj)
            self._cachedFilteredModels = nil
        }
    }
    
    /// Not thread safe. Use only from main thread/queue
    func clear() {
        models.removeAll()
        _cachedFilteredModels = nil
    }
    
    private func getCachedFilterTypes() -> [HTTPModelShortType] {
        return filters
            .enumerated()
            .compactMap { $1 ? HTTPModelShortType.allCases[$0] : nil }
    }
    
    private func notifySubscribers() {
        if publisher.hasSubscribers {
            publisher(filteredModels)
        }
    }
    
}
