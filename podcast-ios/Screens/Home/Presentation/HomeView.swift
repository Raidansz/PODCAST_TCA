//
//  HomeView.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 11. 02..
//
import SwiftUI
import ComposableArchitecture

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
                        ListViewHero(imageURL: podcast.image ?? URL(string: ""))
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
                        ForEach(Array(podcasts.enumerated()), id: \.element) { index, podcast in
                            ListViewCell(
                                imageURL: podcast.image,
                                author: podcast.author,
                                title: podcast.title,
                                isPodcast: true
                            )
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
                            ()
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