//
//  ExploreView.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 09. 24..
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct ExploreFeature {
    @ObservableState
    struct State: Equatable {
        var podcastsList: PodHub?
        var isLoading: Bool = false
        var selectedPodcast: Item?
    }

    enum Action: Equatable {
        case fetchPodcasts
        case fetchPodcastsResponse(PodHub)
        case podcastCellTapped(Item)
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
                            self.podHubManager.searchFor(searchFor: .podcast, value: "hee", limit: 4, page: 1)
                        )
                    )
                }
            case .fetchPodcastsResponse(let response):
                state.isLoading = false
                state.podcastsList = response
                return .none
            case .podcastCellTapped(let podcast):
                state.selectedPodcast = nil
                state.selectedPodcast = podcast
                return .none
            }
        }
    }
}

struct ExloreView: View {
    var store: StoreOf<ExploreFeature>
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                ExploreViewContent(store: store)
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
            .navigationTitle("Explore")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            store.send(.fetchPodcasts)
        }
    }
}

struct ExploreViewContent: View {
    var store: StoreOf<ExploreFeature>
    var body: some View {
        ScrollView {
            Section(content: {
                if (store.podcastsList?.podcasts) != nil {
                    horizontalList(data: (store.podcastsList!.podcasts)) { podcast in
                        ListViewHero(imageURL: podcast.image ?? URL(string: "")!)
                            .frame(width: 300,height: 300)
                    }
                }
            }, header: {
                HStack {
                    Text("Today’s Top 5 Podcasts")
                        .fontWeight(.semibold)
                    Spacer()
                }
                .padding(.horizontal, 16)
            })

            Section(content: {
                LazyVStack(spacing: 24) {
                    if((store.podcastsList?.podcasts) != nil) {
                        ForEach((store.podcastsList!.podcasts), id: \.self) { response in
                            ListViewCell(podcast: response)
                                .shadow(color: .black.opacity(0.2), radius: 10, x: 5, y: 5)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }, header: {
                if (store.podcastsList?.podcasts) != nil {
                    horizontalList(data: (store.podcastsList!.podcasts)) { podcast in
                        CatagoriesView(label: podcast.title ?? "")
                    }
                }
            })
        }
    }
}

struct CatagoriesView: View {
    let label: String
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.blue)
            Text(label)
                .font(.headline)
                .foregroundColor(.black)
                .lineLimit(1)
        }
        .frame(width: 130, height: 56)
    }
}
