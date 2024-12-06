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
public struct HomeFeature: Sendable {
    @ObservableState
    public struct State: Equatable {
        public static func == (lhs: HomeFeature.State, rhs: HomeFeature.State) -> Bool {
            lhs.id == lhs.id
        }

        public var path = StackState<Path.State>()
        public var isLoading: Bool = false
        public let limit = 10
        @Presents var destination: Destination.State?
        public let id = UUID()
        public var podcasts: [Podcast]?
        public init() {}
    }

    public enum Action {
        case fetchTrendingPodcasts
        case loadView
        case trendingPodcastResponse(PodcastResult)
        case path(StackActionOf<Path>)
        case podcastDetailsTapped(Podcast)
        case destination(PresentationAction<Destination.Action>)
    }

    @Dependency(\.podHubClient) var podhubClient

    @Reducer
    public enum Path {
        case podcastDetails(PodcastDetailsFeature)
    }

    @Reducer
    public enum Destination {
    }
    public init() {}
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .fetchTrendingPodcasts:
                state.isLoading = true
                return .run { send in
                    try await send(
                        .trendingPodcastResponse(
                            podhubClient.getLocalTrendingPodcasts(50)
                        )
                    )
                }
            case .trendingPodcastResponse(let result):
                state.podcasts = result.podcastList
                state.isLoading = false
                return .none
            case .loadView:
                return .run { send in
                    await send(.fetchTrendingPodcasts)
                }
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
