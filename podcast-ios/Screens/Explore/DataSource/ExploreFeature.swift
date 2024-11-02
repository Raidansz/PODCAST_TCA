//
//  ExploreFeature.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 11. 02..
//

import ComposableArchitecture

@Reducer
struct ExploreFeature: Sendable {
    @ObservableState
    struct State {
        var podcastsList: PodHub?
        var isLoading: Bool = false
        var selectedPodcast: Item?
        var searchTerm = ""
        var searchPodcastResults: PodHub?
        var path = StackState<Path.State>()
        @Presents var destination: Destination.State?
    }

    @Reducer
    enum Path {
        case podcastDetails(PodcastDetailsFeature)
        case searchResults(ExploreSearchFeature)
    }

    @Reducer
    enum Destination {
        case showMorePodcasts(ShowMorePodcastFeature)
        case settings(SettingFeature)
    }

    enum Action {
        case fetchPodcasts
        case fetchPodcastsResponse(PodHub)
        case searchForPodcastTapped(with: String)
        case searchTermChanged(String)
        case showSearchResults(PodHub, String)
        case settingsTapped
        case path(StackActionOf<Path>)
        case podcastDetailsTapped(Podcast)
        case destination(PresentationAction<Destination.Action>)
    }

    @Injected(\.podHubManager) private var podHubManager: PodHubManagerProtocol

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .fetchPodcasts:
                state.podcastsList = nil
                state.isLoading = true
                return .run {  send in
                    try await send(
                        .fetchPodcastsResponse(
                            self.podHubManager.getTrendingPodcasts()
                        )
                    )
                }
            case .fetchPodcastsResponse(let response):
                state.isLoading = false
                state.podcastsList = response
                return .none
            case .searchForPodcastTapped(with: let term):
                if term.isEmpty {
                    return .none
                }
                state.isLoading = true
                return .run { send in
                    try await send(
                        .showSearchResults(
                            self.podHubManager.searchFor(
                                searchFor: .podcast,
                                value: term,
                                limit: nil,
                                page: nil, id: nil
                            ),
                            term
                        )
                    )
                }
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
            }
        }
        .ifLet(\.$destination, action: \.destination)
        .forEach(\.path, action: \.path)
    }
}
