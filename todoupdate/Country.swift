//
//  Country.swift
//  todoupdate
//
//  Created by Tiến Đoàn on 20/05/2024.
//

import Foundation

struct Country: Codable, Hashable {
    var code: String
    var name: String
}

extension Bundle {
    func decode(_ file: String) -> [String: String] {
        guard let url: URL = self.url(forResource: file, withExtension: nil) else {
            fatalError("Failed to locate \(file) in bundle.")
        }
        
        guard let data: Data = try? Data(contentsOf: url) else {
            fatalError("Failed to load \(file) from bundle.")
        }
        
        let decoder: JSONDecoder = JSONDecoder()
        
        guard let loaded: [String : String] = try? decoder.decode([String: String].self, from: data) else {
            fatalError("Failed to decode \(file) from bundle.")
        }
        
        return loaded
    }
}
