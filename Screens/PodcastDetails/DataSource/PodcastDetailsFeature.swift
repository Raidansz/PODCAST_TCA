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
public struct PodcastDetailsFeature {
    @ObservableState
    public struct State {
        let podcast: Podcast
        var episodes: [Episode]?
        var isLoading: Bool = false
        @Presents var playEpisode: PlayerFeature.State?
        var episodeURL: URL?
        @Shared(.runningItem) var runningItem = RunningItem()
    }

    public enum Action {
        case fetchEpisode
        case cellTapped(Episode)
        case playEpisode(PresentationAction<PlayerFeature.Action>)
        case episodeResponse([Episode]?)
    }

    private func parseFeed(url: URL?) async throws -> [Episode] {
        return try await withCheckedThrowingContinuation { continuation in
            guard let url else { return }
            let parser = FeedParser(URL: url)
            parser.parseAsync { result in
                switch result {
                case let .success(feed):
                    guard let rssFeed = feed.rssFeed else {
                        continuation.resume(returning: [])
                        return
                    }
                    let episodes = rssFeed.toEpisodes()
                    continuation.resume(returning: episodes)
                case let .failure(parserError):
                    continuation.resume(throwing: parserError)
                }
            }
        }
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .fetchEpisode:
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
