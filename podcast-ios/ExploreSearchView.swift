//
//  ExploreSearchView.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 10. 22..
//

import SwiftUI
import ComposableArchitecture
import FeedKit
@Reducer
struct ExploreSearchFeature {
    @ObservableState
    struct State: Equatable {
        var searchResult: PodHub?
        var episodes: IdentifiedArrayOf<Episode>?
        var isLoading: Bool = false
        @Presents var playEpisode: PlayerFeature.State?
        var episodeURL: URL?
        var searchTerm: String = ""
    }

    enum Action: Equatable {
        case cellTapped(Episode)
        case playEpisode(PresentationAction<PlayerFeature.Action>)
        case episodeResponse(IdentifiedArrayOf<Episode>?)
        case onDisappear
        case searchTermChanged(String)
        case searchForPodcastTapped(with: String)
        case showSearchResults(PodHub)
    }

    @Injected(\.podHubManager) private var podHubManager: PodHubManagerProtocol

    private func parseFeed(url: URL?) async throws -> IdentifiedArrayOf<Episode> {
        guard let url = url else {
            return []
        }
        let parser = FeedParser(URL: url)
        let result = try await parser.parseAsync()
        guard let rssFeed = result.rssFeed else {
            return []
        }

        return rssFeed.toEpisodes()
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .episodeResponse(let response):
                state.isLoading = false
                state.episodes = response
                return .none
            case .cellTapped(let episode):
                state.playEpisode = PlayerFeature.State(episode: episode)
                return .none
            case .playEpisode:
                return .none
            case .onDisappear:
                state.episodes = nil
                return .none
            case .searchTermChanged(let term):
                state.searchTerm = term
                return .none
            case .searchForPodcastTapped(with: let term):
                if term.isEmpty {
                    return .none
                }
                state.searchResult = nil
                state.isLoading = true
                return .run { send in
                    try await send(
                        .showSearchResults(
                            self.podHubManager.searchFor(
                                searchFor: .podcast,
                                value: term,
                                limit: nil,
                                page: nil,
                                id: nil
                            )
                        )
                    )
                }
            case .showSearchResults(let result):
                state.isLoading = false
                state.searchResult = result
                return .none
            }
        }
        .ifLet(\.$playEpisode, action: \.playEpisode) {
            PlayerFeature()
        }
    }
}

struct ExploreSearchView: View {
    @State var store: StoreOf<ExploreSearchFeature>
    var body: some View {
            ZStack(alignment: .top) {
                ScrollView {
                    ZStack {
                        RoundedRectangle(cornerRadius: 32)
                            .fill(Color(red: 31/255, green: 31/255, blue: 31/255, opacity: 0.08))
                            .frame(width: 364, height: 64)
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.black)
                                .padding(.leading, 15)
                            TextField(
                                "Search the podcast here...",
                                text: $store.searchTerm.sending(\.searchTermChanged)
                            )
                            .padding(.leading, 5)
                            .onSubmit {
                                store.send(.searchForPodcastTapped(with: store.searchTerm))
                            }
                        }
                        .frame(width: 364, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 32))
                    }
                    .padding()
                    // TODO: Pagination
                    LazyVStack(spacing: 24) {
                        if let list = store.searchResult?.podcasts {
                            ForEach(list, id: \.self) { response in
                                NavigationLink(
                                    state: ExploreFeature.Path.State.podcastDetails(PodcastDetailsFeature.State(podcast: response))
                                ) {
                                    ListViewCell(
                                        imageURL: response.image,
                                        author: response.author, title: response.title,
                                        isPodcast: false
                                    )
                                    .shadow(color: .black.opacity(0.2), radius: 10, x: 5, y: 5)
                                }
                            }
                        }
                    }
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
        .sheet(
            store: self.store.scope(
                state: \.$playEpisode,
                action: \.playEpisode
            )
        ) { store in
            NavigationStack {
                PlayerView(store: store)
                    .navigationTitle(store.episode.title)
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}
