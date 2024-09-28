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
    func performQuery(
        for type: PodcastOrEpisode,
        _ query: QueryType,
        termValue: String?
    )
    async throws -> PodcastIndexResponse {
        let url = try constructURL(type: type, getBy: query, termValue: termValue)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        try setAuthorizationHeaders(for: &request)

        let (data, response) = try await URLSession.shared.data(for: request)

        try validateResponse(response)
        return try parseResponseData(data)
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

    private func setAuthorizationHeaders(for request: inout URLRequest) throws {
        guard let keys = loadApiKeys() else {
            throw PodcastIndexError.missingAPIKeys
        }

        let apiHeaderTime = Int(Date().timeIntervalSince1970)
        let dataToHash = keys.apiKey + keys.apiSecret + "\(apiHeaderTime)"
        let hashString = Insecure.SHA1.hash(data: Data(dataToHash.utf8))
            .map { String(format: "%02x", $0) }
            .joined()

        request.addValue("\(apiHeaderTime)", forHTTPHeaderField: "X-Auth-Date")
        request.addValue(keys.apiKey, forHTTPHeaderField: "X-Auth-Key")
        request.addValue(hashString, forHTTPHeaderField: "Authorization")
        request.addValue("SuperPodcastPlayer/1.8", forHTTPHeaderField: "User-Agent")
    }

    private func constructURL( type: PodcastOrEpisode, getBy query: QueryType, termValue: String?) throws -> URL {
        let path = "\(type.rawValue)/\(query.rawValue)\(termValue ?? "")"
        guard let url = URL(string: "https://api.podcastindex.org/api/1.0/\(path)") else {
            throw PodcastIndexError.invalidURL
        }
        return url
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw PodcastIndexError.invalidResponse
        }
    }

    private func parseResponseData(_ data: Data) throws -> PodcastIndexResponse {
        do {
            let json = try JSON(data: data)
            return PodcastIndexResponse(json: json)
        } catch {
            throw PodcastIndexError.invalidData
        }
    }

    // MARK: - Custom Errors
    enum PodcastIndexError: Error, LocalizedError {
        case invalidURL
        case invalidResponse
        case invalidData
        case missingAPIKeys

        var errorDescription: String? {
            switch self {
            case .invalidURL: return "Failed to construct the URL for the API request."
            case .invalidResponse: return "Received an invalid response from the server."
            case .invalidData: return "Failed to parse the data from the server."
            case .missingAPIKeys: return "API keys are missing or invalid."
            }
        }
    }
}

enum QueryType: String {
    case feedID = "byfeedid?id="
    case feedURL = "byfeedurl?url="
    case itunesID = "byitunesid?id="
    case guid = "byguid?guid="
    case title = "bytitle?title="
    case medium = "bymedium?medium="
    case trending = "trending" // only for podcast types
    case random = "random" // only for episode types
}

enum PodcastOrEpisode: String {
    case podcast = "podcasts"
    case episode = "episodes"
}

protocol PodcastIndexManagerProtocol {
    func performQuery(
        for type: PodcastOrEpisode,
        _ query: QueryType,
        termValue: String?
    ) async throws -> PodcastIndexResponse
}

// TODO: Check if this is the right thing
private struct PodcastIndexManagerKey: @preconcurrency InjectionKey {
    @MainActor static var currentValue: PodcastIndexManagerProtocol = PodcastIndexManager()
}

extension InjectedValues {
    var podcastIndexManager: PodcastIndexManagerProtocol {
        get { Self[PodcastIndexManagerKey.self]}
        set { Self[PodcastIndexManagerKey.self] = newValue }
    }
}
