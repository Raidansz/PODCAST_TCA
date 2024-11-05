//
//  PlayerFeature.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 11. 02..
//

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
        case flushRunningItem
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
            case .flushRunningItem:
                state.runningItem = RunningItem()
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
