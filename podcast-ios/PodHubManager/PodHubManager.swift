//
//  PodHubManager.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 09. 28..
//

class PodHubManager {
    @Injected(\.itunesManager) private var itunesManager: ItunesManagerProtocol
    @Injected(\.podcastIndexManager) private var podcastIndexManager: PodcastIndexManagerProtocol
}


protocol PodHubManagerProtocol  {
    func fetchTrendingPodcasts() async throws -> PodcastIndexResponse
}




//
//
//protocol ItunesManagerProtocol {
//    // swiftlint:disable:next function_parameter_count
//    func searchPodcasts (
//        term: String?,
//        country: Country?,
//        entity: Entity?,
//        attribute: String?,
//        genreId: PodcastGenre?,
//        limit: Int?,
//        lang: Language?,
//        version: Int?,
//        explicit: String?
//    ) async throws -> SearchResults
//
//    func searchPodcasts(term: String, entity: Entity) async throws -> SearchResults
//
//    func searchPodcasts(term: String) async throws -> SearchResults
//}
//protocol PodcastIndexManagerProtocol {
//    func getTrending() async throws -> PodcastIndexResponse
//}
