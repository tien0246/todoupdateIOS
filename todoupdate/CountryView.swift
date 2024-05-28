//
//  CountryView.swift
//  todoupdate
//
//  Created by Tiến Đoàn on 20/05/2024.
//

import SwiftUI

import SwiftUI

struct CountryView: View {
    @Binding var selectedCountries: [String]
    
    @State private var allCountries: [Country] = Bundle.main.decode("itunes_country_codes.json").map { Country(code: $0.key, name: $0.value) }
    @State private var selectedCountriesTemp: [String] = []
    @State private var searchText: String = ""
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    init(selectedCountries: Binding<[String]>) {
        self._selectedCountries = selectedCountries
        self._selectedCountriesTemp = State(initialValue: selectedCountries.wrappedValue)
    }

    var body: some View {
        VStack {
            TextField("Search...", text: $searchText)
                .padding(.vertical, 6)
                .padding(.horizontal, 35.0)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .overlay(
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .padding(.leading, 8)
                        Spacer()
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.primary)
                                    .padding(.trailing, 8)
                            }
                        }
                    }
                )
                .padding(.horizontal, 20)
            
            List(allCountries.filter({ searchText.isEmpty ? true : $0.name.lowercased().contains(searchText.lowercased()) || $0.code.lowercased().contains(searchText.lowercased()) }), id: \.code) { country in
                HStack {
                    Text(country.name)
                    Spacer()
                    if selectedCountriesTemp.contains(country.code) {
                        Image(systemName: "checkmark").foregroundColor(.blue)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if let index = selectedCountriesTemp.firstIndex(of: country.code) {
                        selectedCountriesTemp.remove(at: index)
                    } else {
                        selectedCountriesTemp.append(country.code)
                    }
                }
            }
            .onAppear {
                allCountries = allCountries.sorted { a, b in
                    let isSelectedA = selectedCountriesTemp.contains(a.code)
                    let isSelectedB = selectedCountriesTemp.contains(b.code)
                    if isSelectedA == isSelectedB {
                        return a.name < b.name
                    }
                    return isSelectedA
                }
            }
        }
        .padding(.top)
        .navigationTitle("Select countries")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    selectedCountries = selectedCountriesTemp
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Save")
                }
            }
        }
    }
}

#Preview {
    CountryView(selectedCountries: .constant(["United States", "Russia", "India"]))
}
