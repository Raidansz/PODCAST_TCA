//
//  CategoryDetailsView.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 11. 05..
//

import SwiftUI
import ComposableArchitecture

struct CategoryDetailsView: View {
    @State var store: StoreOf<CategoryDetailsFeature>
    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                LazyVStack(spacing: 24) {
                    if let podcastList = store.podcastList?.podcasts {
                        ForEach(podcastList, id: \.self) { podcast in
                            NavigationLink(state: ExploreFeature.Path.State.podcastDetails(PodcastDetailsFeature.State(podcast: podcast))) {
                                ListViewCell(
                                    imageURL: podcast.image,
                                    author: podcast.author,
                                    title: podcast.title,
                                    isPodcast: true,
                                    description: podcast.publicationDate?.formatted(.dateTime)
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
        .onAppear {
            store.send(.fetchPodcastList(for: store.category))
        }
    }
}