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
        var searchResult: PodcastResult?
        var episodes: [Episode]?
        var isLoading: Bool = false
        @Presents var playEpisode: PlayerFeature.State?
        var episodeURL: URL?
        var searchTerm: String = ""
        var activeTab: Tab = .all
    }

    enum Action {
        case cellTapped(Episode)
        case playEpisode(PresentationAction<PlayerFeature.Action>)
        case episodeResponse([Episode]?)
        case onDisappear
        case searchTermChanged(String)
        case searchForPodcastTapped(with: String, activeTab: Tab)
        case showSearchResults(PodcastResult)
    }

    @Dependency(\.podHubClient) var podhubClient

    private func parseFeed(url: URL?) async throws -> [Episode] {
        guard let url = url else {
            return []
        }
        let parser = FeedParser(URL: url)
        let result = try await parser.parseRSSAsync()
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
            case .searchForPodcastTapped(with: let term, activeTab: let activeTab):
                if term.isEmpty {
                    return .none
                }
                state.activeTab = activeTab
                state.searchResult = nil
                state.isLoading = true
                return .run { [activeTab = state.activeTab] send in
                    try await send(
                        .showSearchResults(
                            podhubClient.searchFor(activeTab, term)
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
