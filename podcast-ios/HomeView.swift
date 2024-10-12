//
//  HomeView.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 09. 20..
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct HomeFeature {
    @ObservableState
    struct State {
        var trendingPodcasts: PodHub?
        var searchPodcastResults: PodHub?
        var path = StackState<Path.State>()
        var isLoading: Bool = false
        var searchTerm = ""
        let limit = 10
        @Presents var destination: Destination.State?
        var currentPage = 1
    }

    enum Action {
        case podcastSearchResponse(PodHub)
        case searchForPodcastTapped(with: String)
        case searchTermChanged(String)
        case fetchTrendingPodcasts
        case loadView
        case trendingPodcastResponse(PodHub)
        case path(StackActionOf<Path>)
        case updateCurrentPage
        case showMorePodcastsTapped
        case destination(PresentationAction<Destination.Action>)
    }

    @Reducer
    enum Path {
        case podcastDetails(PodcastDetailsFeature)
    }

    @Reducer
    enum Destination {
        case showMorePodcasts(PodcastDetailsFeature)
    }

    @Injected(\.podHubManager) private var podHubManager: PodHubManagerProtocol
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .podcastSearchResponse(let result):
                state.searchPodcastResults = result
                state.isLoading = false
                return .none
            case .searchForPodcastTapped(with: let term):
                state.searchPodcastResults = nil
                state.isLoading = true
                return .run { [state = state] send in
                    try await send(
                        .podcastSearchResponse(
                            self.podHubManager.searchFor(
                                searchFor: .podcast,
                                value: term,
                                limit: state.limit,
                                page: state.currentPage
                            )
                        )
                    )
                }
            case .searchTermChanged(let searchTerm):
                state.searchTerm = searchTerm
                return .none
            case .fetchTrendingPodcasts:
                state.isLoading = true
                return .run { [state] send in
                    try await send(
                        .trendingPodcastResponse(
                            self.podHubManager.searchFor(
                                searchFor: .podcast,
                                value: "morning",
                                limit: state.limit,
                                page: state.currentPage
                            )
                        )
                    )
                }
            case .trendingPodcastResponse(let result):
                if let localPodcastList = state.trendingPodcasts {
                    if localPodcastList.podcasts.count < localPodcastList.totalCount {
                        state.trendingPodcasts!.podcasts.append(contentsOf: result.podcasts)
                    }
                } else {
                    state.trendingPodcasts = result
                }
                state.isLoading = false
                return .send(.updateCurrentPage)
            case .loadView:
                state.currentPage = 1
                return .send(.fetchTrendingPodcasts)
            case .path:
                return .none
            case .updateCurrentPage:
                guard let podcastList = state.trendingPodcasts else { return .none }
                let podcastListTotalCount = podcastList.totalCount
                if podcastList.podcasts.count < podcastListTotalCount {
                    state.currentPage += 1
                }
                return .none
            case .destination:
                return .none
            case .showMorePodcastsTapped:
                state.destination = .showMorePodcasts(
                    PodcastDetailsFeature.State(podcast: state.trendingPodcasts!.podcasts.first!)
                )
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
        .forEach(\.path, action: \.path)
    }
}

struct HomeView: View {
    @Bindable var store: StoreOf<HomeFeature>
    var body: some View {
        NavigationStack( path: $store.scope(state: \.path, action: \.path)) {
            ZStack(alignment: .top) {
                HomeViewContent(store: store)
                    .blur(
                        radius: store.isLoading ? 5 : 0
                    )
                if store.isLoading {
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
                            Image(systemName: "bell.fill")
                                .resizable()
                                .frame(width: 21, height: 21)
                        }
                    }
                }
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
        } destination: { store in
            switch store.case {
            case .podcastDetails(let store):
                PodcastDetailsView(store: store)
            }
        }
        .onAppear {
            store.send(.loadView)
        }
        .sheet(
            item: $store.scope(
                state: \.destination?.showMorePodcasts,
                action: \.destination.showMorePodcasts
            )
        ) { store in
            NavigationStack {
                PodcastDetailsView(store: store)
            }
        }
    }
}

struct HomeViewContent: View {
    @State var store: StoreOf<HomeFeature>
    var body: some View {
        ScrollView {
            ZStack {
                RoundedRectangle(cornerRadius: 32)
                    .fill(Color(red: 31/255, green: 31/255, blue: 31/255, opacity: 0.08))
                    .frame(width: 364, height: 64)
                HStack {
                    Image(systemName: "magnifyingglass")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.black)
                        .padding(.leading, 15)
                    TextField(
                        "Search the podcast here...",
                        text: $store.searchTerm.sending(\.searchTermChanged)
                    )
                    .padding(.leading, 5)
                    .onSubmit {
                        store.send(.searchForPodcastTapped(with: store.searchTerm))
                    }
                }
                .frame(width: 364, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 32))
            }
            .padding()
            Section(content: {
                if (store.trendingPodcasts?.podcasts) != nil {
                    horizontalList(data: (store.trendingPodcasts!.podcasts)) { podcast in
                        ListViewHero(imageURL: podcast.image ?? URL(string: "")!)
                            .frame(width: 300, height: 300)
                    }
                }
            }, header: {
                HStack {
                    Text("Trending Podcasts")
                        .fontWeight(.semibold)
                    Spacer()
                }
                .padding(.horizontal, 16)
            }
            )

            Spacer()
                .frame(height: 32)

            Section(content: {
                LazyVStack(spacing: 24) {
                    if let podcasts = store.trendingPodcasts?.podcasts {
                        ForEach(podcasts, id: \.self) { podcast in
                            NavigationLink(
                                state: HomeFeature.Path.State.podcastDetails(
                                    PodcastDetailsFeature.State(podcast: podcast)
                                )
                            ) {
                                ListViewCell(podcast: podcast)
                                    .shadow(color: .black.opacity(0.2), radius: 10, x: 5, y: 5)
                            }
                            .onAppear {
                                if podcast == podcasts.last {
                                    store.send(.fetchTrendingPodcasts)
                                }
                            }
                        }
                    }
                }
            }, header: {
                HStack {
                    Text("Trending Podcasts")
                        .fontWeight(.semibold)
                    Spacer()
                    Button {
                        store.send(.showMorePodcastsTapped)
                    } label: {
                        Text("See more..")
                            .foregroundStyle(Color(.blue))
                    }
                }
                .padding(.horizontal, 16)
            }
            )
            .padding(.horizontal, 16)
        }
    }
}
