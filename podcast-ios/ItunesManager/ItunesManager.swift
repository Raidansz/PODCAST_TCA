//
//  ItunesManager.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 09. 21..
//

import Foundation
import SwiftyJSON
import ComposableArchitecture

class ItunesManager: ItunesManagerProtocol {
    private enum Constants: String {
        case term = "term"
        case country = "country"
        case media = "media"
        case entity = "entity"
        case attribute = "attribute"
        case genreId = "genreId"
        case limit = "limit"
        case lang = "lang"
        case version = "version"
        case explicit = "explicit"
        case apiURL = "https://itunes.apple.com/search"
    }

    private func performQuery(_ url: URL?) async throws -> SearchResults {
        guard let url = url else {
            throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        let (data, _) = try await URLSession.shared.data(from: url)

        let json = try JSON(data: data)
        let resultCount = json["resultCount"].intValue
        let resultsArray = json["results"].arrayValue
        let searchResults = resultsArray.map { SearchResult(json: $0) }
        let searchResultsModel = SearchResults(
            resultCount: resultCount,
            results: IdentifiedArray(uniqueElements: searchResults)
        )

        return searchResultsModel
    }
}

protocol ItunesManagerProtocol {
    // swiftlint:disable:next function_parameter_count
    func searchPodcasts (
        term: String?,
        country: Country?,
        entity: Entity?,
        attribute: String?,
        genreId: PodcastGenre?,
        limit: Int?,
        lang: Language?,
        version: Int?,
        explicit: String?
    ) async throws -> SearchResults

    func searchPodcasts(term: String, entity: Entity) async throws -> SearchResults

    func searchPodcasts(term: String) async throws -> SearchResults
}

// MARK: Search for Podcast / Episode
extension ItunesManager {
    func searchPodcasts(term: String? = nil,
                        country: Country? = nil,
                        entity: Entity? = .podcastAndEpisode,
                        attribute: String? = nil,
                        genreId: PodcastGenre? = nil,
                        limit: Int? = nil,
                        lang: Language? = nil,
                        version: Int? = 2,
                        explicit: String? = nil
    ) async throws -> SearchResults {

        var queryItems = [URLQueryItem]()

        if let term = term?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            queryItems.append(URLQueryItem(name: "term", value: term))
        }

        if let country = country {
            queryItems.append(URLQueryItem(name: Constants.country.rawValue, value: country.rawValue))
        }

        queryItems.append(URLQueryItem(name: Constants.media.rawValue, value: "podcast"))

        if let entity = entity {
            queryItems.append(URLQueryItem(name: Constants.entity.rawValue, value: entity.rawValue))
        }

        if let attribute = attribute {
            queryItems.append(URLQueryItem(name: Constants.attribute.rawValue, value: attribute))
        }

        if let genreId = genreId {
            queryItems.append(URLQueryItem(name: Constants.genreId.rawValue, value: genreId.rawValue))
        }

        if let limit = limit {
            queryItems.append(URLQueryItem(name: Constants.limit.rawValue, value: String(limit)))
        }

        if let lang = lang {
            queryItems.append(URLQueryItem(name: Constants.lang.rawValue, value: lang.rawValue))
        }

        if let version = version {
            queryItems.append(URLQueryItem(name: Constants.version.rawValue, value: String(version)))
        }

        if let explicit = explicit {
            queryItems.append(URLQueryItem(name: Constants.explicit.rawValue, value: explicit))
        }

        var urlComponents = URLComponents(string: Constants.apiURL.rawValue)
        urlComponents?.queryItems = queryItems

        return try await performQuery(urlComponents?.url)
    }

    func searchPodcasts(term: String) async throws -> SearchResults {
        var queryItems = [URLQueryItem]()

        if let term = term.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            queryItems.append(URLQueryItem(name: "term", value: term))
        }

        queryItems.append(URLQueryItem(name: Constants.entity.rawValue, value: "podcast,podcastEpisode"))

        queryItems.append(URLQueryItem(name: Constants.media.rawValue, value: "podcast"))

        var urlComponents = URLComponents(string: Constants.apiURL.rawValue)
        urlComponents?.queryItems = queryItems

        return try await performQuery(urlComponents?.url)
    }

    func searchPodcasts(term: String, entity: Entity) async throws -> SearchResults {
        var queryItems = [URLQueryItem]()

        if let term = term.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            queryItems.append(URLQueryItem(name: "term", value: term))
        }

        queryItems.append(URLQueryItem(name: Constants.entity.rawValue, value: entity.rawValue))

        queryItems.append(URLQueryItem(name: Constants.media.rawValue, value: "podcast"))

        var urlComponents = URLComponents(string: Constants.apiURL.rawValue)
        urlComponents?.queryItems = queryItems

        return try await performQuery(urlComponents?.url)
    }
}

private struct ItunesManagerKey: InjectionKey {
    static var currentValue: ItunesManagerProtocol = ItunesManager()
}

extension InjectedValues {
    var itunesManager: ItunesManagerProtocol {
        get { Self[ItunesManagerKey.self]}
        set { Self[ItunesManagerKey.self] = newValue }
    }
}
