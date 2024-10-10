//
//  PodHubManager.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 09. 28..
//

import Foundation

class PodHubManager: PodHubManagerProtocol {
    @Injected(\.itunesManager) private var itunesManager: ItunesManagerProtocol
    @Injected(\.podcastIndexManager) private var podcastIndexManager: PodcastIndexManagerProtocol

    func searchFor(searchFor mediaType: MediaType, value: String, limit: Int? = nil, page: Int? = nil) async throws -> PodHub {
        let result =  try await lookupItunes(searchFor: mediaType, value: value, limit: limit, page: page)
        if result.results.isEmpty {
            let result = try await lookupPodcastIndex(searchFor: mediaType, value: value)
            return try normalizeResult(result: result, mediaType: mediaType)
        }
        return try normalizeResult(result: result, mediaType: mediaType)
    }

    private func lookupItunes(searchFor: MediaType, value: String, limit: Int? = nil, page: Int? = nil) async throws -> SearchResults {
        let searchResult: SearchResults
        let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if searchFor == .podcast {
            searchResult = try await itunesManager.searchPodcasts(term: encodedValue, entity: .podcast, limit: limit, page: page)
        } else if searchFor == .episode {
            searchResult = try await itunesManager.searchPodcasts(term: encodedValue, entity: .podcastEpisode, limit: limit, page: page)
        } else {
            searchResult = try await itunesManager.searchPodcasts(term: encodedValue, entity: .podcastAndEpisode, limit: limit, page: page)
        }
        return searchResult
    }

    private func lookupPodcastIndex(searchFor: MediaType, value: String) async throws -> PodcastIndexResponse {
        let encodedValue = value.replacingOccurrences(of: " ", with: "+")
        if searchFor == .podcast {
            return   try await podcastIndexManager.performQuery(for: .podcast, .title(encodedValue), parameter: nil)
        } else {
            return  try await podcastIndexManager.performQuery(for: .episode, .title(encodedValue), parameter: nil)
        }
    }

    private func normalizeResult(result: PodHubConvertable, mediaType: MediaType ) throws -> PodHub {
        return try PodHub(result: result, mediaType: mediaType)
    }

    enum FilterBy {
        case type
        case lanugage
    }

    enum SearchBy {
        case name
        case author
    }
}

private struct PodHubManagerKey: InjectionKey {
    static var currentValue: PodHubManagerProtocol = PodHubManager()
}

extension InjectedValues {
    var podHubManager: PodHubManagerProtocol {
        get { Self[PodHubManagerKey.self]}
        set { Self[PodHubManagerKey.self] = newValue }
    }
}

protocol PodHubManagerProtocol {
    func searchFor(searchFor: MediaType, value: String, limit: Int?, page: Int?) async throws -> PodHub
}

enum MediaType {
    case podcast
    case episode
}
