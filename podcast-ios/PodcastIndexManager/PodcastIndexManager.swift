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
        parameter: QueryParameter?
    )
    async throws -> PodcastIndexResponse {
        let url = try constructURL(type: type, getBy: query, with: parameter ?? .max(5))
        var request = URLRequest(url: url)
        print(url)
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

    private func constructURL( type: PodcastOrEpisode, getBy query: QueryType, with parameter: QueryParameter?) throws -> URL {
        let path = "\(type.rawValue)/\(query.query)\(parameter!.parameter)"
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

enum QueryType {
    case feedID(Int)
    case feedURL(String)
    case itunesID(Int)
    case guid(String)
    case title(String)
    case medium(String)
    /// only for podcast types.
    case trending
    /// only for episode types.
    case random

    var query: String {
        switch self {
        case .feedID(let id):
            return "byfeedid?id=\(id)"
        case .feedURL(let url):
            return "byfeedurl?url=\(url)"
        case .itunesID(let id):
            return "byitunesid?id=\(id)"
        case .guid(let guid):
            return "byguid?guid=\(guid)"
        case .title(let title):
            return "bytitle?title=\(title)"
        case .medium(let medium):
            return "bymedium?medium=\(medium)"
        case .trending:
            return "trending"
        case .random:
            return "random"
        }
    }
}


enum QueryParameter {
    ///Maximum number of results to return.
    case max(Int)
    ///Specifying a language code (like "en") will return only episodes having that specific language.
   /// You can specify multiple languages by separating them with commas.
   /// If you also want to return episodes that have no language given, use the token "unknown". (ex. en,es,ja,unknown).
    case lang(String)
    ///Use this argument to specify that you ONLY want episodes with these categories in the results.
    ///Separate multiple categories with commas.
   /// You may specify either the Category ID and/or the Category Name.
   /// Values are not case sensitive.
    case cat(String)

    var parameter: String {
        switch self {
        case .max(let max):
            return "?max=\(max)"
        case .lang(let lang):
            return "?lang=\(lang)"
        case .cat(let cat):
            return "?cat=\(cat)"
        }
    }
}


enum PodcastOrEpisode: String {
    case podcast = "podcasts"
    case episode = "episodes"
}

protocol PodcastIndexManagerProtocol {
    func performQuery(
        for type: PodcastOrEpisode,
        _ query: QueryType,
        parameter: QueryParameter?
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
