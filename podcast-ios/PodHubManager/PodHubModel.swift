//
//  PodHubModel.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 09. 28..
//

import Foundation
import ComposableArchitecture
import SwiftyJSON
import FeedKit

struct PodHub: Equatable {
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

        throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Result is empty or unrecognized"])
    }
}

struct Podcast: Identifiable, Equatable, Hashable {
    var id: UUID
    var title: String?
    var description: String?
    var image: URL?
    var publicationDate: Date?
    var author: String?
    var isPodcast: Bool
    var feedURL: URL?
    var type: String

    init(item: SearchResult, mediaType: MediaType) {
        if let uuid = UUID(uuidString: "\(item.id)") {
            self.id = uuid
        } else {
            self.id = UUID()
        }
        self.title = item.trackName
        self.description = "TBCH"
        self.image = item.artworkUrl600 ?? item.artworkUrl100!
        self.publicationDate = item.releaseDate
        self.author = item.artistName ?? ""
        self.isPodcast = mediaType == .podcast
        self.feedURL = item.feedUrl
        self.type = "it"
    }

    init(item: Item, mediaType: MediaType) {
        if let uuid = UUID(uuidString: "\(item.id)") {
            self.id = uuid
        } else {
            self.id = UUID()
        }
        self.title = item.title
        self.description = item.description
        self.image = item.image ?? item.feedImage!
        self.publicationDate = item.datePublished
        self.author = item.feedAuthor
        self.isPodcast = mediaType == .podcast
        self.feedURL = item.feedUrl
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
    let streamURL: URL

    var fileUrl: String?
    var imageUrl: URL?

    init(feedItem: RSSFeedItem) {
        self.id = feedItem.guid?.value ?? UUID().uuidString
        self.streamURL = URL(string: feedItem.enclosure?.attributes?.url ?? "")!
        self.title = feedItem.title ?? "No Title"
        self.pubDate = feedItem.pubDate ?? Date()
        self.description = Episode.cleanHTMLTags(
            from: feedItem.iTunes?.iTunesSubtitle ?? feedItem.description ?? "No Description Available")
        self.author = feedItem.iTunes?.iTunesAuthor ?? "Unknown Author"
        self.imageUrl = URL(string: (feedItem.iTunes?.iTunesImage?.attributes?.href)!)
    }

    private static func cleanHTMLTags(from string: String) -> String {
        let regex = try? NSRegularExpression(pattern: "<[^>]+>", options: .caseInsensitive)
        let range = NSMakeRange(0, string.count)
        let htmlLessString = regex?.stringByReplacingMatches(in: string, options: [], range: range, withTemplate: "")
        let cleanedString = htmlLessString?
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")

        return cleanedString?.trimmingCharacters(in: .whitespacesAndNewlines) ?? string
    }
}
