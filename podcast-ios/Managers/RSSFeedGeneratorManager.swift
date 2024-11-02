//
//  RSSFeedGeneratorManager.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 10. 30..
//
import Foundation
import FeedKit
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
        urlComponents.path = "/api/v2/\(country.rawValue)/podcasts/top/\(limit)/podcasts.rss"

        guard let url = urlComponents.url else { return [] }
        let firstResult = try await parseFeed(url: url)
        let result = firstResult?.link
        guard let result else { return [] }
        let finalResult = try await parseFeed(url: URL(string: result))?.toPodcasts() ?? []
        var ids: [String] = []
        finalResult.forEach { item in
            ids.append(extractPodcastID(from: item.id) ?? "")
        }
        return ids
    }

    func getTopChartedEpisodes(limit: Int, country: Country) async throws -> IdentifiedArrayOf<Episode> {
        var urlComponents = URLComponents()
        urlComponents.scheme = scheme
        urlComponents.host = mainURL
        urlComponents.path = "/api/v2/\(country.rawValue)/podcasts/top/\(limit)/podcast-episodes.rss"
        guard let url = urlComponents.url else { return [] }
        let result = try await parseFeed(url: url)?.link
        guard let result else { return [] }
        let finalResult = try await parseFeed(url: URL(string: result))?.toEpisodes() ?? []
        return finalResult
    }

    private func parseFeed(url: URL?) async throws -> RSSFeed? {
        guard let url = url else { return nil }
        let parser = FeedParser(URL: url)
        return try await parser.parseAsync().rssFeed
    }
}

protocol RSSFeedGeneratorManagerProtocol {
    func getTopChartedPodcast(limit: Int, country: Country) async throws -> [String]
    func getTopChartedEpisodes(limit: Int, country: Country) async throws -> IdentifiedArrayOf<Episode>
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
