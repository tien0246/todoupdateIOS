//
//  AppDetailView.swift
//  todoupdate
//
//  Created by Tiến Đoàn on 11/05/2024.
//

import SwiftUI

enum EditElement {
    case bundleID, version
}

struct AppDetailView: View {
    @Binding var app: AppInfo
    var body: some View {
        Form {
            CustomLabeledContent(label: "Name") {
                Text(app.name)
            }
            CustomLabeledContent(label: "Bundle ID", isButton: true, destination: AnyView(EditAppInfoView(app: $app, editMode: .bundleID))) {
                Text(app.bundleID)
            }
            CustomLabeledContent(label: "Old version", isButton: true, destination: AnyView(EditAppInfoView(app: $app, editMode: .version))) {
                Text(app.oldVersion)
            }
            CustomLabeledContent(label: "Current version") {
                Text(app.currentVersion)
            }
            CustomLabeledContent(label: "Date update") {
                Text(app.dateUpdate, style: .date)
            }
            CustomLabeledContent(label: "Countries", isButton: true, destination: AnyView(CountryView(selectedCountries: $app.countries))) {
                Text(app.countries.joined(separator: ", "))
            }
            CustomLabeledContent(label: "Icon") {
                Image(uiImage: app.getIconImage())
                    .resizable()
                    .frame(width: 64, height: 64)
                    .cornerRadius(12)
            }
        }
        .navigationTitle(app.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    app.updateVersion()
                }) {
                    Text("Update")
                }
            }
        }
    }
}

struct CustomLabeledContent<Content: View>: View {
    let label: String
    let content: Content
    let isButton: Bool
    var destination: AnyView?
    
    init(label: String, isButton: Bool = false, destination: AnyView? = nil, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
        self.isButton = isButton
        self.destination = destination
    }
    
    var body: some View {
        if isButton {
            NavigationLink(destination: destination) {
                HStack() {
                    Text(label)
                    Spacer()
                    content
                        .foregroundColor(.primary)
                }
            }
        } else {
            HStack() {
                Text(label)
                Spacer()
                content
                    .foregroundColor(.primary)
            }
        }
    }
}

struct EditAppInfoView: View {
    @Binding var app: AppInfo
    @State private var bundleID: String
    @State private var version: String
    let editMode: EditElement

    init(app: Binding<AppInfo>, editMode: EditElement) {
        self._app = app
        self._bundleID = State(initialValue: app.wrappedValue.bundleID)
        self._version = State(initialValue: app.wrappedValue.oldVersion)
        self.editMode = editMode
    }

    var body: some View {
        Form {
            if editMode == .bundleID {
                CustomLabeledContent(label: "Bundle ID") {
                    TextField("Bundle ID", text: $bundleID)
                }
            } else if editMode == .version {
                CustomLabeledContent(label: "Version") {
                    TextField("Version", text: $version)
                }
            }
        }
        .navigationTitle("Edit App Info")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    if editMode == .bundleID {
                        self.app.bundleID = bundleID
                    } else if editMode == .version {
                        self.app.oldVersion = version
                    }
                }
            }
        }
    }
}


 #Preview {
     AppDetailView(app: .constant(AppInfo(bundleID: "a", version: "12")))
 }
