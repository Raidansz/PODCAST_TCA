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
        var isPlaying: Bool = false
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
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
                //TODO: make it less complex
            case .handlePlayAction:
                switch AudioPlayer.shared.playbackStatePublisher.value {
                case .waitingForSelection:
                    state.isPlaying = true
                    return .run { [state] _ in
                        await AudioPlayer.shared.play(item: state.episode, action: .playNow)
                    }
                case .playing:
                    state.isPlaying = false
                    return .run { _ in
                        await  AudioPlayer.shared.pause()
                    }
                case .paused:
                    state.isPlaying = false
                    return .run { _ in
                        await  AudioPlayer.shared.resume()
                    }
                default:
                    return .none
                }
            case .onCurrentTimeChange(let currentTime):
                state.currentTime = currentTime
                return .none
            case .onTotalTimeChange(let totalTime):
                state.totalTime = totalTime
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
                    //Play button
                    store.send(.handlePlayAction)
                } label: {
                    if store.isPlaying {
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

extension PlayerView{
    func onEditingChanged(editingStarted: Bool) {
        if editingStarted {
            AudioPlayer.shared.elapsedTimeObserver.pause(true)
        } else {
            AudioPlayer.shared.seek(to: store.currentTime, playerStatus: store.isPlaying)
        }
    }
}
