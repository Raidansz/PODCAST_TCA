//
//  ExploreView.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 09. 24..
//

import SwiftUI
import ComposableArchitecture

struct ExloreView: View {
    @Bindable var store: StoreOf<ExploreFeature>
    var body: some View {
        NavigationStack( path: $store.scope(state: \.path, action: \.path)) {
            ZStack(alignment: .top) {
                ExploreViewContent(store: store)
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
                    .onTapGesture {
                        store.send(.settingsTapped)
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
            .navigationTitle("Explore")
            .navigationBarTitleDisplayMode(.large)
        } destination: { store in
            switch store.case {
            case .podcastDetails(let store):
                PodcastDetailsView(store: store)
            case .searchResults(let store):
                ExploreSearchView(store: store)
            }
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
        .sheet(
            item: $store.scope(
                state: \.destination?.settings,
                action: \.destination.settings
            )
        ) { store in
            NavigationStack {
                SettingsView(store: store)
            }
        }
        .onAppear {
            store.send(.fetchPodcasts)
        }
    }
}

struct ExploreViewContent: View {
    @Bindable var store: StoreOf<ExploreFeature>
    var body: some View {
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

            Section(content: {
                if (store.podcastsList?.podcasts) != nil {
                    horizontalList(data: (store.podcastsList!.podcasts)) { podcast in
                        ListViewHero(imageURL: podcast.image ?? URL(string: "")!)
                            .frame(width: 300, height: 300)
                            .onTapGesture {
                                store.send(.podcastDetailsTapped(podcast))
                            }
                    }
                }
            }, header: {
                HStack {
                    Text("Today’s Top 5 Podcasts")
                        .fontWeight(.semibold)
                    Spacer()
                }
                .padding(.horizontal, 16)
            })

            Section(content: {
                LazyVStack(spacing: 24) {
                    if store.podcastsList?.podcasts != nil {
                        ForEach((store.podcastsList!.podcasts), id: \.self) { response in
                            ListViewCell(
                                imageURL: response.image,
                                author: response.author, title: response.title,
                                isPodcast: true
                            )
                            .shadow(color: .black.opacity(0.2), radius: 10, x: 5, y: 5)
                            .onTapGesture {
                                store.send(.podcastDetailsTapped(response))
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
            }, header: {
                if (store.podcastsList?.podcasts) != nil {
                    horizontalList(data: (store.podcastsList!.podcasts)) { podcast in
                        CatagoriesView(label: podcast.title ?? "")
                    }
                }
            })
        }
    }
}

struct CatagoriesView: View {
    let label: String
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.blue)
            Text(label)
                .font(.headline)
                .foregroundColor(.black)
                .lineLimit(1)
        }
        .frame(width: 130, height: 56)
    }
}
