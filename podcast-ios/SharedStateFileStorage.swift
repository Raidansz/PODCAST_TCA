//
//  SharedStateFileStorage.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 10. 25..
//

import ComposableArchitecture
import SwiftUI

@Reducer
struct SharedStateFileStorage: Sendable {
    enum Tab { case home, explore }
    @ObservableState
    struct State {
        var currentTab = Tab.home
        var home = HomeTab.State()
        var explore = ExploreTab.State()
        @Shared(.stats) var stats = Stats()
    }

    enum Action {
        case home(HomeTab.Action)
        case explore(ExploreTab.Action)
        case selectTab(Tab)
        case fetchPodcasts
        case fetchPodcastsResponse(PodHub?)
        case path(StackActionOf<Path>)
    }

    @Reducer
    enum Path {
        case podcastDetails(PodcastDetailsFeature)
    }

    @Injected(\.podHubManager) private var podhubManager: PodHubManagerProtocol

    var body: some Reducer<State, Action> {
        Scope(state: \.home, action: \.home) {
            HomeTab()
        }

        Scope(state: \.explore, action: \.explore) {
            ExploreTab()
        }

        Reduce { state, action in
            switch action {
            case .home, .explore:
                return .none
            case let .selectTab(tab):
                state.currentTab = tab
                return .none
            case .fetchPodcasts:
                print("fffffffff")
                return .run { send in
                    try await send(
                        .fetchPodcastsResponse(
                            self.podhubManager.getTrendingPodcasts()
                        )
                    )
                }
            case .fetchPodcastsResponse(let response):
                state.stats.fetchPodcastResponse(value: response)
                return .none
            case .path:
                return .none
            }
        }
    }
}

struct SharedStateFileStorageView: View {
    @Bindable var store: StoreOf<SharedStateFileStorage>
    var body: some View {
        ZStack(alignment: .top) {
            TabView(selection: $store.currentTab.sending(\.selectTab)) {
                HomeView(
                    store: store.scope(state: \.home, action: \.home)
                )
                .tag(SharedStateFileStorage.Tab.home)
                .tabItem {  Label("Home", systemImage: "house") }

                ExloreView(
                    store: store.scope(state: \.explore, action: \.explore)
                )
                .tag(SharedStateFileStorage.Tab.explore)
                .tabItem {  Label("Explore", systemImage: "magnifyingglass") }
            }
            .blur(
                radius: store.stats.isScreenLoading ? 5 : 0
            )
            if store.stats.isScreenLoading {
                ProgressView("Please wait")
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ZStack {
                    RoundedRectangle(cornerRadius: 32)
                        .fill(Color(red: 31/255, green: 31/255, blue: 31/255, opacity: 0.08))
                        .frame(width: 35, height: 35)
                    HStack {
                        Image(systemName: "person.fill")
                            .resizable()
                            .frame(width: 21, height: 21)
                    }
                }
            }
            ToolbarItem(placement: .topBarLeading) {
                ZStack {
                    RoundedRectangle(cornerRadius: 32)
                        .fill(Color(red: 31/255, green: 31/255, blue: 31/255, opacity: 0.08))
                        .frame(width: 35, height: 35)
                    HStack {
                        Image(systemName: "gear.circle.fill")
                            .resizable()
                            .frame(width: 21, height: 21)
                    }
                }
            }
        }
        .onAppear {
            store.send(.fetchPodcasts)
        }
    }
}

extension SharedStateFileStorage {
    @Reducer
    struct HomeTab: Sendable {
        @ObservableState
        struct State {
            @Shared(.stats) var stats = Stats()
            var path = StackState<Path.State>()
        }

        enum Action {
            case podcastTapped(Podcast)
            case path(StackActionOf<Path>)
        }

        @Reducer
        enum Destination {
            case showMorePodcasts(ShowMorePodcastFeature)
        }

        var body: some ReducerOf<Self> {
            Reduce { state, action in
                switch action {
                case .podcastTapped(let tappedPodcast):
                    state.stats = Stats()
                    state.path.append(.podcastDetails(PodcastDetailsFeature.State(podcast: tappedPodcast)))
                    return .none
                case .path:
                    return .none
                }
            }
            .forEach(\.path, action: \.path)
        }
    }
}

extension SharedStateFileStorage {
    @Reducer
    struct ExploreTab: Sendable {
        @ObservableState
        struct State {
            var path = StackState<Path.State>()
            @Presents var destination: Destination.State?
            @Shared(.stats) var stats = Stats()
        }

        @Reducer
        enum Path {
            case podcastDetails(PodcastDetailsFeature)
            case searchResults(ExploreSearchFeature)
        }

        @Reducer
        enum Destination {
            case showMorePodcasts(ShowMorePodcastFeature)
        }

        enum Action {
            case searchTermChanged(String)
        }

        var body: some Reducer<State, Action> {
            Reduce { state, action in
                switch action {
                case .searchTermChanged(let searchTerm):
                    state.stats.updateSearchTermOnChanged(value: searchTerm)
                    return .none
                }
            }
        }
    }
}

struct Stats: Codable, Equatable {
    private(set) var trendingPodcasts: PodHub?
    private(set) var selectedPodcast: Podcast?
    private(set) var selectedEpisode: Episode?
    private(set) var episodes: IdentifiedArrayOf<Episode>?
    private(set) var shownCellLimit = 10
    private(set) var searchTerm = ""
    private(set) var searchPodcastResults: PodHub?
    private(set) var isScreenLoading: Bool = false

    mutating func updateIsScreenLoading(value: Bool) {
        isScreenLoading = value
    }

    mutating func updateSearchTermOnChanged(value: String) {
        searchTerm = value
    }

    mutating func fetchPodcastResponse(value: PodHub?) {
        trendingPodcasts = value
    }

    mutating func selectedPodcast(value: Podcast?) {
        selectedPodcast = value
    }

    mutating func selectedEpisode(value: Episode?) {
        selectedEpisode = value
    }

    mutating func episodeList(value: IdentifiedArrayOf<Episode>?) {
        episodes = value
    }

    mutating func searchPodcastResult(value: PodHub?) {
        searchPodcastResults = value
    }
}

extension PersistenceReaderKey where Self == FileStorageKey<Stats> {
    static var stats: Self {
        fileStorage(.documentsDirectory.appending(component: "stats.json"))
    }
}
