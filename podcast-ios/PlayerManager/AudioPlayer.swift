//
//  AudioPlayer.swift
//  AudioPlayer
//
//  Created by Raidan on 2024. 10. 18..
//
import AVFoundation
import UIKit
import MediaPlayer
import Combine

final class AudioPlayer: Sendable, AudioPlayerProtocol {

    // MARK: - Properties
    static let shared = AudioPlayer()
    private let player = AVPlayer()
    @MainActor var elapsedTimeObserver: PlayerElapsedTimeObserver
    @MainActor var totalDurationObserver: PlayerTotalDurationObserver
    var playableItem: (any PlayableItemProtocol)? // the last dequeued item
    internal var queue: Queue<any PlayableItemProtocol> = .init()
    let playbackStatePublisher = CurrentValueSubject<PlaybackState, Never>(.waitingForSelection)
    var cancellables: Set<AnyCancellable> = .init()
    var elapsedTime: Double = .zero
    // MARK: - Initializer
    init() {
        self.elapsedTimeObserver = PlayerElapsedTimeObserver(player: player)
        self.totalDurationObserver = PlayerTotalDurationObserver(player: player)
        observeAudioInterruptions()
        observePlaybackProgression()
        player.automaticallyWaitsToMinimizeStalling = false
        Task { @MainActor in
            observingElapsedTime()
        }
    }

    // MARK: - Now Playing Info
    func updateNowPlayingInfo(playableItem: (any PlayableItemProtocol)?) {
        guard let playableItem else { return }

        var nowPlayingInfo = [String: Any]()

        nowPlayingInfo[MPMediaItemPropertyTitle] = playableItem.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = playableItem.author
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player.rate
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentTime().seconds
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = player.currentItem?.duration.seconds

        if let imageURL = playableItem.imageUrl {
            Task {
                let (data, _) = try await URLSession.shared.data(from: imageURL)
                guard let artworkImage = UIImage(data: data) else {
                    print("Failed to convert data to UIImage")
                    return
                }
                let artwork = MPMediaItemArtwork(boundsSize: artworkImage.size) { _ in artworkImage }
                nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
                MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
            }
        } else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        }
    }

    // MARK: - Audio Session
    func configureAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
            print("Audio session configured successfully for background playback.")
        } catch {
            print("Failed to configure the audio session: \(error.localizedDescription)")
            handleAudioSessionError(error)
        }
    }

    func handleAudioSessionError(_ error: Error) {
        print("Handling audio session error: \(error)")
    }

    func configureRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.resume()
            return .success
        }

        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }

        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.seekForward()
            return .success
        }

        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.seekBackward()
            return .success
        }
    }
    // MARK: - Playback Controls
    @MainActor
    func play(item: any PlayableItemProtocol, action: PlayAction) {
        switch action {
        case .playNow:
            playableItem = item
            replaceRunningItem(with: playableItem)
            player.play()
            configureAudioSession()
            configureRemoteCommandCenter()
            updateNowPlayingInfo(playableItem: playableItem)
            playbackStatePublisher.send(.playing)
            elapsedTimeObserver.pause(false)
        case .playLater:
            break
        case .playAfterRunningItem(item: let item):
            enqueue(item)
        case .playUntil(time: _):
            break
        case .replacePlayableItem(with: let withItem):
            stop()
            play(item: withItem, action: .playNow)
        }
    }
    @MainActor
    func stop() {
        player.pause()
        replaceRunningItem(with: nil)
        playableItem = nil
        player.seek(to: .zero)
        playbackStatePublisher.send(.stopped)
        elapsedTimeObserver.pause(true)
    }
    @MainActor
    func pause() {
        player.pause()
        playbackStatePublisher.send(.paused)
        elapsedTimeObserver.pause(true)
    }
    @MainActor
    func resume() {
        player.play()
        playbackStatePublisher.send(.playing)
        elapsedTimeObserver.pause(false)
    }

    func seekBackward() {
        let currentTime = player.currentTime()
        let newTime = CMTimeSubtract(currentTime, CMTime(seconds: 15, preferredTimescale: 1))
        player.seek(to: newTime)
    }

    func seekForward() {
        let currentTime = player.currentTime()
        let newTime = CMTimeAdd(currentTime, CMTime(seconds: 15, preferredTimescale: 1))
        player.seek(to: newTime)
    }
    @MainActor
    func seek(to time: Double, playerStatus isPlaying: PlaybackState) {
        let targetTime = CMTime(seconds: time, preferredTimescale: 600)

        if isPlaying == .playing {
            self.elapsedTimeObserver.pause(true)
            self.playbackStatePublisher.send(.buffering)
            player.seek(to: targetTime) { [weak self] _ in
                guard let self else { return }
                Task { @MainActor in
                    self.elapsedTimeObserver.pause(false)
                    self.playbackStatePublisher.send(.playing)
                }
            }
        } else {
            player.seek(to: targetTime)
        }
    }
    // MARK: - Queue Management
    func replaceRunningItem(with withItem: (any PlayableItemProtocol)?) {
        if let withItem {
            player.replaceCurrentItem(with: makePlayableItem(withItem))
        } else {
            player.replaceCurrentItem(with: nil)
        }
    }

    func enqueue(_ item: any PlayableItemProtocol) {
        queue.enqueue(item)
    }

    func dequeue() -> (Bool, (any PlayableItemProtocol)?) {
        if queue.isEmpty {
            return (false, nil)
        } else {
            return (true, queue.dequeue())
        }
    }

    // MARK: - Playback Progression
    func observePlaybackProgression() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playNextItem),
            name: .AVPlayerItemDidPlayToEndTime,
            object: nil
        )
    }
    @MainActor
    @objc private func playNextItem() {
        let (hasNext, nextItem) = dequeue()
        if hasNext, let nextItem = nextItem {
            replaceRunningItem(with: nextItem)
            player.play()
        } else {
            stop()
        }
    }
    @MainActor
    func observingElapsedTime() {
        elapsedTimeObserver.publisher.sink { [weak self] in
            if let self {
                self.elapsedTime = $0
            }
        }
        .store(in: &cancellables)
    }
    // MARK: - Audio Interruptions
    func observeAudioInterruptions() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
    }
    @MainActor
    @objc private func handleAudioInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let interruptionTypeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let interruptionType = AVAudioSession.InterruptionType(rawValue: interruptionTypeValue) else { return }

        switch interruptionType {
        case .began:
            pause()
            print("Audio interrupted. Pausing playback.")
        case .ended:
            handleInterruptionEnded(with: userInfo)
        @unknown default:
            break
        }
    }

    private func handleInterruptionEnded(with userInfo: [AnyHashable: Any]) {
        guard let interruptionOptionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
        let interruptionOptions = AVAudioSession.InterruptionOptions(rawValue: interruptionOptionsValue)
        if interruptionOptions.contains(.shouldResume), playbackStatePublisher.value == .paused {
            player.play()
            playbackStatePublisher.send(.playing)
        }
    }

    // MARK: - Playable Item Creation
    func makePlayableItem(_ playableItem: any PlayableItemProtocol) -> AVPlayerItem {
        AVPlayerItem(url: playableItem.streamURL)
    }
}

