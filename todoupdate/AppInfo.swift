//
//  AppInfo.swift
//  todoupdate
//
//  Created by Tiến Đoàn on 11/05/2024.
//

import Foundation
import UIKit

struct AppInfo: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String = ""
    var bundleID: String
    var oldVersion: String
    var currentVersion: String = ""
    var iconBase64: String = ""
    var countries: [String] = []
    var dateUpdate: Date = Date()


    init(bundleID: String, version: String, countries: [String] = []) {
        self.bundleID = bundleID
        self.oldVersion = version
        self.countries = countries.count > 0 ? countries : ["US"]
        let data: String = getDataAppFromServer()
        self.name = getNameFromData(Data: data)
        self.currentVersion = getCurrentVersion(Data: data)
        self.iconBase64 = getIcon(Data: data)
        self.dateUpdate = getDateUpdate(Data: data)
    }

    private func getDataAppFromServer() -> String {
        var result: String = ""
        var version: String = ""
        for country: String in self.countries {
            let urlString: String = "https://itunes.apple.com/lookup?bundleId=\(self.bundleID)&country=\(country)"
            guard let url: URL = URL(string: urlString) else {
                return "Invalid URL"
            }
            print("Fetching data from iTunes API: \(urlString)")
            let data: String = fetchURLContent(url: url)
            let currentVersion: String = getCurrentVersion(Data: data)
            if currentVersion != "Unknown" || compareVersion(version1: version, version2: currentVersion) {
                result = data
                version = currentVersion
            }
        }
        return result
    }

    private func getCurrentVersion(Data: String) -> String {
        let regex: String = "\"version\":\"([^\"]+)\""
        let matches: [String] = self.matches(for: regex, in: Data)
        return matches.first ?? "Unknown"
    }

    private func getIcon(Data: String) -> String {
        let regex: String = "\"artworkUrl100\":\"([^\"]+)\""
        let matches: [String] = self.matches(for: regex, in: Data)
        if let iconURL: URL = URL(string: matches.first ?? "") {
            return fetchURLContent(url: iconURL)
        }
        return ""
    }

    private func getDateUpdate(Data: String) -> Date {
        let regex: String = "\"currentVersionReleaseDate\":\"([^\"]+)\""
        let matches: [String] = self.matches(for: regex, in: Data)
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        return dateFormatter.date(from: matches.first ?? "") ?? Date()
    }

    func getIconImage() -> UIImage {
        if let data: Data = Data(base64Encoded: self.iconBase64, options: .ignoreUnknownCharacters) {
            return UIImage(data: data) ?? UIImage()
        }
        return UIImage()
    }

    private func getNameFromData(Data: String) -> String {
        let regex: String = "\"trackName\":\"([^\"]+)\""
        let matches: [String] = self.matches(for: regex, in: Data)
        return matches.first ?? "Unknown"
    }

    mutating func refresh() {
        let data: String = getDataAppFromServer()
        self.name = getNameFromData(Data: data)
        self.currentVersion = getCurrentVersion(Data: data)
        self.iconBase64 = getIcon(Data: data)
    }
    
    mutating func updateVersion() {
        self.oldVersion = self.currentVersion
    }

    func isNeedUpdate() -> Bool {
        return compareVersion(version1: self.oldVersion, version2: self.currentVersion)
    }

    func compareVersion(version1: String, version2: String) -> Bool {
        let oldVersionSplit: [String] = version1.split(separator: ".").map(String.init)
        let currentVersionSplit: [String] = version2.split(separator: ".").map(String.init)
        let minLength: Int = min(oldVersionSplit.count, currentVersionSplit.count)
        for i: Int in 0..<minLength {
            if let oldVersionPart: Int = Int(oldVersionSplit[i]), let currentVersionPart: Int = Int(currentVersionSplit[i]) {
                if oldVersionPart < currentVersionPart {
                    return true
                } else if oldVersionPart > currentVersionPart {
                    return false
                }
            }
        }
        return oldVersionSplit.count < currentVersionSplit.count
    }

    private func matches(for regex: String, in text: String) -> [String] {
        do {
            let regex: NSRegularExpression = try NSRegularExpression(pattern: regex)
            let results: [NSTextCheckingResult] = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            return results.map {
                if let range: Range<String.Index> = Range($0.range(at: 1), in: text) {
                    return String(text[range])
                }
                return ""
            }.filter { !$0.isEmpty }
        } catch let error {
            print("Invalid regex: \(error.localizedDescription)")
            return []
        }
    }

    private func fetchURLContent(url: URL) -> String {
        var result: String = ""
        let dispatchGroup: DispatchGroup = DispatchGroup()
        dispatchGroup.enter()

        let task: URLSessionDataTask = URLSession.shared.dataTask(with: url) { data, response, error in
            defer { dispatchGroup.leave() }
            
            if let error = error {
                print("Error fetching data from URL: \(error)")
                result = "Error fetching data: \(error.localizedDescription)"
                return
            }

            guard let httpResponse: HTTPURLResponse = response as? HTTPURLResponse,
                (200...299).contains(httpResponse.statusCode),
                let data: Data = data else {
                print("Invalid response from server")
                result = "Invalid response from server"
                return
            }

            if let stringData: String = String(data: data, encoding: .utf8) {
                result = stringData
            } else if let image: UIImage = UIImage(data: data) {
                result = image.pngData()?.base64EncodedString(options: Data.Base64EncodingOptions.lineLength64Characters) ?? ""
            } else {
                print("Failed to decode data")
                result = "Failed to decode data"
            }
        }
        task.resume()
        dispatchGroup.wait()
        return result
    }
}
