//
//  PodHubManager.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 09. 28..
//

import Foundation
import IdentifiedCollections

class PodHubManager: PodHubManagerProtocol {
    @Injected(\.itunesManager) private var itunesManager: ItunesManagerProtocol
    @Injected(\.podcastIndexManager) private var podcastIndexManager: PodcastIndexManagerProtocol
    private var activeSearchResult: Dictionary<UUID, PaginatedResult> = [:]

    func getTrendingPodcasts() async throws -> PodHub {
        let result = try await podcastIndexManager.performQuery(for: .podcast, .trending, parameter: .lang("en"))
        return try normalizeResult(result: result, mediaType: .podcast, totalCount: result.count)
    }

    func searchFor(
        searchFor mediaType: MediaType,
        value: String,
        limit: Int? = nil,
        page: Int? = nil,
        id: UUID? = nil
    ) async throws -> PodHub {
        if let id, let result = activeSearchResult[id] {
            // TODO: for now I will not remove it
            // activeSearchResult.removeValue(forKey: id)
            return result.podHub
        }
        /// var to hold the final result
        var finalResult: PodHub
        /// we default the search with the itunes API
        let result =  try await lookupItunes(searchFor: mediaType, value: value, limit: limit, page: page)
        /// if the result is empty, then we search with the PocastIndex API
        if result.results.isEmpty {
            let result = try await lookupPodcastIndex(searchFor: mediaType, value: value)
            finalResult = try normalizeResult(result: result, mediaType: mediaType, totalCount: result.count)
        }
        finalResult = try normalizeResult(result: result, mediaType: mediaType, totalCount: result.resultCount)

        if let id = id {
            activeSearchResult[id] = PaginatedResult(podHub: finalResult, currentIndex: 0)
        }
        finalResult.podcasts = IdentifiedArray(uniqueElements: Array(finalResult.podcasts.prefix(limit ?? 5)))
        return finalResult
    }

    func loadMoreForSearchResult(withID: UUID, with limit: Int = 5) async throws -> PodHub {
        if var paginatedResult = activeSearchResult[withID] {
            let totalPodcasts = paginatedResult.podHub.podcasts.count
            let currentIndex = paginatedResult.currentIndex

            let nextIndex = min(currentIndex + limit, totalPodcasts)
            let podcastsToReturn = Array(paginatedResult.podHub.podcasts[0..<nextIndex])

            paginatedResult.currentIndex = nextIndex
            activeSearchResult[withID] = paginatedResult

            return PodHub(podcasts: IdentifiedArray(uniqueElements: podcastsToReturn), count: podcastsToReturn.count)
        } else {
            throw NSError(domain: "SearchResultError", code: 2, userInfo: [NSLocalizedDescriptionKey: "No search result found for the given ID."])
        }
    }

    private func lookupItunes(
        searchFor: MediaType,
        value: String,
        limit: Int? = nil,
        page: Int? = nil
    ) async throws -> SearchResults {
        let searchResult: SearchResults
        let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if searchFor == .podcast {
            searchResult = try await itunesManager.searchPodcasts(
                term: encodedValue,
                entity: .podcast,
                limit: limit,
                page: page
            )
        } else if searchFor == .episode {
            searchResult = try await itunesManager.searchPodcasts(
                term: encodedValue,
                entity: .podcastEpisode,
                limit: limit,
                page: page
            )
        } else {
            searchResult = try await itunesManager.searchPodcasts(
                term: encodedValue,
                entity: .podcastAndEpisode,
                limit: limit,
                page: page
            )
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

    private func normalizeResult(result: PodHubConvertable, mediaType: MediaType, totalCount: Int ) throws -> PodHub {
        return try PodHub(result: result, mediaType: mediaType, totalCount: totalCount)
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
    func searchFor(searchFor: MediaType, value: String, limit: Int?, page: Int?, id: UUID?) async throws -> PodHub
    func loadMoreForSearchResult(withID ID: UUID, with limit: Int) async throws -> PodHub
    func getTrendingPodcasts() async throws -> PodHub
}

enum MediaType {
    case podcast
    case episode
}

struct PaginatedResult {
    var podHub: PodHub
    var currentIndex: Int
}
