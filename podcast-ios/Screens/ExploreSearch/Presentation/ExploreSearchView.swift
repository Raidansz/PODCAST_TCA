//
//  ExploreSearchView.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 10. 22..
//

import SwiftUI
import ComposableArchitecture

struct ExploreSearchView: View {
    @State var store: StoreOf<ExploreSearchFeature>
    var body: some View {
            ZStack(alignment: .top) {
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
                    // TODO: Pagination
                    LazyVStack(spacing: 24) {
                        if let list = store.searchResult?.podcasts {
                            ForEach(list, id: \.self) { response in
                                NavigationLink(
                                    state: ExploreFeature.Path.State.podcastDetails(PodcastDetailsFeature.State(podcast: response))
                                ) {
                                    ListViewCell(
                                        imageURL: response.image,
                                        author: response.author, title: response.title,
                                        isPodcast: true
                                    )
                                    .shadow(color: .black.opacity(0.2), radius: 10, x: 5, y: 5)
                                }
                            }
                        }
                    }
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
