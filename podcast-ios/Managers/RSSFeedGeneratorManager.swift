//
//  RSSFeedGeneratorManager.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 10. 30..
//
import Foundation
import SwiftyJSON
import IdentifiedCollections

final class RSSFeedGeneratorManager: RSSFeedGeneratorManagerProtocol {
    private let scheme = "https"
    private let mainURL = "rss.applemarketingtools.com"

    func extractPodcastID(from urlString: String) -> String? {
        guard let url = URL(string: urlString) else { return nil }
        let lastComponent = url.lastPathComponent
        let pattern = #"id(\d+)"#
        if let range = lastComponent.range(of: pattern, options: .regularExpression) {
            return String(lastComponent[range].dropFirst(2))
        }
        return nil
    }

    func getTopChartedPodcast(limit: Int, country: Country) async throws -> [String] {
        var urlComponents = URLComponents()
        urlComponents.scheme = scheme
        urlComponents.host = mainURL
        urlComponents.path = "/api/v2/\(country.rawValue)/podcasts/top/\(limit)/podcasts.json"

        guard let url = urlComponents.url else { return [] }
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let json = JSON(data)
        let feedResponse = RSSFeedResponse(json: json)

        return feedResponse.feed?.results.map { $0.id } ?? []
    }

//    func getTopChartedEpisodes(limit: Int, country: Country) async throws -> IdentifiedArrayOf<Episode> {
//        var urlComponents = URLComponents()
//        urlComponents.scheme = scheme
//        urlComponents.host = mainURL
//        urlComponents.path = "/api/v2/\(country.rawValue)/podcasts/top/\(limit)/podcast-episodes.rss"
//        guard let url = urlComponents.url else { return [] }
//        let result = try await parseFeed(url: url)?.link
//        guard let result else { return [] }
//        let finalResult = try await parseFeed(url: URL(string: result))?.toEpisodes() ?? []
//        return finalResult
//    }

    deinit {
        PODLogInfo("RSSFeedGeneratorManager was deinitialized")
    }
}

protocol RSSFeedGeneratorManagerProtocol {
    func getTopChartedPodcast(limit: Int, country: Country) async throws -> [String]
//    func getTopChartedEpisodes(limit: Int, country: Country) async throws -> IdentifiedArrayOf<Episode>
}

private struct RSSFeedGeneratorManagerKey: @preconcurrency InjectionKey {
    @MainActor static var currentValue: RSSFeedGeneratorManagerProtocol = RSSFeedGeneratorManager()
}

extension InjectedValues {
    var rssFeedGeneratorManager: RSSFeedGeneratorManagerProtocol {
        get { Self[RSSFeedGeneratorManagerKey.self]}
        set { Self[RSSFeedGeneratorManagerKey.self] = newValue }
    }
}
