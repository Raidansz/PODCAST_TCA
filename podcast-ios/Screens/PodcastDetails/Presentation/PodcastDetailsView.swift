//
//  PodcastDetailsView.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 10. 07..
//

import SwiftUI
import ComposableArchitecture

struct PodcastDetailsView: View {
    @State var store: StoreOf<PodcastDetailsFeature>
    var body: some View {
            ZStack(alignment: .top) {
                ScrollView {
                    // TODO: Pagination
                    Section(content: {
                        LazyVStack(spacing: 24) {
                            if (store.episodes) != nil {
                                ForEach((store.episodes!), id: \.self) { response in
                                    ListViewCell(
                                        imageURL: response.imageUrl,
                                        author: response.author, title: response.title,
                                        isPodcast: false,
                                        description: response.description
                                    )
                                        .shadow(color: .black.opacity(0.2), radius: 10, x: 5, y: 5)
                                        .onTapGesture {
                                            store.send(.cellTapped(response))
                                        }
                                }
                            }
                        }
                    }, header: {
                        ListViewHero(imageURL: store.podcast.image ?? URL(string: ""))
                            .frame(width: 380, height: 380)
                            .padding(.bottom, 20)
                    })
                    .padding(.horizontal, 16)
                }
                .blur(
                    radius: store.isLoading ? 5 : 0
                )
                if store.isLoading {
                    ProgressView("Please wait")
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        .onAppear {
            store.send(.fetchEpisode)
        }
        .sheet(
            store: self.store.scope(
                state: \.$playEpisode,
                action: \.playEpisode
            )
        ) { store in
            NavigationStack {
                PlayerView(store: store)
                    .navigationTitle(store.runningItem.episode?.title ?? "Player")
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}
