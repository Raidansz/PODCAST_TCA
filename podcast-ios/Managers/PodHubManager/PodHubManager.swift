//
//  PodHubManager.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 09. 28..
//

import Foundation
import IdentifiedCollections
import Cache

final class PodHubManager: PodHubManagerProtocol {
    @Injected(\.itunesManager) private var itunesManager: ItunesManagerProtocol
    @Injected(\.podcastIndexManager) private var podcastIndexManager: PodcastIndexManagerProtocol
    @Injected(\.rssFeedGeneratorManager) private var rSSFeedGeneratorManager: RSSFeedGeneratorManagerProtocol
    private let trendingPodcastsCacheKey = "trending_podcasts"
    private let searchResultsCacheKeyPrefix = "search_results_"

    private let diskConfig = DiskConfig(
        name: "PodHubCache",
        expiry: .date(Date().addingTimeInterval(10 * 3600))
    )
    private let memoryConfig = MemoryConfig(
        expiry: .date(Date().addingTimeInterval(30 * 60)), // 30 minutes in memory
        countLimit: 10
    )

    private var trendingPodcastsStorage: Storage<String, PodHub>?
    private var searchResultsStorage: Storage<String, PodHub>?

    init() {
        do {
            trendingPodcastsStorage = try Storage(
                diskConfig: diskConfig,
                memoryConfig: memoryConfig,
                fileManager: .default,
                transformer: TransformerFactory.forCodable(ofType: PodHub.self)
            )
            searchResultsStorage = try Storage(
                diskConfig: diskConfig,
                memoryConfig: memoryConfig,
                fileManager: .default,
                transformer: TransformerFactory.forCodable(ofType: PodHub.self)
            )
        } catch {
            PODLogError("Failed to initialize storage: \(error)")
            trendingPodcastsStorage = nil
            searchResultsStorage = nil
        }
    }
    deinit {
        PODLogInfo("PodHubManager was deinitialized")
    }

    func getTrendingPodcasts() async throws -> PodHub {
        if let cachedPodcasts = try? await trendingPodcastsStorage?.async.object(forKey: trendingPodcastsCacheKey) {
            PODLogInfo("Fetched trending podcasts from cache")
            return cachedPodcasts
        }

        let fetchedIds = try await rSSFeedGeneratorManager.getTopChartedPodcast(limit: 50, country: .unitedStates)
        let result = try await itunesManager.lookupPodcasts(ids: fetchedIds)
        let normalizedResult = try normalizeResult(result: result, mediaType: .podcast, totalCount: result.resultCount)

        trendingPodcastsStorage?.async.setObject(normalizedResult, forKey: trendingPodcastsCacheKey) { result in
            if case .failure(let error) = result {
                PODLogError("Failed to cache trending podcasts: \(error)")
            }
        }

        return normalizedResult
    }

    func searchFor(
        searchFor mediaType: MediaType,
        value: String,
        limit: Int? = nil,
        page: Int? = nil,
        id: UUID? = nil
    ) async throws -> PodHub {
        let cacheKey = "\(searchResultsCacheKeyPrefix)\(mediaType)_\(value)_\(limit ?? 0)_\(page ?? 0)"

        if let cachedResult = try? await searchResultsStorage?.async.object(forKey: cacheKey) {
            PODLogInfo("Fetched search result from cache")
            return cachedResult
        }

        var finalResult: PodHub
        let result = try await lookupItunes(searchFor: mediaType, value: value, limit: limit, page: page)

        if result.results.isEmpty {
            let indexResult = try await lookupPodcastIndex(searchFor: mediaType, value: value)
            finalResult = try normalizeResult(result: indexResult, mediaType: mediaType, totalCount: indexResult.count)
        } else {
            finalResult = try normalizeResult(result: result, mediaType: mediaType, totalCount: result.resultCount)
        }

        searchResultsStorage?.async.setObject(finalResult, forKey: cacheKey) { result in
            if case .failure(let error) = result {
                PODLogError("Failed to cache search result: \(error)")
            }
        }

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
