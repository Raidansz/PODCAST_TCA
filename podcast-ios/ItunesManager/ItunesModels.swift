//
//  ItunesModels.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 09. 21..
//

import Foundation
import SwiftyJSON

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

class SearchResults {
    let resultCount: Int!
    let results: [SearchResult]!

    init(resultCount: Int, results: [SearchResult]) {
        self.resultCount = resultCount
        self.results = results
    }
}

extension Formatter {
    static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        return formatter
    }()
}

class SearchResult: PartialPodcast {
    var wrapperType: String!
    var kind: String!
    var collectionId: Int!
    var trackId: Int?
    var artistName: String!
    var collectionName: String!
    let trackName: String!
    let collectionCensoredName: String!
    let trackCensoredName: String!
    let collectionViewUrl: URL!
    var feedUrl: URL!
    let trackViewUrl: URL!
    var artworkUrl30: URL?
    var artworkUrl60: URL?
    var artworkUrl100: URL?
    var collectionPrice: Double?
    let trackPrice: Double?
    let trackRentalPrice: Double?
    let collectionHdPrice: Double?
    let trackHdPrice: Double?
    let trackHdRentalPrice: Double?
    let releaseDate: Date!
    var collectionExplicitness: String!
    let trackExplicitness: String!
    let trackCount: Int?
    let country: String!
    let currency: String!
    var primaryGenreName: String!
    let contentAdvisoryRating: String?
    var artworkUrl600: URL?
    var genreIds: [String]!
    var genres: [String]!

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
}
