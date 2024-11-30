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
                if store.isLoading {
                    ProgressView("Please wait")
                        .progressViewStyle(CircularProgressViewStyle(tint: .secondary))
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
    }
}

struct HomeViewContent: View {
    @State var store: StoreOf<HomeFeature>
    var body: some View {
        ScrollView {
            Section(content: {
                if let podcasts = store.podcasts {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(podcasts) { podcast in
                                ListViewHero(imageURL: podcast.image ?? URL(string: ""), title: podcast.title)
                                    .frame(width: 150, height: 150)
                                    .onTapGesture {
                                        store.send(.podcastDetailsTapped(podcast))
                                    }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }, header: {
                HStack {
                    Text("Trending in your area")
                        .fontWeight(.semibold)
                    Spacer()
                }
                .padding(.horizontal, 16)
            }
            )

            Section(content: {
                LazyVStack(spacing: 24) {
                    if let podcasts = store.podcasts {
                        ForEach(podcasts) { podcast in
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
                    Spacer()
                }
                .padding(.horizontal, 16)
            }
            )
            .padding(.horizontal, 16)
        }
    }
}
