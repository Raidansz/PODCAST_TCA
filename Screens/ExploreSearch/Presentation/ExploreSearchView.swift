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
                ExploreSearchListView(store: store, shouldShowSegmentView: true)
                if store.isLoading {
                    ProgressView("Please wait")
                        .progressViewStyle(CircularProgressViewStyle(tint: .secondary))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Search")
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
}

struct ExploreSearchListView: View {
    @Bindable var store: StoreOf<ExploreSearchFeature>
    @FocusState private var isSearching: Bool
    @State private var activeTab: Tab = .all
    @Environment(\.colorScheme) private var scheme
    @Namespace private var animation
    @State var shouldShowSegmentView: Bool
    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 15) {
                ExploreSearchContent(store: store)
                    .blur(
                        radius: isSearching ? 5 : 0
                    )
                    .disabled(isSearching)
            }
            .safeAreaPadding(15)
            .safeAreaInset(edge: .top, spacing: 0) {
                expandableNavigationBar()
            }
            .animation(.snappy(duration: 0.3, extraBounce: 0), value: isSearching)
        }
        .scrollTargetBehavior(CustomScrollTargetBehaviour())
        .background(.background)
        .contentMargins(.top, 190, for: .scrollIndicators)
    }

    /// Expandable Navigation Bar
    @ViewBuilder
    func expandableNavigationBar() -> some View {
        GeometryReader { proxy in
            let minY = proxy.frame(in: .scrollView(axis: .vertical)).minY
            let scrollviewHeight = proxy.bounds(of: .scrollView(axis: .vertical))?.height ?? 0
            let scaleProgress = minY > 0 ? 1 + (max(min(minY / scrollviewHeight, 1), 0) * 0.5) : 1
            let progress = isSearching ? 1 : max(min(-minY / 70, 1), 0)

            VStack(spacing: 10) {
                /// Search Bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.title3)

                    TextField("Search Podcasts or Episodes", text: $store.searchTerm.sending(\.searchTermChanged))
                        .focused($isSearching)
                        .onSubmit {
                            store.send(.searchForPodcastTapped(with: store.searchTerm, activeTab: activeTab))
                        }

                    if isSearching {
                        Button(action: {
                            isSearching = false
                        }, label: {
                            Image(systemName: "xmark")
                                .font(.title3)
                        })
                        .transition(.asymmetric(insertion: .push(from: .bottom), removal: .push(from: .top)))
                    }
                }
                .foregroundStyle(Color.primary)
                .padding(.vertical, 10)
                .padding(.horizontal, 15 - (progress * 15))
                .frame(height: 45)
                .clipShape(.capsule)
                .background {
                    RoundedRectangle(cornerRadius: 25 - (progress * 25))
                        .fill((scheme == .dark ? Color.customGray : .gray.opacity(0.15)))
                        .shadow(color: .gray.opacity(0.25), radius: 5, x: 0, y: 5)
                        .padding(.top, -progress * 190)
                        .padding(.bottom, shouldShowSegmentView ? -progress * 65 : 0)
                        .padding(.horizontal, -progress * 15)
                }

                if shouldShowSegmentView {
                    ScrollView(.horizontal) {
                        HStack(spacing: 12) {
                            ForEach(Tab.allCases, id: \.rawValue) { tab in
                                Button {
                                    withAnimation(.snappy) {
                                        activeTab = tab
                                    }
                                    store.send(.searchForPodcastTapped(with: store.searchTerm, activeTab: tab))
                                } label: {
                                    Text(tab.rawValue)
                                        .font(.callout)
                                        .foregroundStyle(
                                            activeTab == tab ? (scheme == .dark ? .black : .white) : Color.primary)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 15)
                                        .background {
                                            if activeTab == tab {
                                                Capsule()
                                                    .fill(Color.primary)
                                                    .matchedGeometryEffect(id: "ACTIVETAB", in: animation)
                                            } else {
                                                Capsule()
                                                    .fill(.background)
                                            }
                                        }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .frame(height: 50)
                }
            }
            .padding(.top, 25)
            .safeAreaPadding(.horizontal, 15)
            .offset(y: minY < 0 || isSearching ? -minY : 0)
            .offset(y: -progress * 65)
        }
        .frame(height: 140)
        .padding(.bottom, 10)
        .padding(.bottom, isSearching ? -65 : 0)
    }
}

struct ExploreSearchContent: View {
    @State var store: StoreOf<ExploreSearchFeature>
    var body: some View {
        LazyVStack(spacing: 24) {
            if let list = store.searchResult?.podcastList {
                ForEach(list) { response in
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
    }
}
