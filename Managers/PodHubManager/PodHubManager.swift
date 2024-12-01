//
//  PodHubManager.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 09. 28..
//

import ItunesPodcastManager
import Foundation
import Dependencies
import SwiftyJSON

public struct PodHubClient {
    var searchFor: @Sendable (Tab, String) async throws -> ItunesPodcastManager.PodcastResult
    var getLocalTrendingPodcasts: @Sendable (Int) async throws -> ItunesPodcastManager.PodcastResult
    var getTrendingPodcasts: @Sendable (Country, Int) async throws -> ItunesPodcastManager.PodcastResult
    var getPodcastListOfCatagory: @Sendable (
        ItunesPodcastManager.PodcastGenre
    ) async throws -> ItunesPodcastManager.PodcastResult
}

 extension PodHubClient: DependencyKey {
     public static let liveValue = Self { tab, term in
        let entity: Entity
        switch tab {
        case .all:
            entity = .podcastAndEpisode
        case .episodes:
            entity = .podcastEpisode
        case .podcasts:
            entity = .podcast
        }
        do {
            return  try await searchPodcasts(term: term, entity: entity)
        } catch {
            throw error
        }
    } getLocalTrendingPodcasts: { limit in
        let safeCountryCode: Country
        if let countryCode = UserDefaults.standard.string(forKey: "DetectedCountry"),
           let country = Country(rawValue: countryCode) {
            safeCountryCode = country
        } else {
            safeCountryCode = .unitedStates
        }
        do {
            return try await getTrendingPodcastItems(country: safeCountryCode, limit: limit)
        } catch {
            throw error
        }
    } getTrendingPodcasts: { country, limit in
        do {
            return try await getTrendingPodcastItems(country: country, limit: limit)
        } catch {
            throw error
        }
    } getPodcastListOfCatagory: { catagory in
        do {
            return try await getPodcastListOf(category: catagory, mediaType: .podcast, limit: 50)
        } catch {
            throw error
        }
    }
}

public extension PodHubClient {
    static func mock() -> Self {
        guard let mockfile = Bundle.main.url(forResource: "mock", withExtension: "json") else {
            fatalError("Mock file not found")
        }
        do {
            let data = try Data(contentsOf: mockfile)
            let json = try JSON(data: data)
            let resultCount = json["resultCount"].intValue
            let resultsArray = json["results"].arrayValue
            let mockResults = resultsArray.compactMap { jsonItem in
                SearchResult(json: jsonItem)
            }

            let mockPodcastResult = PodcastResult(
                searchResults: SearchResults(
                    resultCount: resultCount,
                    results: mockResults
                )
            )

            return Self { _, _ in
                return mockPodcastResult
            } getLocalTrendingPodcasts: { _ in
                return mockPodcastResult
            } getTrendingPodcasts: { _, _ in
                return mockPodcastResult
            } getPodcastListOfCatagory: { _ in
                return mockPodcastResult
            }
        } catch {
            fatalError("Error parsing mock JSON: \(error.localizedDescription)")
        }
    }
}

public extension DependencyValues {
  var podHubClient: PodHubClient {
    get { self[PodHubClient.self] }
    set { self[PodHubClient.self] = newValue }
  }
}

public typealias Podcast = ItunesPodcastManager.Podcast
public typealias Country = ItunesPodcastManager.Country
public typealias PodcastResult = ItunesPodcastManager.PodcastResult
public typealias PodcastGenre = ItunesPodcastManager.PodcastGenre

extension PodcastResult: @retroactive Equatable {
    public static func == (lhs: ItunesPodcastManager.PodcastResult, rhs: ItunesPodcastManager.PodcastResult) -> Bool {
        lhs.id == rhs.id
    }
}

@globalActor actor PodhubActor: Sendable {
    public static let shared = PodhubActor()
}

extension Podcast: @retroactive Equatable {
    public static func == (lhs: ItunesPodcastManager.Podcast, rhs: ItunesPodcastManager.Podcast) -> Bool {
        lhs.id == rhs.id
    }
}
