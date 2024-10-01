//
//  PodHubModel.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 09. 28..
//
import Foundation
import ComposableArchitecture
import SwiftyJSON

struct PodHub: Equatable {
    static func == (lhs: PodHub, rhs: PodHub) -> Bool {
        lhs.id == rhs.id
    }

    var id: UUID = UUID()
    var podcasts: IdentifiedArrayOf<Podcast> = []

    init(result: PodHubConvertable, mediaType: MediaType) throws {
        self.podcasts = IdentifiedArray()

      
        if let searchResults = result as? SearchResults {
            if !searchResults.results.isEmpty {
                let uniquePodcasts = removeDuplicatePodcasts(from: searchResults.results.map { Podcast(item: $0, mediaType: mediaType) })
                self.podcasts = IdentifiedArray(uniqueElements: uniquePodcasts)
                return
            }
        }

        if let podcastIndexResponse = result as? PodcastIndexResponse {
            if !podcastIndexResponse.items.isEmpty {
                let uniquePodcasts = removeDuplicatePodcasts(from: podcastIndexResponse.items.map { Podcast(item: $0, mediaType: mediaType) })
                self.podcasts = IdentifiedArray(uniqueElements: uniquePodcasts)
                return
            }
        }

        throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Result is empty or unrecognized"])
    }

    private func removeDuplicatePodcasts(from podcasts: [Podcast]) -> [Podcast] {
        var seen = Set<UUID>()
        return podcasts.filter { podcast in
            guard !seen.contains(podcast.id) else {
                return false
            }
            seen.insert(podcast.id)
            return true
        }
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
   // var episodes: IdentifiedArrayOf<Episode>

    init(item: SearchResult, mediaType: MediaType){
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
      //  self.episodes = IdentifiedArray(uniqueElements: item.res.map { Episode(item: $0) })
    }

    init(item: Item, mediaType: MediaType){
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
      //  self.episodes = IdentifiedArray(uniqueElements: item.res.map { Episode(item: $0) })
    }
}

struct Episode: Identifiable {
    var id: String
}
protocol PodHubConvertable {
    
}


//if let episodes = json["episodes"].array {
//    let resultsArray = json["results"].arrayValue
//    let searchResults = resultsArray.map { SearchResult(json: $0) }
//    self.items = IdentifiedArray(uniqueElements: episodes.map { Item(json: $0) })

extension Collection {
    var isNotEmpty: Bool {
        return !isEmpty
    }
}
