//
//  HomeView.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 09. 20..
//

import SwiftUI
import ComposableArchitecture

struct HomeView: View {
    @Bindable var store: StoreOf<SharedStateFileStorage.HomeTab>
    var body: some View {
        NavigationStack( path: $store.scope(state: \.path, action: \.path)) {
        ScrollView {
            Section(content: {
                if let podcasts = store.stats.trendingPodcasts {
                    horizontalList(data: (podcasts.podcasts)) { podcast in
                        ListViewHero(imageURL: podcast.image ?? URL(string: "")!)
                            .frame(width: 350, height: 350)
                            .onTapGesture {
                                store.send(.podcastTapped(podcast))
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
                    if let podcasts = store.stats.trendingPodcasts?.podcasts {
                        ForEach(podcasts) { podcast in
                            ListViewCell(
                                imageURL: podcast.image,
                                author: podcast.author,
                                title: podcast.title,
                                isPodcast: true,
                                description: podcast.description
                            )
                            .shadow(color: .black.opacity(0.2), radius: 10, x: 5, y: 5)
                            .onTapGesture {
                                store.send(.podcastTapped(podcast))
                            }
                        }
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
            .padding(.horizontal, 16)
        }
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.large)
        } destination: { store in
            switch store.case {
            case .podcastDetails(let store):
                PodcastDetailsView(store: store)
        }
    }
    }
}
