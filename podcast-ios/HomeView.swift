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
        var trendingPodcasts: [PodcastIndexResponse]?
        var promotedPodcasts: [SearchResult] = []
        var searchPodcastResults: [SearchResults]?
        var isLoading: Bool = false
        var searchTerm = ""
    }

    enum Action: Equatable {
        case podcastSearchResponse(SearchResults)
        case searchForPodcastTapped(with: String)
        case searchTermChanged(String)
        case fetchTrendingPodcasts
        case trendingPodcastResponse(PodcastIndexResponse)
    }

    @Injected(\.itunesManager) private var itunesManager: ItunesManagerProtocol
    @Injected(\.podcastIndexManager) private var podcastIndexManager: PodcastIndexManagerProtocol

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .podcastSearchResponse(let result):
                state.searchPodcastResults = [result]
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
                state.trendingPodcasts = [result]
                state.isLoading = false
                return .none
            }
        }
    }
}

struct HomeView: View {
    @Bindable var store: StoreOf<HomeFeature>

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    HStack {
                        Image(systemName: "music.mic.circle.fill")
                            .resizable()
                            .frame(width: 45, height: 45)
                        Spacer()
                        ZStack {
                            RoundedRectangle(cornerRadius: 32)
                                .fill(Color(red: 31/255, green: 31/255, blue: 31/255, opacity: 0.08))
                                .frame(width: 45, height: 45)
                            HStack {
                                Image(systemName: "bell.fill")
                                    .resizable()
                                    .frame(width: 21, height: 21)
                            }
                        }
                    }
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
                        horizontalList(data: [1, 2, 3, 4, 5]) { _ in
                            ListViewHero()
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
                            ForEach(0..<6) { _ in
                                ListViewCell()
                            }
                        }
                    }, header: {
                        HStack {
                            Text("Trending Podcasts")
                                .fontWeight(.semibold)
                            Spacer()
                            Text("See more..")
                                .foregroundStyle(Color(.blue))
                        }
                        .padding(.horizontal, 16)
                    }
                    )
                }
                .padding(.horizontal, 16)
            }
        }
    }
}
