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
        case trendingPodcastResponse(PodcastResult)
        case fetchPodcastResponse(response: PodcastResult, ofCatagory: PodcastGenre)
        case path(StackActionOf<Path>)
        case podcastDetailsTapped(Podcast)
        case fetchCatagoryPodcastList(forCatagory: PodcastGenre)
        case destination(PresentationAction<Destination.Action>)
    }

    @Reducer
    enum Path {
        case podcastDetails(PodcastDetailsFeature)
    }

    @Reducer
    enum Destination {
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .fetchTrendingPodcasts:
                state.isLoading = true
                return .run { send in
                    try await send(
                        .trendingPodcastResponse(
                            PodHubManager.shared.getLocalTrendingPodcasts(limit: 50)
                        )
                    )
                }
            case .trendingPodcastResponse(let result):
                state.sharedStateManager.setPodcasts(podcasts: result.podcastList)
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
            case .fetchPodcastResponse(response: let response, ofCatagory: let ofCatagory):
                state.sharedStateManager.setPodcasts(podcasts: response.podcastList, category: ofCatagory)
                return .none
            case .fetchCatagoryPodcastList(forCatagory: let forCatagory):
                state.isLoading = true
                return .run { send in
                    try await send(
                        .fetchPodcastResponse(response: PodHubManager.shared.getPodcastListOfCatagory(catagory: forCatagory), ofCatagory: forCatagory)
                    )
                }
            }
        }
        .ifLet(\.$destination, action: \.destination)
        .forEach(\.path, action: \.path)
    }
}
