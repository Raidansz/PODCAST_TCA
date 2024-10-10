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
    struct State: Equatable {
        var trendingPodcasts: PodHub?
        var searchPodcastResults: PodHub?
        @Presents var podcastDetails: PodcastDetailsFeature.State?
        var isLoading: Bool = false
        var searchTerm = ""
        let limit = 10
        var currentPage = 1
        var totalCount: Int?
    }

    enum Action: Equatable {
        case podcastSearchResponse(PodHub)
        case searchForPodcastTapped(with: String)
        case searchTermChanged(String)
        case fetchTrendingPodcasts
        case loadView
        case trendingPodcastResponse(PodHub)
        case cellTapped(Podcast)
        case podcastDetails(PresentationAction<PodcastDetailsFeature.Action>)
        case updateCurrentPage
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
                            self.podHubManager.searchFor(searchFor: .podcast, value: term, limit: state.limit, page: state.currentPage)
                        )
                    )
                }
            case .searchTermChanged(let searchTerm):
                state.searchTerm = searchTerm
                return .none
            case .fetchTrendingPodcasts:
                state.isLoading = true
                return .run { [state = state] send in
                    try await send(
                        .trendingPodcastResponse(
                            self.podHubManager.searchFor(searchFor: .podcast, value: "morning", limit: state.limit, page: state.currentPage)
                        )
                    )
                }
            case .trendingPodcastResponse(let result):
                if state.trendingPodcasts != nil, state.totalCount != nil {
                    if state.totalCount! > (state.trendingPodcasts?.podcasts.count)! {
                        state.trendingPodcasts!.podcasts.append(contentsOf: result.podcasts)
                    }
                } else {
                    state.trendingPodcasts = result
                    state.totalCount = result.podcasts.count
                }
                state.isLoading = false
                return .send(.updateCurrentPage)
            case .loadView:
                state.currentPage = 1
                let itemsLimit = state.limit
                if state.trendingPodcasts != nil {
                    if let podcasts = state.trendingPodcasts?.podcasts {
                        state.trendingPodcasts?.podcasts = IdentifiedArray(podcasts.prefix(itemsLimit))
                    }
                    return .none
                }
                return .send(.fetchTrendingPodcasts)
            case .cellTapped(let podcast):
                state.podcastDetails = PodcastDetailsFeature.State(podcast: podcast)
                return .none
            case .podcastDetails:
                return .none
            case .updateCurrentPage:
                guard let totalCount = state.totalCount else { return .none }
                guard let podcastList = state.trendingPodcasts?.podcasts else { return .none }
                if totalCount > podcastList.count {
                    state.currentPage += 1
                }
                return .none
            }
        }
        .ifLet(\.$podcastDetails, action: \.podcastDetails) {
            PodcastDetailsFeature()
        }
    }
}

struct HomeView: View {
    @State var store: StoreOf<HomeFeature>
    var body: some View {
        NavigationStack {
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
        }
        .onAppear {
            store.send(.loadView)
        }
        .sheet(
            store: self.store.scope(
                state: \.$podcastDetails,
                action: \.podcastDetails
            )
        ) { store in
            NavigationStack {
                PodcastDetailsView(store: store)
                    .navigationTitle(store.podcast.title ?? "")
                    .navigationBarTitleDisplayMode(.inline)
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
                            .frame(width: 300,height: 300)
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
                            ListViewCell(podcast: podcast)
                                .shadow(color: .black.opacity(0.2), radius: 10, x: 5, y: 5)
                                .onTapGesture {
                                    store.send(.cellTapped(podcast))
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
                       // store.send(.playAudioTapped)
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
