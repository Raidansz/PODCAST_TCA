//
//  HomeView.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 09. 20..
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct HomeFeature: Sendable {
    @ObservableState
    struct State {
        var trendingPodcasts: PodHub?
        var path = StackState<Path.State>()
        var isLoading: Bool = false
        let limit = 10
        @Presents var destination: Destination.State?
    }

    enum Action {
        case fetchTrendingPodcasts
        case loadView
        case trendingPodcastResponse(PodHub)
        case path(StackActionOf<Path>)
        case showMorePodcastsTapped
        case podcastDetailsTapped(Podcast)
        case destination(PresentationAction<Destination.Action>)
    }

    @Reducer
    enum Path {
        case podcastDetails(PodcastDetailsFeature)
    }

    @Reducer
    enum Destination {
        case showMorePodcasts(ShowMorePodcastFeature)
    }

    @Injected(\.podHubManager) private var podHubManager: PodHubManagerProtocol
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .fetchTrendingPodcasts:
                state.isLoading = true
                return .run { send in
                    try await send(
                        .trendingPodcastResponse(
                            self.podHubManager.searchFor(
                                searchFor: .podcast,
                                value: "morning",
                                limit: nil,
                                page: nil
                            )
                        )
                    )
                }
            case .trendingPodcastResponse(let result):
                state.trendingPodcasts = result
                state.isLoading = false
                return .none
            case .loadView:
                if state.trendingPodcasts != nil {
                    return .none
                }
                return .send(.fetchTrendingPodcasts)
            case .path:
                return .none
            case .destination:
                return .none
            case .showMorePodcastsTapped:
                guard let podcasts = state.trendingPodcasts else { return .none }
                if state.limit < podcasts.podcasts.count {
                    state.destination = .showMorePodcasts(ShowMorePodcastFeature.State(trendingPodcasts: podcasts))
                }
                return .none
            case .podcastDetailsTapped(let podcast):
                state.path.append(.podcastDetails(PodcastDetailsFeature.State(podcast: podcast)))
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
                ShowMorePodcastView(store: store)
            }
        }
    }
}

struct HomeViewContent: View {
    @State var store: StoreOf<HomeFeature>
    var body: some View {
        ScrollView {
            Section(content: {
                if let podcasts = store.trendingPodcasts {
                    horizontalList(data: (podcasts.podcasts.prefix(store.limit))) { podcast in
                        ListViewHero(imageURL: podcast.image ?? URL(string: "")!)
                            .frame(width: 350, height: 350)
                            .onTapGesture {
                                store.send(.podcastDetailsTapped(podcast))
                            }
                    }
                    .scrollTargetLayout()
                    .scrollTargetBehavior(.viewAligned)
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
                        ForEach(podcasts.prefix(store.limit), id: \.self) { podcast in
                            ListViewCell(podcast: podcast)
                                .shadow(color: .black.opacity(0.2), radius: 10, x: 5, y: 5)
                                .onTapGesture {
                                    store.send(.podcastDetailsTapped(podcast))
                                }
                        }
                    }
                }
            }, header: {
                HStack {
                    Text("Trending Podcasts")
                        .fontWeight(.semibold)
                    Spacer()
                    if store.trendingPodcasts?.podcasts.count ?? 0 > store.limit {
                        Button {
                            store.send(.showMorePodcastsTapped)
                        } label: {
                            Text("See more..")
                                .foregroundStyle(Color(.blue))
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            )
            .padding(.horizontal, 16)
        }
    }
}
