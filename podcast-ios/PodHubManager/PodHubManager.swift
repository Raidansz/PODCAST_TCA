//
//  PodHubManager.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 09. 28..
//

import Foundation

class PodHubManager {
    @Injected(\.itunesManager) private var itunesManager: ItunesManagerProtocol
    @Injected(\.podcastIndexManager) private var podcastIndexManager: PodcastIndexManagerProtocol

    func searchFor(searchFor: SearchFor, value: String) async throws -> PodHub {
        let result =  try await lookupItunes(searchFor: searchFor, value: value)
        if result.results.isEmpty {
            return try normalizeResult(result: try await lookupPodcastIndex(searchFor: searchFor, value: value))
        }
        return try normalizeResult(result: result)
    }

    func lookupItunes(searchFor: SearchFor, value: String) async throws -> SearchResults {
        let searchResult: SearchResults
        if searchFor == .podcast {
            searchResult = try await itunesManager.searchPodcasts(term: value, entity: .podcast)
        } else if searchFor == .episode {
            searchResult = try await itunesManager.searchPodcasts(term: value, entity: .podcastEpisode)
        } else {
            searchResult = try await itunesManager.searchPodcasts(term: value, entity: .podcastAndEpisode)
        }
        return searchResult
    }

    func lookupPodcastIndex(searchFor: SearchFor, value: String) async throws -> PodcastIndexResponse {
        if searchFor == .podcast {
            return   try await podcastIndexManager.performQuery(for: .podcast , .title(value), parameter: nil)
        } else {
            return  try await podcastIndexManager.performQuery(for: .episode , .title(value), parameter: nil)
        }
    }

    private func normalizeResult(result: PodHubConvertable) throws -> PodHub {
        if let item = result as? SearchResults { // Itunes
            
        } else if let item = result as? PodcastIndexResponse { // PodcastIndex
            
        }
        throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
    }

    enum SearchFor {
        case podcast
        case episode
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
