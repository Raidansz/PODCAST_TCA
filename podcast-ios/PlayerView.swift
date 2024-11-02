//
//  PlayerView.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 09. 21..
//

import SwiftUI
import ComposableArchitecture
import AVFoundation
import Combine

@Reducer
struct PlayerFeature {
    @ObservableState
    struct State {
        var player: AVPlayer?
        var isPlaying: PlaybackState = .paused
        var audioURL: URL?
        @Shared(.runningItem) var runningItem = RunningItem()

        init(episode: Episode) {
            runningItem.setEpisode(episode: episode)
        }
    }

    enum Action: Equatable {
        case handlePlayAction
        case onCurrentTimeChange(Double)
        case onTotalTimeChange(Double)
        case updateIsPlaying(PlaybackState)
        case immeditelyPlay
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .handlePlayAction:
                return  handlePlayAction(for: &state)
            case .onCurrentTimeChange(let currentTime):
                state.runningItem.setCurrentTime(value: currentTime)
                return .none
            case .onTotalTimeChange(let totalTime):
                state.runningItem.setTotalTime(value: totalTime)
                return .none
            case .updateIsPlaying(let isPlaying):
                state.isPlaying = isPlaying
                return .none
            case .immeditelyPlay:
                guard let episode = state.runningItem.episode else { return .none }
                if episode.id != AudioPlayer.shared.playableItem?.id {
                    return .run { @MainActor _ in
                        AudioPlayer.shared.stop()
                        AudioPlayer.shared.play(item: episode, action: .playNow)
                    }
                }
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
                if beingPlayedItem.id == state.runningItem.episode?.id {
                    return .run { @MainActor _ in
                        AudioPlayer.shared.pause()
                    }
                } else {
                    return .run { @MainActor [episode = state.runningItem.episode] _ in
                        guard let episode else { return }
                        AudioPlayer.shared.play(item: episode, action: .playNow)
                    }
                }
            }
            return .none
        case .paused:
            if let beingPlayedItem = AudioPlayer.shared.playableItem {
                if beingPlayedItem.id == state.runningItem.episode?.id {
                    return .run { _ in
                        await AudioPlayer.shared.resume()
                    }
                } else {
                    return .run { [episode = state.runningItem.episode] _ in
                        guard let episode else { return }
                        await AudioPlayer.shared.play(item: episode, action: .playNow)
                    }
                }
            } else {
                return .run { [episode = state.runningItem.episode] _ in
                    guard let episode else { return }
                    await AudioPlayer.shared.play(item: episode, action: .playNow)
                }
            }
        case .stopped:
            return .run { [episode = state.runningItem.episode] _ in
                guard let episode else { return }
                await AudioPlayer.shared.play(item: episode, action: .playNow)
            }
        default:
            return .none
        }
    }
}

struct PlayerView: View {
    @Bindable var store: StoreOf<PlayerFeature>
    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                VStack {
                    ListViewHero(imageURL: store.runningItem.episode?.imageUrl)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: proxy.size.width, height: proxy.size.height * 0.5) // 382
                        .clipped()
                        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 10, y: 10)

                    Spacer()
                    VStack {
                        Text(store.runningItem.episode?.title ?? "")
                            .font(.headline)
                        Text(store.runningItem.episode?.author ?? "")
                            .font(.subheadline)
                    }
                    Spacer()
                    HStack {
                        Text(formatTime(seconds: store.runningItem.currentTime))
                        Spacer()
                        Text(formatTime(seconds: store.runningItem.totalTime))
                    }
                    .padding(.horizontal, 16)

                    Slider(
                        value: $store.runningItem.currentTime.sending(\.onCurrentTimeChange),
                        in: 0...store.runningItem.totalTime,
                        onEditingChanged: onEditingChanged
                    )
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
                                if item.id == store.runningItem.episode?.id {
                                    store.send(.updateIsPlaying(state))
                                } else {
                                    store.send(.updateIsPlaying(.stopped))
                                }
                            }
                        }

                    ControllButton(store: store)
                        .padding(.top, 40)
                }
                .onAppear {
                    store.send(.immeditelyPlay)
                }
                .navigationTitle("Now Playing")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }

    private func formatTime(seconds: Double) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let seconds = Int(seconds) % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

struct ControllButton: View {
    @Bindable var store: StoreOf<PlayerFeature>
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button {
                    ()
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .resizable()
                        .foregroundStyle(Color.blue.opacity(0.8))
                        .frame(width: 20, height: 20)
                }
                Spacer()
                Button {
                    AudioPlayer.shared.seekBackward()
                } label: {
                    Image(systemName: "gobackward.15")
                        .resizable()
                        .foregroundStyle(Color.blue.opacity(0.9))
                        .frame(width: 30, height: 30)
                }
                Spacer()
                Button {
                    store.send(.handlePlayAction)
                } label: {
                    if store.isPlaying == .playing {
                        Image(systemName: "pause.circle.fill")
                            .resizable()
                            .frame(width: 60, height: 60)
                    } else {
                        Image(systemName: "play.circle.fill")
                            .resizable()
                            .frame(width: 60, height: 60)
                    }
                }
                Spacer()
                Button {
                    AudioPlayer.shared.seekForward()
                } label: {
                    Image(systemName: "goforward.15")
                        .resizable()
                        .foregroundStyle(Color.blue.opacity(0.9))
                        .frame(width: 30, height: 30)
                }
                Spacer()
                Button {
                    ()
                } label: {
                    Image(systemName: "moon.zzz.fill")
                        .resizable()
                        .foregroundStyle(Color.blue.opacity(0.8))
                        .frame(width: 20, height: 20)
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
            AudioPlayer.shared.seek(to: store.runningItem.currentTime, playerStatus: store.isPlaying)
        }
    }
}
