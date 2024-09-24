//
//  PodcastIndexManager.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 09. 22..
//

import Foundation
import CryptoKit
import SwiftyJSON

final class PodcastIndexManager: PodcastIndexManagerProtocol {
    func getTrending() async throws -> PodcastIndexResponse {
        return try await performQuery("search/byperson?q=jack")
    }

    private func performQuery(_ query: String) async throws -> PodcastIndexResponse {
        // Prepare URL and request
        guard let url = URL(string: "https://api.podcastindex.org/api/1.0/\(query)") else {
            throw NSError(domain: "Invalid URL", code: 0, userInfo: nil)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        try setAuthorizationHeaders(for: &request)

        // Perform the request
        let (data, response) = try await URLSession.shared.data(for: request)

        // Validate the response
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response from server"])
        }

        // Parse the JSON response
        let json = try JSON(data: data)
        return PodcastIndexResponse(json: json)
    }

    private func setAuthorizationHeaders(for request: inout URLRequest) throws {
        guard let keys = loadApiKeys() else {
            throw NSError(domain: "API keys missing", code: 0, userInfo: nil)
        }

        let apiHeaderTime = Int(Date().timeIntervalSince1970)
        let data4Hash = keys.apiKey + keys.apiSecret + "\(apiHeaderTime)"
        let hashString = Insecure.SHA1.hash(data: Data(data4Hash.utf8))
            .map { String(format: "%02x", $0) }
            .joined()

        request.addValue("\(apiHeaderTime)", forHTTPHeaderField: "X-Auth-Date")
        request.addValue(keys.apiKey, forHTTPHeaderField: "X-Auth-Key")
        request.addValue(hashString, forHTTPHeaderField: "Authorization")
        request.addValue("SuperPodcastPlayer/1.8", forHTTPHeaderField: "User-Agent")
    }
}

private extension PodcastIndexManager {
    // Function to load API keys from PodcastIndexKeys.plist
    func loadApiKeys() -> (apiKey: String, apiSecret: String)? {
        guard let path = Bundle.main.path(forResource: "PodcastIndexKey", ofType: "pl"),
              let xml = FileManager.default.contents(atPath: path) else {
            print("Error: PodcastIndexKey.plist not found.")
            return nil
        }

        do {
            let plistData = try PropertyListSerialization.propertyList(from: xml, options: [], format: nil)
            if let plistDict = plistData as? [String: Any],
               let apiKey = plistDict["ApiKey"] as? String,
               let apiSecret = plistDict["ApiSecret"] as? String {
                return (apiKey, apiSecret)
            } else {
                print("Error: PodcastIndexKeys.plist is not in the expected format.")
                return nil
            }
        } catch {
            print("Error: Unable to read PodcastIndexKeys.plist: \(error)")
            return nil
        }
    }
}
protocol PodcastIndexManagerProtocol {
    func getTrending() async throws -> PodcastIndexResponse
}

private struct PodcastIndexManagerKey: InjectionKey {
    static var currentValue: PodcastIndexManagerProtocol = PodcastIndexManager()
}

extension InjectedValues {
    var podcastIndexManager: PodcastIndexManagerProtocol {
        get { Self[PodcastIndexManagerKey.self]}
        set { Self[PodcastIndexManagerKey.self] = newValue }
    }
}
