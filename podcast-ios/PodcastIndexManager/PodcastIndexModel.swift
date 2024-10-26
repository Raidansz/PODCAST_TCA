//
//  PodcastIndexModel.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 09. 22..
//

import Foundation
import SwiftyJSON
import ComposableArchitecture

// MARK: - PodcastIndexResponse Model
struct PodcastIndexResponse: Equatable, Hashable, Identifiable, PodHubConvertable, Codable {
    var id: String
    let status: Bool
    var items: IdentifiedArrayOf<Item> = []
    let count: Int
    let query: String
    let description: String

    init(json: JSON) {
        self.status = json["status"].boolValue
        self.count = json["count"].intValue
        self.query = json["query"].stringValue
        self.description = json["description"].stringValue
        self.id = json["id"].stringValue

        if let episodes = json["episodes"].array {
            self.items = IdentifiedArray(uniqueElements: episodes.map { Item(json: $0) })

        } else if let items = json["items"].array {
            self.items = IdentifiedArray(uniqueElements: items.map { Item(json: $0) })

        } else if let feeds = json["feeds"].array {
            self.items = IdentifiedArray(uniqueElements: feeds.map { Item(json: $0) })

        } else {
            self.items = IdentifiedArray(uniqueElements: [])
        }

    }

    static func == (lhs: PodcastIndexResponse, rhs: PodcastIndexResponse) -> Bool {
        return lhs.status == rhs.status &&
               lhs.count == rhs.count &&
               lhs.query == rhs.query &&
               lhs.description == rhs.description &&
               lhs.items == rhs.items
    }
}

// MARK: - Item Model
struct Item: Equatable, Hashable, Identifiable, PodHubConvertable, Codable {
    let id: Int
    let title: String
    let link: URL?
    let description: String
    let guid: String
    let datePublished: Date
    let dateCrawled: Date
    let enclosureUrl: URL?
    let enclosureType: String
    let enclosureLength: Int
    let duration: Int
    let explicit: Bool
    let episode: Int?
    let episodeType: String
    let season: Int
    let image: URL?
    let feedItunesId: Int?
    let feedImage: URL?
    let feedId: Int
    let feedUrl: URL?
    let feedAuthor: String
    let feedTitle: String
    let feedLanguage: String
    let chaptersUrl: URL?
    let transcriptUrl: URL?
    let url: URL?
//    let transcripts: [Transcript]

    init(json: JSON) {
        self.id = json["id"].intValue
        self.title = json["title"].stringValue
        self.link = URL(string: json["link"].stringValue)
        self.description = json["description"].stringValue
        self.guid = json["guid"].stringValue
        self.datePublished = Date(timeIntervalSince1970: TimeInterval(json["datePublished"].intValue))
        self.dateCrawled = Date(timeIntervalSince1970: TimeInterval(json["dateCrawled"].intValue))
        self.enclosureUrl = URL(string: json["enclosureUrl"].stringValue)
        self.enclosureType = json["enclosureType"].stringValue
        self.enclosureLength = json["enclosureLength"].intValue
        self.duration = json["duration"].intValue
        self.explicit = json["explicit"].boolValue
        self.episode = json["episode"].int
        self.episodeType = json["episodeType"].stringValue
        self.season = json["season"].intValue
        self.image = URL(string: json["image"].stringValue)
        self.feedItunesId = json["feedItunesId"].int
        self.feedImage = URL(string: json["feedImage"].stringValue)
        self.feedId = json["feedId"].intValue
        self.feedUrl = URL(string: json["feedUrl"].stringValue)
        self.feedAuthor = json["feedAuthor"].stringValue
        self.feedTitle = json["feedTitle"].stringValue
        self.feedLanguage = json["feedLanguage"].stringValue
        self.chaptersUrl = URL(string: json["chaptersUrl"].stringValue)
        self.transcriptUrl = URL(string: json["transcriptUrl"].stringValue)
//        self.transcripts = json["transcripts"].arrayValue.map { Transcript(json: $0) }
        self.url = URL(string: json["url"].stringValue)
    }

    static func == (lhs: Item, rhs: Item) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Transcript Model
struct Transcript: Hashable {
    let url: URL?
    let type: String

    init(json: JSON) {
        self.url = URL(string: json["url"].stringValue)
        self.type = json["type"].stringValue
    }
}
