//
//  updateView.swift
//  To do update
//
//  Created by Tiến Đoàn on 28/05/2024.
//

import SwiftUI

enum ActiveSheet: Identifiable {
    case addView
    case filePicker
    var id: Int {
        switch self {
        case .addView:
            return 0
        case .filePicker:
            return 1
        }
    }
}

enum ActiveAlert: Identifiable {
    case noAppNeedUpdate
    case exportFile
    var id: Int {
        switch self {
        case .noAppNeedUpdate:
            return 0
        case .exportFile:
            return 1
        }
    }
}

struct UpdateView: View {
    @ObservedObject var viewModel: ViewModel
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    @State private var activeSheet: ActiveSheet?
    @State private var activeAlert: ActiveAlert?
    @State private var isRefreshing: Bool = true
    @State private var isShowAction: Bool = false

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                ForEach($viewModel.listApp, id: \.id) { app in
                    if app.wrappedValue.isNeedUpdate() || app.wrappedValue.currentVersion == "Unknown" {
                        HStack(spacing: 0) {
                            AppRow(app: app)
                                .contextMenu {
                                Button(action: {
                                    app.wrappedValue.updateVersion()
                                }) {
                                    Label("Update", systemImage: "checkmark")
                                }
                                Button(action: {
                                    viewModel.removeApp(app: app.wrappedValue)
                                }) {
                                    Label("Delete", systemImage: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                                .frame(maxWidth: isShowAction ? .infinity : .none, alignment: .leading)
                                .animation(.default, value: isShowAction)

                            if isShowAction {
                                ZStack {
                                    Color(colorScheme == .dark ? .secondarySystemBackground : .systemBackground)
                                    VStack(alignment: .leading) {
                                        Button(action: {
                                            withAnimation {
                                                app.wrappedValue.updateVersion()
                                            }
                                        }) {
                                            Image(systemName: "checkmark")
                                                .frame(minWidth: 70, maxHeight: 35)
                                                .foregroundColor(.white)
                                                .background(Color.green)
                                                .cornerRadius(12)
                                        }

                                        Button(action: {
                                            withAnimation {
                                                viewModel.removeApp(app: app.wrappedValue)
                                            }
                                        }) {
                                            Image(systemName: "trash")
                                                .frame(minWidth: 70, maxHeight: 35)
                                                .foregroundColor(.white)
                                                .background(Color.red)
                                                .cornerRadius(12)
                                        }
                                    }
                                }
                                    .frame(maxWidth: 80, maxHeight: .infinity)
                                    .transition(.move(edge: .trailing))
                            }
                        }
                            .animation(.default, value: isShowAction)
                    }
                }
            }
                .cornerRadius(12)
                .padding()
        }
            .onAppear() {
                checkForUpdates()
                isRefreshing = false
            }
            .navigationTitle("To Do Update")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
            ToolbarItemGroup(placement: .topBarLeading) {
                Menu {
                    Button(action: {
                        activeSheet = .filePicker
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("Import")
                        }
                    }
                    Button(action: {
                        activeAlert = .exportFile
                        viewModel.exportToFile()
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Export")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }

                Button(action: {
                    isShowAction.toggle()
                }) {
                    Image(systemName: "pencil")
                }
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button(action: {
                    isRefreshing = true
                    viewModel.refreshApp { updatedApps in
                        isRefreshing = false
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                }
                    .disabled(viewModel.listApp.isEmpty)

                Button(action: {
                    activeSheet = .addView
                }) {
                    Image(systemName: "plus")
                }
            }
        }
            .alert(item: $activeAlert) { item in
            switch item {
            case .noAppNeedUpdate:
                Alert(title: Text("No app need update"), message: Text("All apps are up to date"), dismissButton: .default(Text("OK")))
            case .exportFile:
                Alert(title: Text("Export file"), message: Text("Export file successfully"), dismissButton: .default(Text("OK")))
            }
        }
            .sheet(item: $activeSheet, onDismiss: {
            activeSheet = nil
        }) { item in
            switch item {
            case .addView:
                AddView(model: viewModel) {
                    activeSheet = nil
                }
            case .filePicker:
                DocumentPicker() { url in
                    isRefreshing = true
                    viewModel.importFromFile(url: url) {
                        isRefreshing = false
                        activeSheet = nil
                    }
                }
            }
        }
            .overlay(
            isRefreshing ? LoadingView() : nil
        )
    }

    private func checkForUpdates() {
        if viewModel.listApp.allSatisfy({ !$0.isNeedUpdate() && $0.currentVersion != "Unknown" }) && viewModel.listApp.count > 0 {
            activeAlert = .noAppNeedUpdate
        }
    }
}

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)

            ProgressView()
                .scaleEffect(1.5, anchor: .center)
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
        }
    }
}

struct AppRow: View {
    @Binding var app: AppInfo

    @Environment(\.colorScheme) var colorScheme: ColorScheme
    var body: some View {
        NavigationLink(destination: AppDetailView(app: $app)) {
            HStack {
                Image(uiImage: app.getIconImage())
                    .resizable()
                    .frame(width: 64, height: 64)
                    .cornerRadius(12)
                VStack(alignment: .leading) {
                    Text(app.name)
                    Text("Bundle ID: \(app.bundleID)")
                    Text("New version: \(app.currentVersion)")
                }
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground))
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    UpdateView(viewModel: ViewModel())
}
