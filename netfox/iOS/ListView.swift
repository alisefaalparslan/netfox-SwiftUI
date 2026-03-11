//
//  ListView.swift
//
//  Created by alisefaalparslan on 5.07.2025.
//

import Foundation
import SwiftUI

struct ListView: View {
    @State private var allModels: [NFXHTTPModel] = []
    @State private var filteredModels: [NFXHTTPModel] = []
    @State private var filter: String = ""
    @State private var selectedModel: NFXHTTPModel?
    @State private var showClearConfirmation = false
    @State private var showSettings = false
    @State private var showToolBar = false
    @State private var showSourceBar = false
    @Environment(\.presentationMode) private var presentationMode

    @State var selectedStatus: FiltersStatusType = .all
    @State var selectedSortByDurationTime: FiltersSortByTimeType = .clear
    @State var selectedSortByStartTime: FiltersSortByTimeType = .clear
    @State var selectedSortByFinishTime: FiltersSortByTimeType = .clear
    @State var ignoredDomains: [String] = []
    
    @State private var allDomains: [String] = []
    @State private var maxTimeInterval: Float = 0.0

    var body: some View {
        NavigationStack {
            List(filteredModels, id: \.randomHash) { model in
                NavigationLink(destination: DetailsView(selectedModel: model)) {
                    ListItemView(model: model)
                    .padding(.vertical, 5)
                }
            }
            .listStyle(.grouped)
            .navigationTitle("")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button(action: { showClearConfirmation = true }) {
                        Image(systemName: "trash")
                    }

                    Button(action: { showSettings = true }) {
                        Image(systemName: "gear")
                    }

                    Button(action: { showToolBar = true }) {
                        Image(systemName: "line.3.horizontal.decrease")
                    }

                    Button(action: { showSourceBar = true }) {
                        Image(systemName: "cpu")
                    }
                }

                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Text("T: \(filteredModels.count)")
                        .font(.system(size: 12))
                    
                    Text("S: \(String(format: "%.2f", maxTimeInterval))")
                        .font(.system(size: 12))
                }
            }
            .searchable(text: $filter, placement: .navigationBarDrawer(displayMode: .always))
            .onChange(of: allModels) { _ in updateFilteredData() }
            .onChange(of: filter) { _ in updateFilteredData() }
            .onChange(of: selectedStatus) { _ in updateFilteredData() }
            .onChange(of: selectedSortByDurationTime) { _ in updateFilteredData() }
            .onChange(of: selectedSortByStartTime) { _ in updateFilteredData() }
            .onChange(of: selectedSortByFinishTime) { _ in updateFilteredData() }
            .onChange(of: ignoredDomains) { _ in updateFilteredData() }
            .confirmationDialog("Clear data?", isPresented: $showClearConfirmation) {
                Button("Yes", role: .destructive) {
                    NFX.sharedInstance().clearOldData()
                }
                Button("Cancel", role: .cancel) { }
            }
            .sheet(isPresented: $showToolBar) {
                FilterView(
                    selectedStatus: $selectedStatus,
                    selectedSortByDurationTime: $selectedSortByDurationTime,
                    selectedSortByFinishTime: $selectedSortByFinishTime,
                    selectedSortByStartTime: $selectedSortByStartTime,
                    ignoredDomains: ignoredDomains,
                    allDomains: allDomains
                ) { ignoredDomains in
                    if ignoredDomains != self.ignoredDomains {
                        self.ignoredDomains = ignoredDomains
                    }
                }
            }
            .sheet(isPresented: $showSourceBar) {
                PerformanceMonitoringSettingsView()
            }
            .onAppear {
                NFXHTTPModelManager.shared.publisher.subscribe { models in
                    allModels = models
                }
                allModels = NFXHTTPModelManager.shared.filteredModels
                self.ignoredDomains = NFXHTTPModelManager.shared.ignoredDomains
                self.selectedStatus = NFXHTTPModelManager.shared.selectedStatus
                self.selectedSortByDurationTime = NFXHTTPModelManager.shared.selectedSortByDurationTime
                self.selectedSortByStartTime = NFXHTTPModelManager.shared.selectedSortByStartTime
                self.selectedSortByFinishTime = NFXHTTPModelManager.shared.selectedSortByFinishTime
                updateFilteredData()
            }
            .onDisappear {
                NFXHTTPModelManager.shared.ignoredDomains = self.ignoredDomains
                NFXHTTPModelManager.shared.selectedStatus = self.selectedStatus
                NFXHTTPModelManager.shared.selectedSortByDurationTime = self.selectedSortByDurationTime
                NFXHTTPModelManager.shared.selectedSortByStartTime = self.selectedSortByStartTime
                NFXHTTPModelManager.shared.selectedSortByFinishTime = self.selectedSortByFinishTime
            }
            .navigationDestination(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }

    private func updateFilteredData() {
        var currentModels = allModels

        // 1. Domains for filter view (cached here to avoid recomputing in body)
        let domains = Set(currentModels.compactMap { $0.requestHost })
        self.allDomains = Array(domains).sorted()

        // 2. Apply search filter
        if !filter.isEmpty {
            let query = filter.lowercased()
            currentModels = currentModels.filter {
                ($0.requestURL?.lowercased().contains(query) == true) ||
                ($0.requestMethod?.lowercased().contains(query) == true) ||
                ($0.responseType?.lowercased().contains(query) == true)
            }
        }

        // 3. Ignore domains
        if !ignoredDomains.isEmpty {
            currentModels = currentModels.filter {
                !ignoredDomains.contains($0.requestHost ?? "")
            }
        }

        // 4. Apply status filter
        switch selectedStatus {
        case .success:
            currentModels = currentModels.filter { (200...299).contains($0.responseStatus ?? 999) }
        case .cache:
            currentModels = currentModels.filter { (300...399).contains($0.responseStatus ?? 999) }
        case .error:
            currentModels = currentModels.filter { ($0.responseStatus ?? 999) >= 400 }
        case .all:
            break
        }

        // 5. Apply sorting
        if selectedSortByDurationTime != .clear {
            currentModels.sort { selectedSortByDurationTime == .asc ? ($0.timeInterval ?? 0) < ($1.timeInterval ?? 0) : ($0.timeInterval ?? 0) > ($1.timeInterval ?? 0) }
        } else if selectedSortByStartTime != .clear {
            currentModels.sort { selectedSortByStartTime == .asc ? ($0.requestDate ?? Date.distantPast) < ($1.requestDate ?? Date.distantPast) : ($0.requestDate ?? Date.distantPast) > ($1.requestDate ?? Date.distantPast) }
        } else if selectedSortByFinishTime != .clear {
            currentModels.sort { selectedSortByFinishTime == .asc ? ($0.responseDate ?? Date.distantPast) < ($1.responseDate ?? Date.distantPast) : ($0.responseDate ?? Date.distantPast) > ($1.responseDate ?? Date.distantPast) }
        } else {
            // Default: Newest first (Manager appends, so we reverse)
            currentModels.reverse()
        }

        self.filteredModels = currentModels
        self.maxTimeInterval = currentModels.map { $0.timeInterval ?? 0.0 }.max() ?? 0.0
    }
}

class NFXListController_SwiftUI: UIHostingController<ListView> {
    required init?(coder: NSCoder) {
        super.init(coder: coder, rootView: ListView())
    }

    override init(rootView: ListView) {
        super.init(rootView: rootView)
    }

    convenience init() {
        self.init(rootView: ListView())
    }
}


#Preview {
    ListView()
}
