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
        var trendingPodcasts: PodcastIndexResponse?
//        var promotedPodcasts: IdentifiedArrayOf<SearchResult> = []
        var searchPodcastResults: SearchResults? // IdentifiedArrayOf<SearchResults> = []
        @Presents var playAudio: PlayerFeature.State?
        var isLoading: Bool = false
        var searchTerm = ""
    }

    enum Action: Equatable {
        case podcastSearchResponse(SearchResults)
        case searchForPodcastTapped(with: String)
        case searchTermChanged(String)
        case fetchTrendingPodcasts
        case loadView
        case trendingPodcastResponse(PodcastIndexResponse)
        case playAudioTapped
        case playAudio(PresentationAction<PlayerFeature.Action>)
    }

    @Injected(\.itunesManager) private var itunesManager: ItunesManagerProtocol
    @Injected(\.podcastIndexManager) private var podcastIndexManager: PodcastIndexManagerProtocol

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .podcastSearchResponse(let result):
                state.searchPodcastResults = result
                state.isLoading = false
                return .none
            case .searchForPodcastTapped(with: let term):
                print(term)
                state.searchPodcastResults = nil
                state.isLoading = true
                return .run {  send in
                    try await send(
                        .podcastSearchResponse(
                            self.itunesManager.searchPodcasts(
                                term: term,
                                entity: .podcastAndEpisode
                            )
                        )
                    )
                }
            case .searchTermChanged(let searchTerm):
                state.searchTerm = searchTerm
                return .none
            case .fetchTrendingPodcasts:
                state.trendingPodcasts = nil
                state.isLoading = true
                return .run {  send in
                    try await send(
                        .trendingPodcastResponse(
                            self.podcastIndexManager.getTrending()
                        )
                    )
                }
            case .trendingPodcastResponse(let result):
                state.trendingPodcasts = result
                state.isLoading = false
                return .none
            case .loadView:
                return .send(.fetchTrendingPodcasts)
            case .playAudioTapped:
                state.playAudio = PlayerFeature.State(podcast: state.trendingPodcasts!.items.first!)
                return .none
            case .playAudio:
                return .none
            }
        }
        .ifLet(\.$playAudio, action: /Action.playAudio){
            PlayerFeature()
        }
    }
}

struct HomeView: View {
    @State var store: StoreOf<HomeFeature>
    var body: some View {
       // NavigationStack {
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
       // }
        .onAppear {
            store.send(.loadView)
        }
        .sheet(
          store: self.store.scope(
            state: \.$playAudio,
            action: { .playAudio($0) }
          )
        ) { store in
          NavigationStack {
              PlayerView(store: store)
              .navigationTitle("Player")
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
                    if (store.trendingPodcasts?.items) != nil {
                        horizontalList(data: (store.trendingPodcasts!.items)) { podcast in
                        ListViewHero(podcast: podcast)
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
                        if (store.trendingPodcasts?.items) != nil {
                            ForEach((store.trendingPodcasts!.items), id: \.self) { response in
                                ListViewCell(podcast: response)
                                    .shadow(color: .black.opacity(0.2), radius: 10, x: 5, y: 5)
                            }
                        }
                    }
                }, header: {
                    HStack {
                        Text("Trending Podcasts")
                            .fontWeight(.semibold)
                        Spacer()
                        Button {
                            store.send(.playAudioTapped)
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
