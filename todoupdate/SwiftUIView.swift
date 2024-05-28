//
//  SwiftUIView.swift
//  todoupdate
//
//  Created by Tiến Đoàn on 18/05/2024.
//

import SwiftUI

struct ApppRow: View {
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
            .background(Color(colorScheme == .dark ? .secondarySystemBackground : .systemBackground))
            .foregroundColor(.primary)
        }
    }
}


#Preview {
    ApppRow(app: .constant(AppInfo(bundleID: "com.smilegate.outerplane.stove.ios", version: "1")))
}

