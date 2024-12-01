//
//  CategoryDetailsFeature.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 11. 05..
//

import Foundation
import ComposableArchitecture


@Reducer
struct CategoryDetailsFeature: Sendable {
    @ObservableState
    struct State {
        let category: Catagory
        var isLoading: Bool = false
        @Presents var playEpisode: PlayerFeature.State?
        var episodeURL: URL?
        var podcasts: [Podcast]?
        init(category: Catagory) {
            self.category = category
        }
    }

    enum Action {
        case fetchPodcastList(for: Catagory)
        case podcastResponse(PodcastResult?)
    }

    @Dependency(\.podHubClient) var podhubClient

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .fetchPodcastList(for: let category):
                state.podcasts = nil
                state.isLoading = true
                return .run {[id = category.id]  send in
                    try await send(
                        .podcastResponse(
                            podhubClient.getPodcastListOfCatagory(id)
                        )
                    )
                }
            case .podcastResponse(let response):
                state.podcasts = response?.podcastList
                state.isLoading = false
                return .none
            }
        }
    }
}
