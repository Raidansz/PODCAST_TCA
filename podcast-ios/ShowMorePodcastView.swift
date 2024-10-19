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
    @ObservableState
    struct State {
        var trendingPodcasts: PodHub
        var isLoading: Bool = false
    }

    enum Action {

    }

    @Reducer
    enum Path {
        case podcastDetails(PodcastDetailsFeature)
    }

    @Injected(\.podHubManager) private var podHubManager: PodHubManagerProtocol
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            default:
                return .none
            }
        }
    }
}

struct ShowMorePodcastView: View {
    @Bindable var store: StoreOf<ShowMorePodcastFeature>
    var body: some View {
        ScrollView {
        LazyVStack {
            ForEach(store.trendingPodcasts.podcasts) { podcast in
                    ListViewCell(podcast: podcast)
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 5, y: 5)
                }
        }
        .padding(.horizontal, 16)
        }
        .navigationTitle("Top Podcasts")
    }
}
