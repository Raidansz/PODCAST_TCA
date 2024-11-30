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
        //@Shared(.sharedStateManager) var sharedStateManager = SharedStateManager()
        public var podcasts: [Podcast]?
        public init() {}
    }

    public enum Action {
        case fetchTrendingPodcasts
        case loadView
        case trendingPodcastResponse(PodcastResult)
        //case fetchPodcastResponse(response: PodcastResult, ofCatagory: PodcastGenre)
        case path(StackActionOf<Path>)
        case podcastDetailsTapped(Podcast)
      //  case fetchCatagoryPodcastList(forCatagory: PodcastGenre)
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
                state.podcasts = result.podcastList ?? nil
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
//            case .fetchPodcastResponse(response: let response, ofCatagory: let ofCatagory):
//                state.sharedStateManager.setPodcasts(podcasts: response.podcastList, category: ofCatagory)
//                return .none
//            case .fetchCatagoryPodcastList(forCatagory: let forCatagory):
//                state.isLoading = true
//                return .run { send in
//                    try await send(
//                        .fetchPodcastResponse(response: podhubClient.getPodcastListOfCatagory(forCatagory), ofCatagory: forCatagory)
//                    )
//                }
            }
        }
        .ifLet(\.$destination, action: \.destination)
        .forEach(\.path, action: \.path)
    }
}
