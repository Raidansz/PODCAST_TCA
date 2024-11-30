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
    func toEpisodes() -> [Episode] {
        let imageUrl = iTunes?.iTunesImage?.attributes?.href
        var episodes = [Episode]()
        items?.forEach { feedItem in
            let item = Episode(feedItem: feedItem)
            if item.imageUrl == nil {
                item.imageUrl = URL(string: imageUrl ?? "")
            }
            episodes.append(item)
        }
        return episodes
    }
}

extension FeedParser {
    public func parseRSSAsync() async throws -> Feed {
        return try await withCheckedThrowingContinuation { continuation in
            parseAsync { result in
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
