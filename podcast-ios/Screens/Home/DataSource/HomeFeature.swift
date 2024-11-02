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
        var trendingPodcasts: PodHub?
        var path = StackState<Path.State>()
        var isLoading: Bool = false
        let limit = 10
        @Presents var destination: Destination.State?
        let uuid = UUID()
    }

    enum Action {
        case fetchTrendingPodcasts
        case loadView
        case trendingPodcastResponse(PodHub)
        case showMorePodcastsTapped
        case path(StackActionOf<Path>)
        case podcastDetailsTapped(Podcast)
        case destination(PresentationAction<Destination.Action>)
        case resetPagination
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
                return .run {[limit = state.limit, id = state.uuid] send in
                    try await send(
                        .trendingPodcastResponse(
                            self.podHubManager.getTrendingPodcasts()
                        )
                    )
                }
            case .trendingPodcastResponse(let result):
                state.trendingPodcasts = result
                state.isLoading = false
                return .none
            case .loadView:
                if state.trendingPodcasts != nil {
                    return .none
                }
                return .send(.fetchTrendingPodcasts)
            case .path:
                return .none
            case .destination:
                return .none
            case .showMorePodcastsTapped:
                guard let podcasts = state.trendingPodcasts else { return .none }
                if state.limit < podcasts.podcasts.count {
                    state.destination = .showMorePodcasts(ShowMorePodcastFeature.State(trendingPodcasts: podcasts))
                }
                return .none
            case .podcastDetailsTapped(let podcast):
                state.path.append(.podcastDetails(PodcastDetailsFeature.State(podcast: podcast)))
                return .none
            case .resetPagination:
                let podcasts = state.trendingPodcasts?.podcasts
                guard let podcasts else { return .none }
                state.trendingPodcasts?.podcasts = IdentifiedArray(uniqueElements: Array(podcasts.prefix(5)))
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
        .forEach(\.path, action: \.path)
    }
}
