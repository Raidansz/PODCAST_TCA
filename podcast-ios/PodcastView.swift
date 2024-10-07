//
//  PodcastView.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 10. 07..
//

import SwiftUI
import ComposableArchitecture
import FeedKit
@Reducer
struct PodcastDetailsFeature {
    @ObservableState
    struct State: Equatable {
        let podcast: Podcast
        var episodes: IdentifiedArrayOf<Episode>?
        var isLoading: Bool = false
        var episodeURL: URL?
    }
    
    enum Action: Equatable {
        case fetchEpisode
        case episodeResponse(IdentifiedArrayOf<Episode>?)
    }
    
    private func parseFeed(url: URL?) async throws -> IdentifiedArrayOf<Episode> {
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
    
    var body: some ReducerOf<Self> {
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
            }
        }
    }
}

struct PodcastDetailsView: View {
    @State var store: StoreOf<PodcastDetailsFeature>
    var body: some View {
        List(store.episodes ?? []) { episode in
            Text(episode.title)
            
        }
    }
}