// MARK: - PlaybackState Enum
enum PlaybackState: Int, Equatable {
    case waitingForSelection
    case buffering
    case playing
    case paused
    case stopped
    case waitingForConnection
}

// MARK: - PlayAction Enum
enum PlayAction {
    case playNow
    case playLater
    case playAfterRunningItem(item: any PlayableItemProtocol)
    case playUntil(time: TimeInterval)
    case replacePlayableItem(with: any PlayableItemProtocol)
}
// MARK: - AudioPlayerProtocol
protocol AudioPlayerProtocol {
    func updateNowPlayingInfo(playableItem: (any PlayableItemProtocol)?)
    func makePlayableItem(_: any PlayableItemProtocol) -> AVPlayerItem
    func play(item: any PlayableItemProtocol, action: PlayAction) async
    func configureAudioSession()
    func pause()
    func stop()
    func seekBackward()
    func seekForward()
    func replaceRunningItem(with withItem: (any PlayableItemProtocol)?)
    func enqueue(_ item: any PlayableItemProtocol)
    func dequeue() -> (Bool, (any PlayableItemProtocol)?)
    var queue: Queue<any PlayableItemProtocol> { get }
    var playableItem: (any PlayableItemProtocol)? { get }
    var playbackStatePublisher: CurrentValueSubject<PlaybackState, Never> { get }
}

// MARK: - PlayableItemProtocol
protocol PlayableItemProtocol: Identifiable, Equatable {
    var title: String { get }
    var author: String { get }
    var imageUrl: URL? { get }
    var streamURL: URL { get }
    var id: String { get }
}
