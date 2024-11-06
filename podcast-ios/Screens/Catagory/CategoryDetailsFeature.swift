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
struct CategoryDetailsFeature: Sendable{
    @ObservableState
    struct State {
        let category: Catagory
        var podcastList: PodHub?
        var isLoading: Bool = false
        @Presents var playEpisode: PlayerFeature.State?
        var episodeURL: URL?
        @Shared(.runningItem) var runningItem = RunningItem()

        init(category: Catagory) {
            self.category = category
        }
    }

    enum Action {
        case fetchPodcastList(for: Catagory)
        case podcastResponse(PodHub?)
    }

    @Injected(\.podHubManager) private var podHubManager: PodHubManagerProtocol

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .fetchPodcastList(for: let category):
                state.podcastList = nil
                state.isLoading = true
                return .run {[id = category.id]  send in
                    try await send(
                        .podcastResponse(
                            self.podHubManager.getPodcastListOf(catagory: id)
                        )
                    )
                }
            case .podcastResponse(let response):
                state.podcastList = response
                state.isLoading = false
                return .none
            }
        }
    }
}
