//
//  FilterView.swift
//
//  Created by alisefaalparslan on 5.07.2025.
//

import SwiftUI

struct FilterView: View {
    @Binding var selectedStatus: FiltersStatusType
    @Binding var selectedSortByDurationTime: FiltersSortByTimeType
    @Binding var selectedSortByFinishTime: FiltersSortByTimeType
    @Binding var selectedSortByStartTime: FiltersSortByTimeType

    @State var ignoredDomains: [String]

    var allDomains: [String]

    var onDissmiss: (([String]) -> Void)

    var body: some View {
        List {
            Section(header: Text("Status Code").font(.headline)) {
                ForEach(FiltersStatusType.allCases) { model in
                    HStack {
                        Text(model.text)
                        Spacer()
                        if selectedStatus == model {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedStatus = model
                    }
                }
            }

            Section(header: Text("Sort by Duration Time").font(.headline)) {
                ForEach(FiltersSortByTimeType.allCases) { model in
                    HStack {
                        Text(model.text)
                        Spacer()
                        if selectedSortByDurationTime == model {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedSortByDurationTime = model
                    }
                }
            }

            Section(header: Text("Sort by Finish Time").font(.headline)) {
                ForEach(FiltersSortByTimeType.allCases) { model in
                    HStack {
                        Text(model.text)
                        Spacer()
                        if selectedSortByFinishTime == model {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedSortByFinishTime = model
                    }
                }
            }

            Section(header: Text("Sort by Start Time").font(.headline)) {
                ForEach(FiltersSortByTimeType.allCases) { model in
                    HStack {
                        Text(model.text)
                        Spacer()
                        if selectedSortByStartTime == model {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedSortByStartTime = model
                    }
                }
            }

            Section(header: Text("Tracked Domains").font(.headline)) {

                Button("Select All") {
                    ignoredDomains = []
                }

                Button("Deselect All") {
                    ignoredDomains = allDomains
                }

                ForEach(allDomains, id: \.self) { domain in
                    HStack {
                        Text(domain)
                        Spacer()
                        if !ignoredDomains.contains(domain) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if !ignoredDomains.contains(domain) {
                            ignoredDomains.append(domain)
                        } else {
                            ignoredDomains.removeAll { $0 == domain }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Filters")
        .onDisappear {
            onDissmiss(ignoredDomains)
        }
    }
}
