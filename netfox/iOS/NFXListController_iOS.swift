//
//  NFXListController.swift
//  netfox
//
//  Copyright © 2016 netfox. All rights reserved.
//

import Foundation
import SwiftUI

struct NFXListView: View {
    @State private var allModels: [NFXHTTPModel] = []
    @State private var filter: String = ""
    @State private var selectedModel: NFXHTTPModel?
    @State private var showClearConfirmation = false
    @State private var showSettings = false
    @Environment(\.presentationMode) private var presentationMode

    private let dataSubscription = NFXHTTPModelManager.shared.publisher

    @State var selectedStatus: LeftToolbarStatus = .all
    @State var selectedSortByDurationTime: LeftToolbarSortByTime = .clear
    @State var selectedSortByStartTime: LeftToolbarSortByTime = .clear
    @State var selectedSortByFinishTime: LeftToolbarSortByTime = .clear

    var body: some View {
        NavigationStack {
            List(filteredData, id: \.randomHash) { model in
                NavigationLink(destination: NFXDetailsView(selectedModel: model)) {
                    NFXListCellView(
                        url: model.requestURL ?? "",
                        status: model.responseStatus ?? 999,
                        timeInterval: model.timeInterval ?? 999,
                        requestTime: model.requestTime ?? "-",
                        type: model.responseType ?? "-",
                        method: model.requestMethod ?? "-",
                        isNew: false
                    )
                    .padding(.vertical, 5)
                }
            }
            .listStyle(.grouped)
            .navigationTitle("Requests")
            .toolbar {

                ToolbarItem(placement: .navigationBarLeading) {
                    if #available(iOS 16.4, *) {
                        LeftToolbarView(
                            selectedStatus: $selectedStatus,
                            selectedSortByDurationTime: $selectedSortByDurationTime,
                            selectedSortByFinishTime: $selectedSortByFinishTime,
                            selectedSortByStartTime: $selectedSortByStartTime
                        )
                    } else {
                        // Fallback on earlier versions
                    }
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
            .onAppear {
                NFXHTTPModelManager.shared.publisher.subscribe { models in
                    allModels = models
                }
                populate(with: NFXHTTPModelManager.shared.filteredModels)
            }
            .navigationDestination(isPresented: $showSettings) {
                NFXSettingsView()
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

class NFXListController_SwiftUI: UIHostingController<NFXListView> {
    required init?(coder: NSCoder) {
        super.init(coder: coder, rootView: NFXListView())
    }

    override init(rootView: NFXListView) {
        super.init(rootView: rootView)
    }

    convenience init() {
        self.init(rootView: NFXListView())
    }
}


#Preview {
    NFXListView()
}

enum LeftToolbarStatus: CaseIterable, Identifiable {

    case success
    case cache
    case error
    case all

    var color: Color {
        switch self {
        case .success:
            return .NFXGreenColor
        case .cache:
            return .NFXOrangeColor
        case .error:
            return .NFXRedColor
        case .all:
            return .yellow
        }
    }

    var text: String {
        switch self {
        case .success:
            return "2XX"
        case .cache:
            return "3XX"
        case .error:
            return "4XX"
        case .all:
            return "All"
        }
    }

    var id: Int {
        text.hashValue
    }
}

enum LeftToolbarSortByTime: CaseIterable, Identifiable {

    case desc
    case asc
    case clear

    var color: Color {
        switch self {
        case .desc:
            return .NFXGreenColor
        case .asc:
            return .NFXRedColor
        case .clear:
            return .yellow
        }
    }

    var text: String {
        switch self {
        case .desc:
            return "Desc"
        case .asc:
            return "Asc"
        case .clear:
            return "Clear"
        }
    }

    var id: Int {
        text.hashValue
    }
}


@available(iOS 16.4, *)
struct LeftToolbarView: View {
    @State private var isHamburgerMenuVisible: Bool = false

    @Binding var selectedStatus: LeftToolbarStatus
    @Binding var selectedSortByDurationTime: LeftToolbarSortByTime
    @Binding var selectedSortByFinishTime: LeftToolbarSortByTime
    @Binding var selectedSortByStartTime: LeftToolbarSortByTime

    var body: some View {
        Image(systemName: "line.3.horizontal.decrease")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundStyle(.blue)
            .customPopover(
                isPresented: $isHamburgerMenuVisible,
                showDirection: .bottom
            ) {
                ZStack {
                    Color(UIColor.systemBackground).ignoresSafeArea(edges: .all)

                    VStack(spacing: 20) {
                        Text("Status Code")
                            .font(.headline)
                        HStack(spacing: 10) {

                            ForEach(LeftToolbarStatus.allCases) { model in
                                Text(model.text)
                                    .font(.caption)
                                    .foregroundStyle(Color.black)
                                    .frame(height: 40)
                                    .padding(.horizontal, 5)
                                    .frame(minWidth: 20)
                                    .background(model.color)
                                    .clipShape(RoundedRectangle(cornerRadius: 5))
                                    .overlay(alignment: .top) {
                                        Rectangle()
                                            .frame(height: model == selectedStatus ? 5 : 0)
                                            .foregroundColor(Color(UIColor.label))
                                    }
                                    .onTapGesture {
                                        selectedStatus = model
                                        isHamburgerMenuVisible = false
                                    }
                            }

                        }

                        Divider()

                        Text("Sort by duration time")
                            .font(.headline)
                        HStack(spacing: 10) {

                            ForEach(LeftToolbarSortByTime.allCases) { model in
                                Text(model.text)
                                    .font(.caption)
                                    .foregroundStyle(Color.black)
                                    .frame(height: 40)
                                    .padding(.horizontal, 5)
                                    .frame(minWidth: 20)
                                    .background(model.color)
                                    .clipShape(RoundedRectangle(cornerRadius: 5))
                                    .overlay(alignment: .top) {
                                        Rectangle()
                                            .frame(height: model == selectedSortByDurationTime ? 5 : 0)
                                            .foregroundColor(Color(UIColor.label))
                                    }
                                    .onTapGesture {
                                        selectedSortByDurationTime = model
                                        isHamburgerMenuVisible = false
                                    }
                            }
                        }

                        Divider()

                        Text("Sort by finish time")
                            .font(.headline)
                        HStack(spacing: 10) {

                            ForEach(LeftToolbarSortByTime.allCases) { model in
                                Text(model.text)
                                    .font(.caption)
                                    .foregroundStyle(Color.black)
                                    .frame(height: 40)
                                    .padding(.horizontal, 5)
                                    .frame(minWidth: 20)
                                    .background(model.color)
                                    .clipShape(RoundedRectangle(cornerRadius: 5))
                                    .overlay(alignment: .top) {
                                        Rectangle()
                                            .frame(height: model == selectedSortByFinishTime ? 5 : 0)
                                            .foregroundColor(Color(UIColor.label))
                                    }
                                    .onTapGesture {
                                        selectedSortByFinishTime = model
                                        isHamburgerMenuVisible = false
                                    }
                            }
                        }

                        Divider()

                        Text("Sort by start time")
                            .font(.headline)
                        HStack(spacing: 10) {

                            ForEach(LeftToolbarSortByTime.allCases) { model in
                                Text(model.text)
                                    .font(.caption)
                                    .foregroundStyle(Color.black)
                                    .frame(height: 40)
                                    .padding(.horizontal, 5)
                                    .frame(minWidth: 20)
                                    .background(model.color)
                                    .clipShape(RoundedRectangle(cornerRadius: 5))
                                    .overlay(alignment: .top) {
                                        Rectangle()
                                            .frame(height: model == selectedSortByStartTime ? 5 : 0)
                                            .foregroundColor(Color(UIColor.label))
                                    }
                                    .onTapGesture {
                                        selectedSortByStartTime = model
                                        isHamburgerMenuVisible = false
                                    }
                            }
                        }

                    }
                    .padding()
                }
                .frame(width: 250)
                .presentationCompactAdaptation(.none)
            }
    }
}



struct CustomPopoverModifier<PopoverContent: View>: ViewModifier {

    @Binding var isPresented: Bool
    let showDirection: Edge

    @ViewBuilder let content: () -> PopoverContent

    func body(content: Content) -> some View {
        content
            .popover(
                isPresented: $isPresented,
                attachmentAnchor: attachmentAnchor,
                arrowEdge: arrowEdge,
                content: self.content
            )
            .onTapGesture {
                isPresented.toggle()
            }
    }

    var arrowEdge: Edge {
        switch showDirection {
        case .top:
            return .bottom
        case .leading:
            return .trailing
        case .bottom:
            return .top
        case .trailing:
            return .leading
        }
    }

    var attachmentAnchor: PopoverAttachmentAnchor {
        switch showDirection {
        case .top:
            return PopoverAttachmentAnchor.point(.bottom)
        case .leading:
            return PopoverAttachmentAnchor.point(.trailing)
        case .bottom:
            return PopoverAttachmentAnchor.point(.top)
        case .trailing:
            return PopoverAttachmentAnchor.point(.leading)
        }
    }
}

extension View {
    func customPopover<PopoverContent: View>(
        isPresented: Binding<Bool>,
        showDirection: Edge = .top,
        @ViewBuilder content: @escaping () -> PopoverContent
    ) -> some View {
        self.modifier(CustomPopoverModifier(
            isPresented: isPresented,
            showDirection: showDirection,
            content: content
        ))
    }
}
