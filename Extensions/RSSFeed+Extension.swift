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
            var item = Episode(feedItem: feedItem)
            if item.imageUrl == nil {
                item.imageUrl = URL(string: imageUrl ?? "")
            }
            episodes.append(item)
        }
        return episodes
    }
}
