//
//  AddView.swift
//  todoupdate
//
//  Created by Tiến Đoàn on 11/05/2024.
//

import SwiftUI

struct AddView: View {
    @ObservedObject var model: ViewModel
    var completion: (() -> Void)?

    @State private var bundleID: String = ""
    @State private var version: String = ""
    @State private var countries: [String] = []

    var body: some View {
        NavigationView {
            Form {
                Section (header: Text("App Info"), footer: Text("The default value of country is US")) {
                    TextField("Bundle ID", text: $bundleID)
                    TextField("Version", text: $version)
                    NavigationLink(destination: CountryView(selectedCountries: $countries)) {
                        HStack {
                            Text("Countries")
                            Spacer()
                            Text(countries.joined(separator:", "))
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    }
                }
            }
            .navigationTitle("Add app")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        completion?()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if !bundleID.isEmpty && !version.isEmpty {
                            model.addApp(app: AppInfo(bundleID: bundleID, version: version, countries: countries))
                        }
                        completion?()
                    }
                }
            }
        }
    }
}

#Preview {
    AddView(model: ViewModel())
}
