//
//  ItunesModels.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 09. 21..
//

import Foundation
import SwiftyJSON
import ComposableArchitecture
import SwiftData

protocol PartialPodcast {
    var collectionId: Int! { get }
    var feedUrl: URL! { get }
    var artistName: String! { get }
    var collectionName: String! { get }
    var artworkUrl30: URL? { get }
    var artworkUrl60: URL? { get }
    var artworkUrl100: URL? { get }
    var collectionExplicitness: String! { get }
    var primaryGenreName: String! { get }
    var artworkUrl600: URL? { get }
    var genreIds: [String]! { get }
    var genres: [String]! { get }
}

@Model
class SearchResults: Equatable, Identifiable, PodHubConvertable, Codable, Sendable {
    var resultCount: Int!
    var results: IdentifiedArrayOf<SearchResult> = []
    
    enum CodingKeys: CodingKey {
        case resultCount
        case results
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(resultCount, forKey: .resultCount)
        try container.encode(results, forKey: .results)
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        resultCount = try container.decode(Int.self, forKey: .resultCount)
        results = try container.decode(IdentifiedArrayOf<SearchResult>.self, forKey: .results)
    }

    init(resultCount: Int, results: IdentifiedArrayOf<SearchResult>) {
        self.resultCount = resultCount
        self.results = results
    }

    static func == (lhs: SearchResults, rhs: SearchResults) -> Bool {
        return lhs.results == rhs.results &&
        lhs.resultCount == rhs.resultCount
    }
}

extension Formatter {
    static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        return formatter
    }()
}
@Model
class SearchResult: Equatable, Identifiable, PartialPodcast, Codable {
    var wrapperType: String!
    var kind: String!
    var collectionId: Int!
    var trackId: Int?
    var artistName: String!
    var collectionName: String!
    var trackName: String!
    var collectionCensoredName: String!
    var trackCensoredName: String!
    var collectionViewUrl: URL!
    var feedUrl: URL!
    var trackViewUrl: URL!
    var artworkUrl30: URL?
    var artworkUrl60: URL?
    var artworkUrl100: URL?
    var collectionPrice: Double?
    var trackPrice: Double?
    var trackRentalPrice: Double?
    var collectionHdPrice: Double?
    var trackHdPrice: Double?
    var trackHdRentalPrice: Double?
    var releaseDate: Date!
    var collectionExplicitness: String!
    var trackExplicitness: String!
    var trackCount: Int?
    var country: String!
    var currency: String!
    var primaryGenreName: String!
    var contentAdvisoryRating: String?
    var artworkUrl600: URL?
    var genreIds: [String]!
    var genres: [String]!

    enum CodingKeys: CodingKey {
       case wrapperType
       case kind
       case collectionId
       case trackId
       case artistName
       case collectionName
       case trackName
       case collectionCensoredName
       case trackCensoredName
       case collectionViewUrl
       case feedUrl
       case trackViewUrl
       case artworkUrl30
       case artworkUrl60
       case artworkUrl100
       case collectionPrice
       case trackPrice
       case trackRentalPrice
       case collectionHdPrice
       case trackHdPrice
       case trackHdRentalPrice
       case releaseDate
       case collectionExplicitness
       case trackExplicitness
       case trackCount
       case country
       case currency
       case primaryGenreName
       case contentAdvisoryRating
       case artworkUrl600
       case genreIds
       case genres
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        wrapperType = try container.decode(String.self, forKey: .wrapperType)
        kind = try container.decode(String.self, forKey: .kind)
        collectionId = try container.decode(Int.self, forKey: .collectionId)
        trackId = try container.decodeIfPresent(Int.self, forKey: .trackId)
        artistName = try container.decode(String.self, forKey: .artistName)
        collectionName = try container.decode(String.self, forKey: .collectionName)
        trackName = try container.decode(String.self, forKey: .trackName)
        collectionCensoredName = try container.decode(String.self, forKey: .collectionCensoredName)
        trackCensoredName = try container.decode(String.self, forKey: .trackCensoredName)
        collectionViewUrl = try container.decode(URL.self, forKey: .collectionViewUrl)
        feedUrl = try container.decode(URL.self, forKey: .feedUrl)
        trackViewUrl = try container.decode(URL.self, forKey: .trackViewUrl)
        artworkUrl30 = try container.decodeIfPresent(URL.self, forKey: .artworkUrl30)
        artworkUrl60 = try container.decodeIfPresent(URL.self, forKey: .artworkUrl60)
        artworkUrl100 = try container.decodeIfPresent(URL.self, forKey: .artworkUrl100)
        collectionPrice = try container.decodeIfPresent(Double.self, forKey: .collectionPrice)
        trackPrice = try container.decodeIfPresent(Double.self, forKey: .trackPrice)
        trackRentalPrice = try container.decodeIfPresent(Double.self, forKey: .trackRentalPrice)
        collectionHdPrice = try container.decodeIfPresent(Double.self, forKey: .collectionHdPrice)
        trackHdPrice = try container.decodeIfPresent(Double.self, forKey: .trackHdPrice)
        trackHdRentalPrice = try container.decodeIfPresent(Double.self, forKey: .trackHdRentalPrice)
        releaseDate = try container.decode(Date.self, forKey: .releaseDate)
        collectionExplicitness = try container.decode(String.self, forKey: .collectionExplicitness)
        trackExplicitness = try container.decode(String.self, forKey: .trackExplicitness)
        trackCount = try container.decodeIfPresent(Int.self, forKey: .trackCount)
        country = try container.decode(String.self, forKey: .country)
        currency = try container.decode(String.self, forKey: .currency)
        primaryGenreName = try container.decode(String.self, forKey: .primaryGenreName)
        contentAdvisoryRating = try container.decodeIfPresent(String.self, forKey: .contentAdvisoryRating)
        artworkUrl600 = try container.decodeIfPresent(URL.self, forKey: .artworkUrl600)
        genreIds = try container.decode([String].self, forKey: .genreIds)
        genres = try container.decode([String].self, forKey: .genres)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(wrapperType, forKey: .wrapperType)
        try container.encode(kind, forKey: .kind)
        try container.encode(collectionId, forKey: .collectionId)
        try container.encodeIfPresent(trackId, forKey: .trackId)
        try container.encode(artistName, forKey: .artistName)
        try container.encode(collectionName, forKey: .collectionName)
        try container.encode(trackName, forKey: .trackName)
        try container.encode(collectionCensoredName, forKey: .collectionCensoredName)
        try container.encode(trackCensoredName, forKey: .trackCensoredName)
        try container.encode(collectionViewUrl, forKey: .collectionViewUrl)
        try container.encode(feedUrl, forKey: .feedUrl)
        try container.encode(trackViewUrl, forKey: .trackViewUrl)
        try container.encodeIfPresent(artworkUrl30, forKey: .artworkUrl30)
        try container.encodeIfPresent(artworkUrl60, forKey: .artworkUrl60)
        try container.encodeIfPresent(artworkUrl100, forKey: .artworkUrl100)
        try container.encodeIfPresent(collectionPrice, forKey: .collectionPrice)
        try container.encodeIfPresent(trackPrice, forKey: .trackPrice)
        try container.encodeIfPresent(trackRentalPrice, forKey: .trackRentalPrice)
        try container.encodeIfPresent(collectionHdPrice, forKey: .collectionHdPrice)
        try container.encodeIfPresent(trackHdPrice, forKey: .trackHdPrice)
        try container.encodeIfPresent(trackHdRentalPrice, forKey: .trackHdRentalPrice)
        try container.encode(releaseDate, forKey: .releaseDate)
        try container.encode(collectionExplicitness, forKey: .collectionExplicitness)
        try container.encode(trackExplicitness, forKey: .trackExplicitness)
        try container.encodeIfPresent(trackCount, forKey: .trackCount)
        try container.encode(country, forKey: .country)
        try container.encode(currency, forKey: .currency)
        try container.encode(primaryGenreName, forKey: .primaryGenreName)
        try container.encodeIfPresent(contentAdvisoryRating, forKey: .contentAdvisoryRating)
        try container.encodeIfPresent(artworkUrl600, forKey: .artworkUrl600)
        try container.encode(genreIds, forKey: .genreIds)
        try container.encode(genres, forKey: .genres)
    }

