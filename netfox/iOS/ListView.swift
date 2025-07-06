//
//  ListView.swift
//
//  Created by alisefaalparslan on 5.07.2025.
//

import Foundation
import SwiftUI

struct ListView: View {
    @State private var allModels: [NFXHTTPModel] = []
    @State private var filter: String = ""
    @State private var selectedModel: NFXHTTPModel?
    @State private var showClearConfirmation = false
    @State private var showSettings = false
    @State private var showToolBar = false
    @Environment(\.presentationMode) private var presentationMode

    private let dataSubscription = NFXHTTPModelManager.shared.publisher

    @State var selectedStatus: FiltersStatusType = .all
    @State var selectedSortByDurationTime: FiltersSortByTimeType = .clear
    @State var selectedSortByStartTime: FiltersSortByTimeType = .clear
    @State var selectedSortByFinishTime: FiltersSortByTimeType = .clear
    @State var ignoredDomains: [String] = []

    var body: some View {
        NavigationStack {
            List(filteredData, id: \.randomHash) { model in
                NavigationLink(destination: DetailsView(selectedModel: model)) {
                    ListItemView(model: model)
                    .padding(.vertical, 5)
                }
            }
            .listStyle(.grouped)
            .navigationTitle("Requests")
            .toolbar {

                ToolbarItemGroup(placement: .navigationBarLeading) {

                    Button(action: { showToolBar = true }) {
                        Image(systemName: "line.3.horizontal.decrease")
                    }

                    Text("T: \(filteredData.count)")
                        .font(.system(size: 12))

                    Text("S: \(String(format: "%.2f", filteredData.max(by: { $0.timeInterval ?? 0 < $1.timeInterval ?? 0 })?.timeInterval ?? 0.0))")
                        .font(.system(size: 12))
                }

                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: { showClearConfirmation = true }) {
                        Image(systemName: "trash")
                    }
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gear")
                    }
                }
            }
            .searchable(text: $filter, placement: .navigationBarDrawer(displayMode: .always))
            .onChange(of: selectedStatus) { newValue in

            }
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
                    allDomains: Array(Set(allModels.compactMap { $0.requestHost })).sorted()
                ) { ignoredDomains in
                    if ignoredDomains != self.ignoredDomains {
                        self.ignoredDomains = ignoredDomains
                    }
                }
            }
            .onAppear {
                NFXHTTPModelManager.shared.publisher.subscribe { models in
                    allModels = models
                }
                populate(with: NFXHTTPModelManager.shared.filteredModels)
                self.ignoredDomains = NFXHTTPModelManager.shared.ignoredDomains
                self.selectedStatus = NFXHTTPModelManager.shared.selectedStatus
                self.selectedSortByDurationTime = NFXHTTPModelManager.shared.selectedSortByDurationTime
                self.selectedSortByStartTime = NFXHTTPModelManager.shared.selectedSortByStartTime
                self.selectedSortByFinishTime = NFXHTTPModelManager.shared.selectedSortByFinishTime
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

    private var filteredData: [NFXHTTPModel] {
         var currentModels = allModels

         // 1. Apply search filter
         if !filter.isEmpty {
             currentModels = currentModels.filter {
                 ($0.requestURL?.range(of: filter, options: [.caseInsensitive, .diacriticInsensitive]) != nil) ||
                 ($0.requestMethod?.range(of: filter, options: [.caseInsensitive, .diacriticInsensitive]) != nil) ||
                 ($0.responseType?.range(of: filter, options: [.caseInsensitive, .diacriticInsensitive]) != nil)
             }
         }

        if !ignoredDomains.isEmpty {
            currentModels = currentModels.filter {
                !ignoredDomains.contains($0.requestHost ?? "")
            }
        }

         // 2. Apply status filter
         switch selectedStatus {
         case .success:
             currentModels = currentModels.filter { ($0.responseStatus ?? 999) >= 200 && ($0.responseStatus ?? 999) < 300 } // Success codes typically 2xx
         case .cache:
             currentModels = currentModels.filter { ($0.responseStatus ?? 999) >= 300 && ($0.responseStatus ?? 999) < 400 } // Redirection codes typically 3xx (often cached)
         case .error:
             currentModels = currentModels.filter { ($0.responseStatus ?? 999) >= 400 } // Error codes 4xx or 5xx
         case .all:
             break
         }

         // 3. Apply sorting
         switch selectedSortByDurationTime {
         case .asc:
             currentModels.sort { ($0.timeInterval ?? 0) < ($1.timeInterval ?? 0) }
         case .desc:
             currentModels.sort { ($0.timeInterval ?? 0) > ($1.timeInterval ?? 0) }
         case .clear:
             break
         }

        switch selectedSortByStartTime {
        case .asc:
            currentModels.sort { ($0.requestDate ?? Date()) < ($1.requestDate ?? Date()) }
        case .desc:
            currentModels.sort { ($0.requestDate ?? Date()) > ($1.requestDate ?? Date()) }
        case .clear:
            break
        }

        switch selectedSortByFinishTime {
        case .asc:
            currentModels.sort { ($0.responseDate ?? Date()) < ($1.responseDate ?? Date()) }
        case .desc:
            currentModels.sort { ($0.responseDate ?? Date()) > ($1.responseDate ?? Date()) }
        case .clear:
            break
        }

         return currentModels
     }

    private func populate(with models: [NFXHTTPModel]) {
        allModels = models
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
