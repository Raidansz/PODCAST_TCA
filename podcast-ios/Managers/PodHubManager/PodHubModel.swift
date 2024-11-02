//
//  PodHubModel.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 09. 28..
//

import Foundation
import ComposableArchitecture
import FeedKit

struct PodHub: Sendable, Equatable {
    static func == (lhs: PodHub, rhs: PodHub) -> Bool {
        lhs.id == rhs.id
    }

    var id: UUID = UUID()
    var podcasts: IdentifiedArrayOf<Podcast> = []
    var totalCount: Int

    init(result: PodHubConvertable, mediaType: MediaType, totalCount: Int) throws {
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

struct Podcast: Identifiable, Equatable, Hashable {
    var id: String
    var title: String?
    var image: URL?
    var publicationDate: Date?
    var author: String?
    var isPodcast: Bool
    var feedURL: URL?
    var type: String

    init(item: SearchResult, mediaType: MediaType) {
        self.id = "\(item.id)"
        self.title = item.trackName
        self.image = item.artworkUrl600 ?? item.artworkUrl100 ?? URL(filePath: "")!
        self.publicationDate = item.releaseDate
        self.author = item.artistName ?? ""
        self.isPodcast = mediaType == .podcast
        self.feedURL = item.feedUrl
        self.type = "it"
    }

    init(feedItem: RSSFeedItem) {
        self.id = feedItem.guid?.value ?? UUID().uuidString
        self.feedURL = URL(string: feedItem.enclosure?.attributes?.url ?? "") ?? URL(filePath: "")!
        self.title = feedItem.title ?? "No Title"
        self.publicationDate = feedItem.pubDate ?? Date()
        self.author = feedItem.iTunes?.iTunesAuthor ?? "Unknown Author"
        self.image = URL(string: feedItem.link ?? "")
        self.type = "RSSFeedGenerator"
        self.isPodcast = true
    }

    init(item: Item, mediaType: MediaType) {
        self.id = "\(item.id)"
        self.title = item.title
        self.image = item.image ?? item.feedImage ?? URL(filePath: "")!
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

struct Episode: Codable, Identifiable, Equatable, Hashable, PlayableItemProtocol {
    var id: String
    let title: String
    let pubDate: Date
    let description: String
    let author: String
    let streamURL: URL?

    var fileUrl: String?
    var imageUrl: URL?

    init(feedItem: RSSFeedItem) {
        self.id = feedItem.guid?.value ?? UUID().uuidString
        self.streamURL = URL(string: feedItem.enclosure?.attributes?.url ?? "") ?? URL(filePath: "")!
        self.title = feedItem.title ?? "No Title"
        self.pubDate = feedItem.pubDate ?? Date()
        self.author = feedItem.iTunes?.iTunesAuthor ?? "Unknown Author"
        self.imageUrl = URL(string: feedItem.iTunes?.iTunesImage?.attributes?.href ?? "")
        let descriptionText = feedItem.iTunes?.iTunesSubtitle ?? feedItem.description ?? "No Description Available"
        self.description = descriptionText.cleanHTMLTags()
    }
}
