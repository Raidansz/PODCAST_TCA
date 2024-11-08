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
                ExploreListView(store: store, shouldShowSegmentView: false)
                    .blur(
                        radius: store.isLoading ? 5 : 0
                    )
                    .navigationBarHidden(true)

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
            case .categoryDetails(let store):
                CategoryDetailsView(store: store)
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

struct ExploreListView: View {
    @Bindable var store: StoreOf<ExploreFeature>
    @FocusState private var isSearching: Bool
    @State private var activeTab: Tab = .all
    @Environment(\.colorScheme) private var scheme
    @Namespace private var animation
    @State var shouldShowSegmentView: Bool
    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 15) {
                ExploreViewContent(store: store)
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
    func expandableNavigationBar(_ title: String = "Explore") -> some View {
        GeometryReader { proxy in
            let minY = proxy.frame(in: .scrollView(axis: .vertical)).minY
            let scrollviewHeight = proxy.bounds(of: .scrollView(axis: .vertical))?.height ?? 0
            let scaleProgress = minY > 0 ? 1 + (max(min(minY / scrollviewHeight, 1), 0) * 0.5) : 1
            let progress = isSearching ? 1 : max(min(-minY / 70, 1), 0)

            VStack(spacing: 10) {
                /// Title
                Text(title)
                    .font(.largeTitle.bold())
                    .scaleEffect(scaleProgress, anchor: .topLeading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 10)
                    .foregroundStyle(progress < 1  ? Color.primary: Color.primary.opacity(0))

                /// Search Bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.title3)

                    TextField("Search Podcasts or Episodes", text: $store.searchTerm.sending(\.searchTermChanged))
                        .focused($isSearching)
                        .onSubmit {
                            store.send(.searchForPodcastTapped(with: store.searchTerm))
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
        .frame(height: shouldShowSegmentView ? 190 : 140)
        .padding(.bottom, 10)
        .padding(.bottom, isSearching ? -65 : 0)
    }
}
struct ExploreViewContent: View {
    @Bindable var store: StoreOf<ExploreFeature>
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        ScrollView {
            Section(content: {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 100, maximum: 200)),
                              GridItem(.adaptive(minimum: 100, maximum: 200))],
                    spacing: 8) {
                        ForEach(store.catagoryList) { catagory in
                            CategoryViewHero(title: catagory.title, theme: (scheme == .dark ? Color.customGray : .gray.opacity(0.15)))
                                .frame(height: 100)
                                .onTapGesture {
                                    store.send(.catagoryTapped(catagory))
                                }
                        }
                    }
                    .padding(.horizontal, 16)
            }, header: {
                HStack {
                    Text("Categories")
                        .fontWeight(.semibold)
                    Spacer()
                }
                .padding(.horizontal, 16)
            })
        }
    }
}

struct CustomScrollTargetBehaviour: ScrollTargetBehavior {
    func updateTarget(_ target: inout ScrollTarget, context: TargetContext) {
        if target.rect.minY < 70 {
            if target.rect.minY < 35 {
                target.rect.origin = .zero
            } else {
                target.rect.origin = .init(x: 0, y: 70)
            }
        }
    }
}

struct ErrorMessage {
    let text: String
    let color: Color
    let id: String
}

enum Tab: String, CaseIterable {
    case all = "All"
    case podcasts = "Podcasts"
    case episodes = "Episodes"
}


extension Color {
    static let customGray = Color(red: 49 / 255, green: 49 / 255, blue: 49 / 255)
}
