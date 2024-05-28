//
//  ViewModel.swift
//  todoupdate
//
//  Created by Tiến Đoàn on 11/05/2024.
//

import Foundation
import Combine

class ViewModel: ObservableObject {
    @Published var listApp: [AppInfo]
    
    private let savePath: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("listApp.json")
    private var saveCancellable: AnyCancellable?

    init() {
        do {
            let data: Data = try Data(contentsOf: savePath)
            listApp = try JSONDecoder().decode([AppInfo].self, from: data)
            listApp.sort { $0.dateUpdate < $1.dateUpdate }
        } catch {
            listApp = []
        }

        saveCancellable = $listApp
            .debounce(for: 0, scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.save()
            }
    }

    func addApp(app: AppInfo) {
        listApp.append(app)
        listApp.sort { $0.dateUpdate < $1.dateUpdate }
    }

//    func removeApp(_ index: IndexSet) {
//        listApp.remove(atOffsets: index)
//    }

    func removeApp(app: AppInfo) {
        if let index = listApp.firstIndex(of: app) {
            listApp.remove(at: index)
        }
    }

//    func moveApp(from source: IndexSet, to destination: Int) {
//        listApp.move(fromOffsets: source, toOffset: destination)
//    }

//    func updateApp(app: AppInfo, at index: Int) {
//        listApp[index] = app
//    }

    func refreshApp(completion: @escaping ([AppInfo]) -> Void) {
        var updatedApps = [AppInfo]()
        let dispatchGroup: DispatchGroup = DispatchGroup()
        
        for index in listApp.indices {
            dispatchGroup.enter()
            DispatchQueue.global(qos: .userInitiated).async {
                var refreshedApp = self.listApp[index]
                refreshedApp.refresh()
                if refreshedApp.isNeedUpdate() {
                    updatedApps.append(refreshedApp)
                }
                DispatchQueue.main.async {
                    self.listApp[index] = refreshedApp
                    dispatchGroup.leave()
                }
            }
        }

        dispatchGroup.notify(queue: .main) {
            self.listApp.sort { $0.dateUpdate < $1.dateUpdate }
            print("done refresh")
            completion(updatedApps)
        }
    }

    func save() {
        let encoder: JSONEncoder = JSONEncoder()
        if let encoded = try? encoder.encode(listApp) {
            try? encoded.write(to: savePath, options: .atomic)
        }
        NSLog("%@", "Save data to \(savePath.absoluteString)")
        print("Count \(listApp.count)")
    }
    
    func importFromFile(url: URL, completion: (() -> Void)? = nil) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            let contents: String = try String(contentsOf: url)
            let lines: [String] = contents.components(separatedBy: .newlines)
            
            for line: String in lines {
                let components: [String] = line.split(separator: "|").map(String.init)
                if components.count == 3 {
                    let bundleID: String = components[0]
                    let version: String = components[1]
                    let countries: [String] = components[2].split(separator: ",").map(String.init)
                    
                    DispatchQueue.main.async {
                        self.addApp(app: AppInfo(bundleID: bundleID, version: version, countries: countries))
                    }
                }
            }
            
            DispatchQueue.main.async {
                completion?()
            }
        } catch {
            print("Unable to read the file: \(error.localizedDescription)")
            DispatchQueue.main.async {
                completion?()
            }
        }
    }
    
    func exportToFile() {
        let fileManager = FileManager.default
        guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let exportDirPath = documentsPath.appendingPathComponent("export")

        if !fileManager.fileExists(atPath: exportDirPath.path) {
            do {
                try fileManager.createDirectory(at: exportDirPath, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error export: \(error)")
                return
            }
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        let fileName = "\(dateFormatter.string(from: Date())).txt"
        let filePath = exportDirPath.appendingPathComponent(fileName)

        let content = listApp.map { "\($0.bundleID)|\($0.oldVersion)|\($0.countries.joined(separator: ","))" }.joined(separator: "\n")
        do {
            try content.write(to: filePath, atomically: true, encoding: .utf8)
            print("Done: \(filePath)")
        } catch {
            print("Error: \(error)")
        }
    }

}
