//
//  PlayerView.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 09. 21..
//

import SwiftUI
import ComposableArchitecture
import AVFoundation
import SliderControl
import Combine

@Reducer
struct PlayerFeature {
    @ObservableState
    struct State: Equatable {
        var player: AVPlayer?
        var isPlaying: PlaybackState = .paused
        var currentTime: Double = 0
        var totalTime: Double = 100
        var audioURL: URL?
        var episode: Episode

        init(episode: Episode) {
            self.episode = episode
        }
    }

    enum Action: Equatable {
        case handlePlayAction
        case onCurrentTimeChange(Double)
        case onTotalTimeChange(Double)
        case updateIsPlaying(PlaybackState)
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .handlePlayAction:
                return  handlePlayAction(for: &state)
            case .onCurrentTimeChange(let currentTime):
                state.currentTime = currentTime
                return .none
            case .onTotalTimeChange(let totalTime):
                state.totalTime = totalTime
                return .none
            case .updateIsPlaying(let isPlaying):
                state.isPlaying = isPlaying
                return .none
            }
        }
    }
}
    // TODO: define a sharedStateStorage
extension PlayerFeature {
    private func handlePlayAction(for state: inout State) -> Effect<Action> {
        switch state.isPlaying {
        case .playing:
            if let beingPlayedItem = AudioPlayer.shared.playableItem {
                if beingPlayedItem.id == state.episode.id {
                    return .run { @MainActor _ in
                        AudioPlayer.shared.pause()
                    }
                } else {
                    return .run { @MainActor [episode = state.episode] _ in
                        AudioPlayer.shared.play(item: episode, action: .playNow)
                    }
                }
            }
            return .none
        case .paused:
            if let beingPlayedItem = AudioPlayer.shared.playableItem {
                if beingPlayedItem.id == state.episode.id {
                    return .run { _ in
                        await AudioPlayer.shared.resume()
                    }
                } else {
                    return .run { [episode = state.episode] _ in
                        await AudioPlayer.shared.play(item: episode, action: .playNow)
                    }
                }
            } else {
                return .run { [episode = state.episode] _ in
                    await AudioPlayer.shared.play(item: episode, action: .playNow)
                }
            }
        case .stopped:
            return .run { [episode = state.episode] _ in
                await AudioPlayer.shared.play(item: episode, action: .playNow)
            }
        default:
            return .none
        }
    }
}

struct PlayerView: View {
    @State var store: StoreOf<PlayerFeature>
    var body: some View {
        NavigationStack {
            VStack {
                ZStack {
                    ListViewHero(imageURL: store.episode.imageUrl.unsafelyUnwrapped)
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

                SliderControlView(
                    value: $store.currentTime.sending(\.onCurrentTimeChange),
                    in: 0...store.totalTime,
                    onEditingChanged: onEditingChanged
                )
                .progressColor(.blue)
                .padding(.horizontal, 16)
                .onReceive(
                    Publishers.CombineLatest(
                        AudioPlayer.shared.totalDurationObserver.publisher,
                        AudioPlayer.shared.elapsedTimeObserver.publisher
                    )) { totalDuration, elapsedTime in
                        store.send(.onCurrentTimeChange(elapsedTime))
                        store.send(.onTotalTimeChange(totalDuration))
                    }
                    .onReceive(AudioPlayer.shared.playbackStatePublisher) { state in
                        if let item = AudioPlayer.shared.playableItem {
                            if item.id == store.episode.id {
                                store.send(.updateIsPlaying(state))
                            } else {
                                store.send(.updateIsPlaying(.stopped))
                            }
                        }
                    }

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
                    store.send(.handlePlayAction)
                } label: {
                    if store.isPlaying == .playing {
                        Image(systemName: "pause.circle.fill")
                            .resizable()
                            .frame(width: 80, height: 80)
                    } else {
                        Image(systemName: "play.circle.fill")
                            .resizable()
                            .frame(width: 80, height: 80)
                    }
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

extension PlayerView {
    func onEditingChanged(editingStarted: Bool) {
        if editingStarted {
            AudioPlayer.shared.elapsedTimeObserver.pause(true)
        } else {
            AudioPlayer.shared.seek(to: store.currentTime, playerStatus: store.isPlaying)
        }
    }
}
