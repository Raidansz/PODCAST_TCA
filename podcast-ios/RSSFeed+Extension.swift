//
//  RSSFeed+Extension.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 10. 07..
//

import FeedKit
import ComposableArchitecture
import Foundation

extension RSSFeed {
    func toEpisodes() -> IdentifiedArrayOf<Episode> {
        let imageUrl = iTunes?.iTunesImage?.attributes?.href
        var episodes = IdentifiedArrayOf<Episode>()
        items?.forEach { feedItem in
            var episode = Episode(feedItem: feedItem)
            if episode.imageUrl == nil {
                episode.imageUrl = URL(string: imageUrl ?? "")
            }
            episodes.append(episode)
        }
        return episodes
    }
}

extension FeedParser: @unchecked @retroactive Sendable {
    public func parseAsync() async throws -> Feed {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = self.parse()

                switch result {
                case .success(let feed):
                    continuation.resume(returning: feed)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
