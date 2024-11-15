//
//  PlayerView.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 09. 21..
//

import SwiftUI
import ComposableArchitecture
import Combine
import AudioPlayer

struct PlayerView: View {
    @Bindable var store: StoreOf<PlayerFeature>
    @State var playerStatus: PlaybackState = .waitingForSelection
    @State var totalTime: String = "02:00:00"
    @State var elapsedTime: String = "00:00"

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                VStack {
                    HeroCell(imageURL: store.runningItem.episode?.imageUrl, title: store.runningItem.episode?.title)
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
                    VStack {
                        HStack {
                            Text(elapsedTime)
                            Spacer()
                            Text(totalTime)
                        }
                        .padding(.horizontal, 16)

                        Slider(
                            value: $store.runningItem.currentTime.sending(\.onCurrentTimeChange),
                            in: 0...store.runningItem.totalTime,
                            onEditingChanged: onEditingChanged
                        )
                        .padding(.horizontal, 16)
                    }
                    .onReceive(AudioPlayerManager.shared.elapsedTimeObserver) { value in
                        if AudioPlayerManager.shared.playableItem?.id == store.runningItem.episode?.id {
                            store.send(.onCurrentTimeChange(value))
                            elapsedTime = formatTime(seconds: value)
                            totalTime = formatTime(seconds: store.runningItem.totalTime)
                        }
                    }
                    .onReceive(AudioPlayerManager.shared.totalItemTimeObserver) { value in
                        if AudioPlayerManager.shared.playableItem?.id == store.runningItem.episode?.id {
                            store.send(.onTotalTimeChange(value))
                            totalTime = formatTime(seconds: value)
                        }
                    }
                    .onReceive(AudioPlayerManager.shared.playbackStatePublisher) { state in
                        if let item = AudioPlayerManager.shared.playableItem {
                            if item.id == store.runningItem.episode?.id {
                                store.send(.updateIsPlaying(state))
                            } else {
                                store.send(.updateIsPlaying(.stopped))
                            }
                        }
                        playerStatus = state
                    }

                    ControllButton(store: store, playerStatus: $playerStatus)
                        .padding(.top, 40)
                }
                .onAppear {
                    store.send(.immeditelyPlay)
                }
                .onDisappear {
                    if playerStatus == .paused {
                        AudioPlayerManager.shared.stop()
                        store.send(.flushRunningItem)
                    }
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
    @Binding var playerStatus: PlaybackState
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
                    AudioPlayerManager.shared.seekBackward()
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
                    if playerStatus == .playing {
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
                    AudioPlayerManager.shared.seekForward()
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
            AudioPlayerManager.shared.shouldObserveElapsedTime = false
        } else {
            AudioPlayerManager.shared.seek(to: store.runningItem.currentTime)
        }
    }
}
