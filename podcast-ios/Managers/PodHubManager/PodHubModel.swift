//
//  PodHubModel.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 09. 28..
//

import Foundation
import ComposableArchitecture
import FeedKit
import SwiftyJSON
import SwiftData

struct PodHub: Sendable, Equatable, Codable {
    static func == (lhs: PodHub, rhs: PodHub) -> Bool {
        lhs.id == rhs.id
    }

    var id: UUID = UUID()
    var podcasts: IdentifiedArrayOf<Podcast> = []
    var totalCount: Int

    init(result: PodHubConvertable, mediaType: Entity, totalCount: Int) throws {
        self.podcasts = IdentifiedArray()
        self.totalCount = totalCount
        if let searchResults = result as? SearchResults {
            if !searchResults.results.isEmpty {
                let itunesPodcasts = searchResults.results.map {
                    Podcast(item: $0, mediaType: mediaType)
                }
                self.podcasts = IdentifiedArray(uniqueElements: itunesPodcasts)
                return
            }
        }

        if let podcastIndexResponse = result as? PodcastIndexResponse {
            if !podcastIndexResponse.items.isEmpty {
                let podcasts = podcastIndexResponse.items.map {
                    Podcast(item: $0, mediaType: mediaType)
                }
                self.podcasts = IdentifiedArray(uniqueElements: podcasts)
                return
            }
        }
        PODLogError("\(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Result is empty or unrecognized"]))")
        throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Result is empty or unrecognized"])
    }

    init(podcasts: IdentifiedArrayOf<Podcast>, count: Int) {
        self.podcasts = podcasts
        self.totalCount = count
    }
}
@Model
final class Podcast: Identifiable, Equatable, Hashable, Codable, Sendable {
    var id: String
    var title: String?
    var image: URL?
    var publicationDate: Date?
    var author: String?
    var isPodcast: Bool
    var feedURL: URL?
    var type: String

    enum CodingKeys: String, CodingKey {
        case id, title, image, publicationDate, author, isPodcast, feedURL, type
    }

    // Custom initializer to handle encoding and decoding
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        image = try container.decodeIfPresent(URL.self, forKey: .image)
        publicationDate = try container.decodeIfPresent(Date.self, forKey: .publicationDate)
        author = try container.decodeIfPresent(String.self, forKey: .author)
        isPodcast = try container.decode(Bool.self, forKey: .isPodcast)
        feedURL = try container.decodeIfPresent(URL.self, forKey: .feedURL)
        type = try container.decode(String.self, forKey: .type)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(image, forKey: .image)
        try container.encodeIfPresent(publicationDate, forKey: .publicationDate)
        try container.encodeIfPresent(author, forKey: .author)
        try container.encode(isPodcast, forKey: .isPodcast)
        try container.encodeIfPresent(feedURL, forKey: .feedURL)
        try container.encode(type, forKey: .type)
    }

    init(item: SearchResult, mediaType: Entity) {
        self.id = "\(item.id)"
        self.title = item.trackName
        self.image = item.artworkUrl600 ?? item.artworkUrl100 ?? URL(fileURLWithPath: "")
        self.publicationDate = item.releaseDate
        self.author = item.artistName ?? ""
        self.isPodcast = mediaType == .podcast
        self.feedURL = item.feedUrl
        self.type = "it"
    }

    init(feedItem: RSSFeedItem) {
        self.id = feedItem.guid?.value ?? UUID().uuidString
        self.feedURL = URL(string: feedItem.enclosure?.attributes?.url ?? "") ?? URL(fileURLWithPath: "")
        self.title = feedItem.title ?? "No Title"
        self.publicationDate = feedItem.pubDate ?? Date()
        self.author = feedItem.iTunes?.iTunesAuthor ?? "Unknown Author"
        self.image = URL(string: feedItem.link ?? "")
        self.type = "RSSFeedGenerator"
        self.isPodcast = true
    }

    init(item: Item, mediaType: Entity) {
        self.id = "\(item.id)"
        self.title = item.title
        self.image = item.image ?? item.feedImage ?? URL(fileURLWithPath: "")
        self.publicationDate = item.datePublished
        self.author = item.feedAuthor
        self.isPodcast = mediaType == .podcast
        self.feedURL = item.feedUrl ?? item.url
        self.type = "index"
    }
}

protocol PodHubConvertable {}

extension Collection {
    var isNotEmpty: Bool {
        return !isEmpty
    }
}
@Model
final class Episode: Codable, Identifiable, Equatable, Hashable, PlayableItemProtocol {
    var id: String
    var title: String
    var pubDate: Date
    var episodeDescription: String
    var author: String
    var streamURL: URL?

    var fileUrl: String?
    var imageUrl: URL?

    enum CodingKeys: String, CodingKey {
        case id, title, pubDate, episodeDescription, author, streamURL, fileUrl, imageUrl
    }

    // Custom initializer for decoding
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        pubDate = try container.decode(Date.self, forKey: .pubDate)
        episodeDescription = try container.decode(String.self, forKey: .episodeDescription)
        author = try container.decode(String.self, forKey: .author)
        streamURL = try container.decodeIfPresent(URL.self, forKey: .streamURL)
        fileUrl = try container.decodeIfPresent(String.self, forKey: .fileUrl)
        imageUrl = try container.decodeIfPresent(URL.self, forKey: .imageUrl)
    }

    // Custom encoding function
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(pubDate, forKey: .pubDate)
        try container.encode(episodeDescription, forKey: .episodeDescription)
        try container.encode(author, forKey: .author)
        try container.encodeIfPresent(streamURL, forKey: .streamURL)
        try container.encodeIfPresent(fileUrl, forKey: .fileUrl)
        try container.encodeIfPresent(imageUrl, forKey: .imageUrl)
    }

    init(feedItem: RSSFeedItem) {
        self.id = feedItem.guid?.value ?? UUID().uuidString
        self.streamURL = URL(string: feedItem.enclosure?.attributes?.url ?? "") ?? URL(fileURLWithPath: "")
        self.title = feedItem.title ?? "No Title"
        self.pubDate = feedItem.pubDate ?? Date()
        self.author = feedItem.iTunes?.iTunesAuthor ?? "Unknown Author"
        self.imageUrl = URL(string: feedItem.iTunes?.iTunesImage?.attributes?.href ?? "")
        let descriptionText = feedItem.iTunes?.iTunesSubtitle ?? feedItem.description ?? "No Description Available"
        self.episodeDescription = descriptionText.cleanHTMLTags()
    }
}
