//
//  PodHubManager.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 09. 28..
//

import ItunesPodcastManager
import Foundation

protocol PodHubManagerProtocol {
    func searchFor(searchFor: Tab, value: String) async throws -> PodcastResult
    func getLocalTrendingPodcasts() async throws -> PodcastResult
    func getTrendingPodcasts() async throws -> PodcastResult
    func getPodcastListOf(catagory: PodcastGenre) async throws -> PodcastResult
}
@PodhubActor
class PodHubManager {
    static let shared = PodHubManager()
    func searchFor(searchFor: Tab, value: String) async throws -> ItunesPodcastManager.PodcastResult {
        let entity: Entity
        switch searchFor {
        case .all:
            entity = .podcastAndEpisode
        case .episodes:
            entity = .podcastEpisode
        case .podcasts:
            entity = .podcast
        }
        do {
            return     try await searchPodcasts(term: value, entity: entity)
        } catch {
            throw error
        }
    }

    func getLocalTrendingPodcasts(limit: Int) async throws -> ItunesPodcastManager.PodcastResult {
        let safeCountryCode: Country
        if let countryCode = UserDefaults.standard.string(forKey: "DetectedCountry"),
           let country = Country(rawValue: countryCode) {
            safeCountryCode = country
        } else {
            safeCountryCode = .unitedStates
        }
        do {
            return  try await  getTrendingPodcasts(country: safeCountryCode, limit: limit )
        } catch {
            throw error
        }
    }

    nonisolated  func getTrendingPodcasts(country: Country, limit: Int) async throws -> ItunesPodcastManager.PodcastResult {
        do {
            return try await getTrendingPodcastItems(country: country, limit: limit)
        } catch {
            throw error
        }
    }

    nonisolated func getPodcastListOfCatagory(
        catagory: ItunesPodcastManager.PodcastGenre
    ) async throws -> ItunesPodcastManager.PodcastResult {
        do {
            return try await getPodcastListOf(category: catagory, mediaType: .podcast, limit: 50)
        } catch {
            throw error
        }
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
