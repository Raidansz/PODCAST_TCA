//
//  PodHubManager.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 09. 28..
//

import Foundation
import IdentifiedCollections

final class PodHubManager: PodHubManagerProtocol {
    @Injected(\.itunesManager) private var itunesManager: ItunesManagerProtocol
    @Injected(\.podcastIndexManager) private var podcastIndexManager: PodcastIndexManagerProtocol
    @Injected(\.rssFeedGeneratorManager) private var rSSFeedGeneratorManager: RSSFeedGeneratorManagerProtocol

    deinit {
        PODLogInfo("PodHubManager was deinitialized")
    }

    func getTrendingPodcasts() async throws -> PodHub {
        let fetchedIds = try await rSSFeedGeneratorManager.getTopChartedPodcast(limit: 50, country: .unitedStates)
        let result = try await itunesManager.lookupPodcasts(ids: fetchedIds)
        return try normalizeResult(result: result, mediaType: .podcast, totalCount: result.resultCount)
    }

    func searchFor(
        searchFor mediaType: MediaType,
        value: String,
        limit: Int? = nil,
        page: Int? = nil,
        id: UUID? = nil
    ) async throws -> PodHub {
        var finalResult: PodHub
        let result =  try await lookupItunes(searchFor: mediaType, value: value, limit: limit, page: page)
        if result.results.isEmpty {
            let result = try await lookupPodcastIndex(searchFor: mediaType, value: value)
            finalResult = try normalizeResult(result: result, mediaType: mediaType, totalCount: result.count)
        }
        finalResult = try normalizeResult(result: result, mediaType: mediaType, totalCount: result.resultCount)
        return finalResult
    }

    private func lookupItunes(
        searchFor: MediaType,
        value: String,
        limit: Int? = nil,
        page: Int? = nil
    ) async throws -> SearchResults {
        let searchResult: SearchResults
        let encodedValuee = value.replacingOccurrences(of: " ", with: "+")
        
        guard let encodedValue = encodedValuee.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)?
                .replacingOccurrences(of: "%20", with: "+") else {
            PODLogError("\(URLError(.badURL))")
            throw URLError(.badURL)
        }
        
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
        let encodedValuee = value.replacingOccurrences(of: " ", with: "+")

        guard let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)?
                .replacingOccurrences(of: "%20", with: "+") else {
            PODLogError("\(URLError(.badURL))")
            throw URLError(.badURL)
        }

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
