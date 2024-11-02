//
//  HomeView.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 09. 20..
//

import SwiftUI
import ComposableArchitecture
import Kingfisher
import AVFoundation

@Reducer
struct HomeFeature: Sendable {
    @ObservableState
    struct State {
        var trendingPodcasts: PodHub?
        var path = StackState<Path.State>()
        var isLoading: Bool = false
        let limit = 10
        @Presents var destination: Destination.State?
        let uuid = UUID()
    }

    enum Action {
        case fetchTrendingPodcasts
        case loadView
        case trendingPodcastResponse(PodHub)
        case showMorePodcastsTapped
        case path(StackActionOf<Path>)
        case podcastDetailsTapped(Podcast)
        case destination(PresentationAction<Destination.Action>)
        case resetPagination
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
                return .run {[limit = state.limit, id = state.uuid] send in
                    try await send(
                        .trendingPodcastResponse(
                            self.podHubManager.getTrendingPodcasts()
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
            case .resetPagination:
                let podcasts = state.trendingPodcasts?.podcasts
                guard let podcasts else { return .none }
                state.trendingPodcasts?.podcasts = IdentifiedArray(uniqueElements: Array(podcasts.prefix(5)))
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
import AVFoundation
struct HomeViewContent: View {


    func clearAllAppCache() {
        // Clear URLCache
        URLCache.shared.removeAllCachedResponses()
        print("URL cache cleared")
        
        // Clear temporary files
        let tempDirectory = FileManager.default.temporaryDirectory
        do {
            let tempFiles = try FileManager.default.contentsOfDirectory(at: tempDirectory, includingPropertiesForKeys: nil)
            for file in tempFiles {
                try FileManager.default.removeItem(at: file)
            }
            print("Temporary files cleared")
        } catch {
            print("Error clearing temporary files: \(error.localizedDescription)")
        }
        
        // Clear files in Documents directory
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        do {
            let documentFiles = try FileManager.default.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
            for file in documentFiles {
                try FileManager.default.removeItem(at: file)
            }
            print("Documents directory cleared")
        } catch {
            print("Error clearing documents directory: \(error.localizedDescription)")
        }
        
        // Clear AVPlayer download tasks using a background session
        let backgroundConfig = URLSessionConfiguration.background(withIdentifier: "com.yourApp.downloadSession")
        let downloadSession = AVAssetDownloadURLSession(configuration: backgroundConfig, assetDownloadDelegate: nil, delegateQueue: .main)
        downloadSession.getAllTasks { tasks in
            for task in tasks {
                task.cancel()
            }
            print("AVPlayer download tasks cleared")
        }
        
        // Provide user feedback that cache was cleared
        showCacheClearedAlert()
    }

    func showCacheClearedAlert() {
        // Display a simple alert to inform the user that cache was cleared.
        // Note: This function requires being inside a view controller.
        let alert = UIAlertController(title: "Cache Cleared", message: "All cached data has been removed.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        // Assuming this function is called within a view controller
        if let topController = UIApplication.shared.keyWindow?.rootViewController {
            topController.present(alert, animated: true, completion: nil)
        }
    }

    
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
                            clearAllAppCache()
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
