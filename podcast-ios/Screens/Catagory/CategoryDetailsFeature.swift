//
//  CategoryDetailsFeature.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 11. 05..
//

import Foundation
import ComposableArchitecture
import FeedKit

@Reducer
struct CategoryDetailsFeature: Sendable {
    @ObservableState
    struct State {
        let category: Catagory
        var isLoading: Bool = false
        @Presents var playEpisode: PlayerFeature.State?
        var episodeURL: URL?
        @Shared(.runningItem) var runningItem = RunningItem()
        @Shared(.sharedStateManager) var sharedStateManager = SharedStateManager()

        init(category: Catagory) {
            self.category = category
        }
    }

    enum Action {
        case fetchPodcastList(for: Catagory)
        case podcastResponse(PodcastResult?)
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .fetchPodcastList(for: let category):
                state.sharedStateManager.setPodcasts(podcasts: nil)
                state.isLoading = true
                return .run {[id = category.id]  send in
                    try await send(
                        .podcastResponse(
                            PodHubManager.shared.getPodcastListOfCatagory(catagory: id)
                        )
                    )
                }
            case .podcastResponse(let response):
                state.sharedStateManager.setPodcasts(podcasts: response?.podcastList)
                state.isLoading = false
                return .none
            }
        }
    }
}
