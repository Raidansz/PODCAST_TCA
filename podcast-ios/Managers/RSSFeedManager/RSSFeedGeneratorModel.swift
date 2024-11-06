//
//  RSSFeedGeneratorModel.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 11. 05..
//

import SwiftyJSON
import Foundation

// MARK: - FeedResponse
struct RSSFeedResponse: Codable {
    var feed: RSSResponse?

    init(json: JSON) {
        if let feedJSON = json["feed"].dictionary {
            feed = RSSResponse(json: JSON(feedJSON))
        } else {
            feed = nil
        }
    }
}

// MARK: - Feed
struct RSSResponse: Codable {
    let results: [RSSPodcastID]

    init(json: JSON) {
        if let resultsArray = json["results"].array {
            results = resultsArray.compactMap { RSSPodcastID(json: $0) }
        } else {
            results = []
        }
    }
}

// MARK: - PodcastID
struct RSSPodcastID: Codable {
    let id: String

    init(json: JSON) {
        id = json["id"].stringValue
    }
}
