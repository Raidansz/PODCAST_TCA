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
                ExploreViewContent(podcastList: store.podcastsList?.podcasts)
                    .blur(
                        radius: store.isLoading ? 5 : 0
                    )
                if store.isLoading {
                    ProgressView("Please wait")
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
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
    var podcastList: IdentifiedArrayOf<Podcast>?
    var coordinator: UICoordinator = .init()
    var body: some View {
        VStack {
            if (podcastList) != nil {
                ScrollView(.vertical) {
                    Rectangle()
                        .foregroundStyle(.red)
                        .frame(width: 400, height: 800)
                    LazyVStack(alignment: .leading, spacing: 15) {
                        LazyVGrid(columns: Array(repeating: GridItem(spacing: 10), count: 2), spacing: 10) {
                            ForEach(podcastList!) { post in
                                podcastCardView(post)
                            }
                        }
                    }
                    .padding(15)
                    .background(ScrollViewExtractor {
                        coordinator.scrollView = $0
                    })
                }
                .opacity(coordinator.hideRootView ? 0 : 1)
                .scrollDisabled(coordinator.hideRootView)
                .allowsHitTesting(!coordinator.hideRootView)
                .overlay {
                    GeometryReader {
                        let size = $0.size
                        let animateView = coordinator.animateView
                        let hideLayer = coordinator.hideLayer
                        let rect = coordinator.rect

                        let anchorX = (coordinator.rect.minX / size.width) > 0.5 ? 1.0 : ((coordinator.rect.minX / size.width) > 0.25 ? 0.5 : 0.0)

                        let scale = size.width / coordinator.rect.width
                        let offsetX = animateView && anchorX != 0.5 ? (anchorX > 0.5 ? 15 : -15) * scale : 0
                        let offsetY = animateView ? -coordinator.rect.minY * scale : 0

                        let detailHeight: CGFloat = rect.height * scale
                        let scrollContentHeight: CGFloat = size.height - detailHeight

                        if let image = coordinator.animationLayer, let post = coordinator.selectedItem {

                            if !hideLayer {
                                Image(uiImage: image)
                                    .scaleEffect(animateView ? scale : 1, anchor: .init(x: anchorX, y: 0))
                                    .offset(x: offsetX, y: offsetY)
                                    .offset(y: animateView ? -coordinator.headerOffset : 0)
                                    .opacity(animateView ? 0 : 1)
                                    .transition(.identity)
                            }
                            ScrollView(.vertical) {
                                ListViewCell(imageURL: coordinator.selectedItem?.image, author: coordinator.selectedItem?.author, title: coordinator.selectedItem?.title, isPodcast: false)
                                    .safeAreaInset(edge: .top, spacing: 0) {
                                        Rectangle()
                                            .fill(.clear)
                                            .frame(height: detailHeight)
                                            .offsetY { offset in
                                                coordinator.headerOffset = max(min(-offset, detailHeight), 0)
                                            }
                                    }
                            }
                            .scrollDisabled(!hideLayer)
                            .contentMargins(.top, detailHeight, for: .scrollIndicators)
                            .background {
                                Rectangle()
                                    .fill(.background)
                                    .padding(.top, detailHeight - coordinator.headerOffset)
                            }
                            .animation(.easeInOut(duration: 0.3).speed(1.5)) {
                                $0
                                    .offset(y: animateView ? 0 : scrollContentHeight)
                                    .opacity(animateView ? 1 : 0)
                            }
   
                            PodcastCardImageView(post: post)
                                .allowsHitTesting(false)
                                .frame(
                                    width: animateView ? size.width : rect.width,
                                    height: animateView ? rect.height * scale : rect.height
                                )
                                .clipShape(.rect(cornerRadius: animateView ? 0 : 10))
                                .overlay(alignment: .top, content: {
                                    headerActions(post)
                                        .offset(y: coordinator.headerOffset)
                                        .padding(.top, safeArea.top)
                                })
                                .offset(x: animateView ? 0 : rect.minX, y: animateView ? 0 : rect.minY)
                                .offset(y: animateView ? -coordinator.headerOffset : 0)
                        }
                    }
                    .ignoresSafeArea()
                    .environment(coordinator)
                    .allowsHitTesting(coordinator.hideLayer)
                }
                .background(.gray.opacity(0.15))
            }
        }
    }
}

extension ExploreViewContent {
    @ViewBuilder
    func headerActions(_ post: Podcast) -> some View {
        HStack {
            Spacer(minLength: 0)
            if coordinator.hideLayer {
                Button(action: { coordinator.toogleView(show: false, frame: .zero, post: post) }, label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundStyle(Color.primary, .bar)
                        .padding(10)
                        .contentShape(.rect)
                })
                .transition(.asymmetric(insertion: .opacity, removal: .identity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: coordinator.hideLayer)
    }

    @ViewBuilder
    func podcastCardView(_ post: Podcast) -> some View {
        GeometryReader {
            let frame = $0.frame(in: .global)
            PodcastCardImageView(post: post)
                .clipShape(.rect(cornerRadius: 10))
                .contentShape(.rect(cornerRadius: 10))
                .onTapGesture {
                    coordinator.toogleView(show: true, frame: frame, post: post)
                }
        }
        .frame(height: 220)
    }
}
