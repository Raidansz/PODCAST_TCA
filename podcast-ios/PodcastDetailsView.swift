//
//  PodcastDetailsView.swift
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
        NavigationStack {
            ZStack(alignment: .top) {
                ScrollView {
                    // TODO: Pagination
                    Section(content: {
                        LazyVStack(spacing: 24) {
                            if (store.episodes) != nil {
                                ForEach((store.episodes!), id: \.self) { response in
                                    ListEpisodeViewCell(episode: response)
                                        .shadow(color: .black.opacity(0.2), radius: 10, x: 5, y: 5)
                                }
                            }
                        }
                    }, header: {
                        ListViewHero(imageURL: store.podcast.image ?? URL(string: "")!)
                            .frame(width: 380, height: 380)
                            .padding(.bottom, 20)
                    })
                    .padding(.horizontal, 16)
                }
                .blur(
                    radius: store.isLoading ? 5 : 0
                )
                if store.isLoading {
                    ProgressView("Please wait")
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .onAppear {
            store.send(.fetchEpisode)
        }
    }
}
