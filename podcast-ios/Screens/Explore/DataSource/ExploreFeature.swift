//
//  ExploreFeature.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 11. 02..
//

import ComposableArchitecture
import SwiftUICore
import Combine
import AppServices

@Reducer
struct ExploreFeature: Sendable {
    @ObservableState
    struct State {
        var isLoading: Bool = false
        var searchTerm = ""
        var searchPodcastResults: PodcastResult?
        var path = StackState<Path.State>()
        var catagoryList: [PodcastCategory] {
            globalCatagories
        }
        var themeForCatagories = getRandomTheme()
        let searchID = "search"
        @Shared(.sharedStateManager) var sharedStateManager = SharedStateManager()
        @Presents var destination: Destination.State?
    }

    @Reducer
    enum Path {
        case podcastDetails(PodcastDetailsFeature)
        case categoryDetails(CategoryDetailsFeature)
        case searchResults(ExploreSearchFeature)
    }

    @Reducer
    enum Destination {
        case showMorePodcasts(ShowMorePodcastFeature)
        case settings(SettingFeature)
    }

    enum Action {
        case fetchPodcasts
        case fetchPodcastsResponse(PodcastResult)
        case searchForPodcastTapped(with: String)
        case searchTermChanged(String)
        case showSearchResults(PodcastResult, String)
        case settingsTapped
        case path(StackActionOf<Path>)
        case podcastDetailsTapped(Podcast)
        case catagoryTapped(PodcastCategory)
        case destination(PresentationAction<Destination.Action>)
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .fetchPodcasts:
                state.sharedStateManager.setPodcasts(podcasts: nil)
                state.isLoading = true
                return .run {  send in
                    try await send(
                        .fetchPodcastsResponse(
                            PodHubManager.shared.getTrendingPodcasts(country: .unitedStates, limit: 50)
                        )
                    )
                }
            case .fetchPodcastsResponse(let response):
                state.isLoading = false
                state.sharedStateManager.setPodcasts(podcasts: response.podcastList)
                return .none
            case .searchForPodcastTapped(with: let term):
                if term.isEmpty {
                    return .none
                }
                state.isLoading = true
                return .run { send in
                    try await send(
                        .showSearchResults(
                            PodHubManager.shared.searchFor(
                                searchFor: .podcasts, value: term),
                            term
                        )
                    )
                } catch: { [state] error, send in
                    Task.cancel(id: state.searchID)
                }
                    .cancellable(id: state.searchID)
            case .searchTermChanged(let searchTerm):
                state.searchTerm = searchTerm
                return .none
            case .path:
                return .none
            case .podcastDetailsTapped(let podcast):
                state.path.append(.podcastDetails(PodcastDetailsFeature.State(podcast: podcast)))
                return .none
            case .destination:
                return .none
            case .showSearchResults(let result, let initialTerm):
                state.isLoading = false
                if state.path.isEmpty {
                    state.path.append(.searchResults(ExploreSearchFeature.State(searchResult: result, searchTerm: initialTerm)))
                }
                return .none
            case .settingsTapped:
                state.destination = .settings(SettingFeature.State())
                return .none
            case .catagoryTapped(let catagory):
                state.path.append(.categoryDetails(CategoryDetailsFeature.State(category: catagory)))
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
        .forEach(\.path, action: \.path)
    }
}