    init(json: JSON) {
        wrapperType = json["wrapperType"].string
        kind = json["kind"].string
        collectionId = json["collectionId"].int
        trackId = json["collectionId"].int
        artistName = json["artistName"].string
        collectionName = json["collectionName"].string
        trackName = json["trackName"].string ?? ""
        collectionCensoredName = json["collectionCensoredName"].string
        trackCensoredName = json["trackCensoredName"].string
        collectionViewUrl = URL(string: json["collectionViewUrl"].string ?? "") ?? URL(string: "")
        feedUrl = URL(string: json["feedUrl"].string ?? "")
        trackViewUrl = URL(string: json["trackViewUrl"].string ?? "") ?? URL(string: "")
        artworkUrl30 = URL(string: json["artworkUrl30"].string ?? "")
        artworkUrl60 = URL(string: json["artworkUrl60"].string ?? "")
        artworkUrl100 = URL(string: json["artworkUrl100"].string ?? "")
        artworkUrl600 = URL(string: json["artworkUrl600"].string ?? "")
        collectionPrice = json["collectionPrice"].double
        trackPrice = json["trackPrice"].double
        trackRentalPrice = json["trackRentalPrice"].double
        collectionHdPrice = json["collectionHdPrice"].double
        trackHdPrice = json["trackHdPrice"].double
        trackHdRentalPrice = json["trackHdRentalPrice"].double
        releaseDate = ISO8601DateFormatter().date(from: json["releaseDate"].string ?? "")
        collectionExplicitness = json["collectionExplicitness"].string
        trackExplicitness = json["trackExplicitness"].string
        trackCount = json["trackCount"].int
        country = json["country"].string
        currency = json["currency"].string
        primaryGenreName = json["primaryGenreName"].string
        contentAdvisoryRating = json["contentAdvisoryRating"].string

        if let genreIdsArray = json["genreIds"].array {
            genreIds = genreIdsArray.compactMap { $0.string }
        } else {
            genreIds = []
        }

        if let genresArray = json["genres"].array {
            genres = genresArray.compactMap { $0.string }
        } else {
            genres = []
        }
    }

    static func == (lhs: SearchResult, rhs: SearchResult) -> Bool {
        return lhs.collectionId == rhs.collectionId &&
               lhs.trackId == rhs.trackId &&
               lhs.artistName == rhs.artistName &&
               lhs.collectionName == rhs.collectionName &&
               lhs.trackName == rhs.trackName &&
               lhs.feedUrl == rhs.feedUrl &&
               lhs.collectionViewUrl == rhs.collectionViewUrl &&
               lhs.primaryGenreName == rhs.primaryGenreName
    }
}
