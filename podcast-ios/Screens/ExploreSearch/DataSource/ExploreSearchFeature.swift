//
//  ExploreSearchFeature.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 11. 02..
//

import ComposableArchitecture
import FeedKit
import Foundation
@Reducer
struct ExploreSearchFeature {
    @ObservableState
    struct State {
        var searchResult: PodHub?
        var episodes: IdentifiedArrayOf<Episode>?
        var isLoading: Bool = false
        @Presents var playEpisode: PlayerFeature.State?
        var episodeURL: URL?
        var searchTerm: String = ""
        @Shared(.runningItem) var runningItem = RunningItem()
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
//                state.playEpisode = PlayerFeature.State(episode: episode)
                state.runningItem.setEpisode(episode: episode)
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
