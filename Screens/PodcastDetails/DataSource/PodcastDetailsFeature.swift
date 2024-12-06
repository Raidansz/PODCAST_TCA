//
//  PodcastDetailsFeature.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 11. 02..
//
import Foundation
import ComposableArchitecture
import FeedKit

@Reducer
public struct PodcastDetailsFeature: Sendable {
    @ObservableState
    public struct State {
        let podcast: Podcast
        var episodes: [Episode]?
        var isLoading: Bool = false
        @Presents var playEpisode: PlayerFeature.State?
        var episodeURL: URL?
    }

    public enum Action {
        case fetchEpisode
        case cellTapped(Episode)
        case playEpisode(PresentationAction<PlayerFeature.Action>)
        case episodeResponse([Episode]?)
    }

    private func parseFeed(url: URL?) async throws -> [Episode] {
        guard let url = url else { return [] }

        return try await Task { () -> [Episode] in
            let parser = FeedParser(URL: url)
            let result = parser.parse()

            switch result {
            case .success(let feed):
                if let episodes = feed.rssFeed?.toEpisodes() {
                    return episodes
                } else {
                    return []
                }
            case .failure(let error):
                throw error
            }
        }.value
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .fetchEpisode:
                state.episodes = nil
                state.isLoading = true
                return .run { [url = state.podcast.feedURL] send in
                    try await send(
                        .episodeResponse(
                            self.parseFeed(url: url)
                        )
                    )
                }
            case .episodeResponse(let response):
                state.isLoading = false
                state.episodes = response
                return .none
            case .cellTapped(let episode):
                state.playEpisode = PlayerFeature.State(episode: episode)
                return .none
            case .playEpisode:
                return .none
            }
        }
        .ifLet(\.$playEpisode, action: \.playEpisode) {
            PlayerFeature()
        }
    }
}
