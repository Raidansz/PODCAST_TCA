//
//  HomeView.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 09. 20..
//

import SwiftUI
import ComposableArchitecture

struct HomeFeature: Reducer {
    struct State: Equatable {
        var trendingPodcasts: [SearchResult] = []
        var promotedPodcasts: [SearchResult] = []
        var searchPodcastResults: [SearchResults]?
        var isLoading: Bool = false
        var searchTerm = ""
    }

    enum Action: Equatable {
        case podcastSearchResponse(SearchResults)
        case searchForPodcastTapped(with: String)
        case searchTermChange(String)
    }
    @Injected(\.itunesManager) private var itunesManager: ItunesManagerProtocol
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
                    try await send(.podcastSearchResponse(self.itunesManager.searchPodcasts(term: term, entity: .podcastAndEpisode)))
                }
            case .searchTermChange(let searchTerm):
                state.searchTerm = searchTerm
                return .none
            }
        }
    }
}

struct HomeView: View {
    let store: StoreOf<HomeFeature>
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
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
                        .padding(.horizontal, 16)
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
                                TextField("Search the podcast here...", text: viewStore.binding(
                                    get: { $0.searchTerm },
                                    send: HomeFeature.Action.searchTermChange)
                                )
                                .padding(.leading, 5)
                                .onSubmit {
                                    viewStore.send(.searchForPodcastTapped(with: viewStore.searchTerm))
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
                        Section(content: {
                            LazyVStack(spacing: 10) {
                                ForEach(0..<6) { _ in
                                    ListViewCell()
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .padding(.horizontal, 16)
                        }, header: {
                            HStack {
                                Text("Trending Podcasts")
                                    .fontWeight(.semibold)
                                Spacer()
                                Button {
                                    viewStore.send(.searchForPodcastTapped(with: "hello"))
                                } label: {
                                    Text("See more..")
                                        .foregroundStyle(Color(.blue))
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        )
                    }
                }
            }
        }
    }
}
