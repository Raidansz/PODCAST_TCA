//
//  HomeFeature.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 11. 02..
//

import ComposableArchitecture
import Kingfisher
import AVFoundation

@Reducer
struct HomeFeature: Sendable {
    @ObservableState
    struct State {
        var path = StackState<Path.State>()
        var isLoading: Bool = false
        let limit = 10
        @Presents var destination: Destination.State?
        let uuid = UUID()
        @Shared(.sharedStateManager) var sharedStateManager = SharedStateManager()
    }

    enum Action {
        case fetchTrendingPodcasts
        case loadView
        case trendingPodcastResponse(PodHub)
        case path(StackActionOf<Path>)
        case podcastDetailsTapped(Podcast)
        case destination(PresentationAction<Destination.Action>)
    }

    @Reducer
    enum Path {
        case podcastDetails(PodcastDetailsFeature)
    }

    @Reducer
    enum Destination {
        case showMorePodcasts(ShowMorePodcastFeature)
    }

    @Injected(\.podHubManager) private var podHubManager: PodHubManagerProtocol
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .fetchTrendingPodcasts:
                state.isLoading = true
                return .run { send in
                    try await send(
                        .trendingPodcastResponse(
                            self.podHubManager.getLocalTrendingPodcasts()
                        )
                    )
                }
            case .trendingPodcastResponse(let result):
                state.sharedStateManager.setPodcasts(podcasts: result.podcasts)
                state.isLoading = false
                return .none
            case .loadView:
                return .send(.fetchTrendingPodcasts)
            case .path:
                return .none
            case .destination:
                return .none
            case .podcastDetailsTapped(let podcast):
                state.path.append(.podcastDetails(PodcastDetailsFeature.State(podcast: podcast)))
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
        .forEach(\.path, action: \.path)
    }
}
