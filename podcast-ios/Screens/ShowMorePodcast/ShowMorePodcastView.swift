//
//  ShowMorePodcastView.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 10. 12..
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct ShowMorePodcastFeature {
    @Injected(\.podHubManager) private var podHubManager: PodHubManagerProtocol
    @ObservableState
    struct State {
        var trendingPodcasts: PodHub
        var isLoading: Bool = false
    }
    @Reducer
    enum Path {
        case podcastDetails(PodcastDetailsFeature)
    }
}

struct ShowMorePodcastView: View {
    @Bindable var store: StoreOf<ShowMorePodcastFeature>
    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(store.trendingPodcasts.podcasts) { podcast in
                    ListViewCell(
                        imageURL: podcast.image,
                        author: podcast.author, title: podcast.title,
                        isPodcast: true
                    )
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 5, y: 5)
                }
            }
            .padding(.horizontal, 16)
        }
        .navigationTitle("Top Podcasts")
    }
}