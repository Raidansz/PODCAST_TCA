//
//  PodHubModel.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 09. 28..
//

import Foundation
import ComposableArchitecture
import FeedKit
import UIKit
import AudioPlayer

final class Episode: Codable, Identifiable, PlayableItemProtocol {
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

struct Catagory: Identifiable, Hashable {
    let id: PodcastGenre
    let title: String
    let description: String
}

let artsDescription = "Explore podcasts about literature, visual arts, and performing arts."
let businessDescription = "Stay updated with industry insights, entrepreneurial tips, and financial advice."
let comedyDescription = "Enjoy a wide range of humorous shows, from stand-up to improv and storytelling."
let educationDescription = "Learn something new every day with topics ranging from science to history."
let healthAndFitnessDescription = "Get motivated with wellness tips, fitness guides, and mental health discussions."
let kidsAndFamilyDescription = "Family-friendly content with stories, music, and discussions for all ages."
let musicDescription = "Listen to music reviews, artist interviews, and discussions on music history."
let newsDescription = "Stay informed with current events, daily news updates, and analysis."
let religionAndSpiritualityDescription = "Explore diverse perspectives on spirituality, faith, and personal growth."
let scienceDescription = "Dive into the wonders of science, from the cosmos to biology and everything in between."
let societyAndCultureDescription = "Discover perspectives on culture, social issues, and lifestyle topics."
let sportsDescription = "Catch up on sports news, game analysis, and interviews with athletes."
let technologyDescription = "Keep up with the latest tech trends, innovations, and gadget reviews."
let tvAndFilmDescription = "Get insights into movies, television shows, and the entertainment industry."
let trueCrimeDescription = "Uncover real-life mysteries, true crime cases, and investigative storytelling."

let globalCatagories: IdentifiedArrayOf<Catagory> = [
    .init(id: .arts, title: "Arts", description: artsDescription),
    .init(id: .business, title: "Business", description: businessDescription),
    .init(id: .education, title: "Education", description: educationDescription),
    .init(id: .kidsAndFamily, title: "Kids & Family", description: kidsAndFamilyDescription),
    .init(id: .music, title: "Music", description: musicDescription),
    .init(id: .science, title: "Science", description: scienceDescription),
    .init(id: .societyAndCulture, title: "Society & Culture", description: societyAndCultureDescription),
    .init(id: .sports, title: "Sports", description: sportsDescription),
    .init(id: .technology, title: "Technology", description: technologyDescription)
]
