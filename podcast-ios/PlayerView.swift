//
//  PlayerView.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 09. 21..
//

import SwiftUI
import ComposableArchitecture
import AVFoundation
@Reducer
struct PlayerFeature {
    @ObservableState
    struct State: Equatable {
        var player: AVPlayer?
        var isPlaying = false
        var totalTime: TimeInterval = 0.0
        var currentTime: TimeInterval = 0.0
        var audioURL: URL?
        var playerPodcast: IdentifiedArrayOf<Podcast>

        init(podcast: IdentifiedArrayOf<Podcast>) {
            self.playerPodcast = podcast
        }
    }

    enum Action: Equatable {
        case initialize(URL?)
        case play
        case pause
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .initialize(let url):
                if let url {
                    state.player = AVPlayer(url: url)
                    state.player!.play()
                }
                return .none
            case .play:
                if state.player == nil {
                    return .send(.initialize(state.audioURL))
                } else {
                    state.isPlaying = true
                    state.player!.play()
                    return .none
                }
            case .pause:
                state.isPlaying = false
                state.player?.pause()
                return .none
            }
        }
    }
}

struct PlayerView: View {
    @State var store: StoreOf<PlayerFeature>
    var body: some View {
        NavigationStack {
            VStack {
                ZStack {
                    AsyncImage(url: URL(string: "https://picsum.photos/364/364")!)
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(24)
                        .frame(width: 364, height: 364)

                    VStack {
                        Spacer()
                            .frame(height: 359)

                        RoundedRectangle(cornerRadius: 48)
                            .fill(Color.blue.opacity(0.2))

                            .blur(radius: 5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 48)
                                    .stroke(Color.white.opacity(0.7), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                            .frame(width: 266, height: 72)
                    }
                }
                Spacer()
                VStack {
                    Text("Sunday Vibes - Rift")
                        .font(.headline)
                    Text("Entertainment")
                        .font(.subheadline)
                }
                Spacer()
                HStack {
                    Text("07:00")
                    Spacer()
                    Text("15:00")
                }
                .padding(.horizontal, 16)
// TODO: Add slider
                ControllButton(store: store)
                    .padding(.top, 40)
            }
            .navigationTitle("Now Playing")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}


struct ControllButton: View {
    @State var store: StoreOf<PlayerFeature>
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button {
                    ()
                } label: {
                    Image(systemName: "shuffle")
                        .resizable()
                        .frame(width: 32, height: 32)
                }
                Spacer()
                Button {
                    ()
                } label: {
                    Image(systemName: "gobackward.15")
                        .resizable()
                        .frame(width: 32, height: 32)
                }
                Spacer()
                Button {
                    store.send(.play)
                } label: {
                    Image(systemName: "play.circle.fill")
                        .resizable()
                        .frame(width: 80, height: 80)
                }
                Spacer()
                Button {
                    ()
                } label: {
                    Image(systemName: "goforward.15")
                        .resizable()
                        .frame(width: 32, height: 32)
                }
                Spacer()
                Button {
                    ()
                } label: {
                    Image(systemName: "water.waves.and.arrow.down")
                        .resizable()
                        .frame(width: 32, height: 32)
                }
                Spacer()
            }
        }
    }
}
