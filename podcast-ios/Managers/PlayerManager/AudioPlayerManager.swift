//
//  AVPlayerManager.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 11. 06..
//

import Combine
import Foundation
import AVFoundation
import MediaPlayer
import Kingfisher

final class AudioPlayerManager: NSObject, @unchecked Sendable {
    // MARK: - Stored Properties
    static let shared = AudioPlayerManager()
    var audioPlayerManager: AVPlayerManager?
    var elapsedTimeObserver = PassthroughSubject<TimeInterval, Never>()
    var timeObserver: Any?
    var totalItemTimeObserver = PassthroughSubject<TimeInterval, Never>()
    var player: AVPlayer?
    var elapsedTime: Double = .zero
    private(set) var playbackStatePublisher
    = CurrentValueSubject<PlaybackState, Never>(.waitingForSelection)
    var cancellables: Set<AnyCancellable> = []
    var playableItem: (any PlayableItemProtocol)?
    private var resourceLoaderDelegate: StreamingResourceLoaderDelegate?
    var queue: Queue<any PlayableItemProtocol> = .init()
    // MARK: - Setup

    func setup() {
        self.player = AVPlayer()
        guard let player else { return }
        setupElapsedTimeObserver(player: player)
        setupTotalItemTimeObserver(player: player)
        self.audioPlayerManager = AVPlayerManager(player: player)
        configureAudioSession()
        configureRemoteCommandCenter()
        observingElapsedTime()
    }

    // MARK: - TearDown
    func tearDown() {
        tearDownTimeObservers()
        audioPlayerManager = nil
        player?.replaceCurrentItem(with: nil)
        player = nil
        resourceLoaderDelegate = nil
        try? AVAudioSession.sharedInstance().setActive(false)
        URLCache.shared.removeAllCachedResponses()
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func playNextItem() {
        let (hasNext, nextItem) = dequeue()
        if hasNext, let nextItem = nextItem {
        play(avPlayerItem: nextItem)
        } else {
            stop()
        }
    }

    func updatePlayerStatus(state: PlaybackState) {
        Task { @MainActor in
            self.playbackStatePublisher.send(state)
        }
    }
    // MARK: - Control Panel

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

    func makePlayableItem(_ playableItem: (any PlayableItemProtocol)?) -> AVPlayerItem? {
        if let url = playableItem?.streamURL {
            let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
            let asset = AVURLAsset(url: request.url!, options: [
                "AVURLAssetAllowsCellularAccessKey": true,
                "AVURLAssetPreferPreciseDurationAndTimingKey": false
            ])

            resourceLoaderDelegate = StreamingResourceLoaderDelegate()

            asset.resourceLoader.setDelegate(resourceLoaderDelegate, queue: DispatchQueue.main)

            let playerItem = AVPlayerItem(asset: asset)
            playerItem.preferredForwardBufferDuration = 0
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(playerDidFinishPlaying),
                name: .AVPlayerItemDidPlayToEndTime,
                object: playerItem
            )
            return playerItem
        }
        return nil
    }

    @objc func playerDidFinishPlaying(notification: Notification) {
        URLCache.shared.removeAllCachedResponses()
    }

    @objc private func handleAudioInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let interruptionTypeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let interruptionType = AVAudioSession.InterruptionType(rawValue: interruptionTypeValue) else { return }

        switch interruptionType {
        case .began:
            pause()
            PODLogInfo("Audio interrupted. Pausing playback.")
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
            resume()
        }
    }
}
// MARK: - Observers
extension AudioPlayerManager {
    func setupElapsedTimeObserver(player: AVPlayer) {
        self.player = player
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(
                seconds: 0.5,
                preferredTimescale: 600
            ),
            queue: nil
        ) { [weak self] time in
            guard let self = self else { return }
            if self.playbackStatePublisher.value == .paused { return }
            self.elapsedTimeObserver.send(time.seconds)
        }
    }

    func setupTotalItemTimeObserver(player: AVPlayer) {
        let durationKeyPath: KeyPath<AVPlayer, CMTime?> = \.currentItem?.duration
        player.publisher(for: durationKeyPath).sink { duration in
            guard let duration = duration else { return }
            guard duration.isNumeric else { return }
            self.totalItemTimeObserver.send(duration.seconds)
        }
        .store(in: &cancellables)
    }

    func observePlaybackProgression() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playNextItem),
            name: .AVPlayerItemDidPlayToEndTime,
            object: nil
        )
    }

    func observeAudioInterruptions() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
    }

    func observingElapsedTime() {
        elapsedTimeObserver.sink { [weak self] time in
            guard let self else { return }
            if playbackStatePublisher.value == .playing {
                self.elapsedTime = time
            }
        }
        .store(in: &cancellables)
    }

    func tearDownTimeObservers() {
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        cancellables.removeAll()
    }
}

// MARK: - Audio Session & Media Player info
extension AudioPlayerManager {
    func updateNowPlayingInfo(playableItem: (any PlayableItemProtocol)?) {
        guard let playableItem else { return }

        var nowPlayingInfo = [String: Any]()

        nowPlayingInfo[MPMediaItemPropertyTitle] = playableItem.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = playableItem.author
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player?.rate
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsedTime
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = player?.currentItem?.duration.seconds

        if let imageURL = playableItem.imageUrl {
            Task {
                let result = try? await KingfisherManager.shared.retrieveImage(with: imageURL)
                if let cachedImage = result?.image {
                    let artwork = MPMediaItemArtwork(boundsSize: cachedImage.size) { _ in cachedImage }
                    nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
                    try await KingfisherManager.shared.cache.removeImage(forKey: imageURL.absoluteString)
                }
                MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
            }
        } else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        }
    }

    func configureAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
            PODLogInfo("Audio session configured successfully for background playback.")
        } catch {
            PODLogError("Failed to configure the audio session: \(error.localizedDescription)")
            handleAudioSessionError(error)
        }
    }

    func handleAudioSessionError(_ error: Error) {
        PODLogError("Handling audio session error: \(error)")
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
}

// MARK: - Control Panel
extension AudioPlayerManager {
    func play(avPlayerItem: (any PlayableItemProtocol)?) {
        guard let item = makePlayableItem(avPlayerItem) else { return }
        stop()
        self.playableItem = avPlayerItem
        setup()
        audioPlayerManager?.play(playerItem: item)
        updateNowPlayingInfo(playableItem: playableItem)
        updatePlayerStatus(state: .playing)
    }

    func resume() {
        audioPlayerManager?.resume()
        updatePlayerStatus(state: .playing)
    }

    func pause() {
        audioPlayerManager?.pause()
        updatePlayerStatus(state: .paused)
    }

    func stop() {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        audioPlayerManager?.stop()
        updatePlayerStatus(state: .stopped)
        tearDown()
    }

    func seek(to time: Double) {
        let targetTime = CMTime(seconds: time, preferredTimescale: 600)
        if playbackStatePublisher.value == .playing {
            updatePlayerStatus(state: .buffering)
            audioPlayerManager?.player.seek(to: targetTime) { [weak self] _ in
                guard let self else { return }
                updatePlayerStatus(state: .playing)
                audioPlayerManager?.resume()
            }
        } else {
            audioPlayerManager?.player.seek(to: targetTime)
        }
    }

    func seekForward() {
        audioPlayerManager?.seekForward()
    }

    func seekBackward() {
        audioPlayerManager?.seekBackward()
    }
}

class StreamingResourceLoaderDelegate: NSObject, AVAssetResourceLoaderDelegate {
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader,
                        shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {

        guard let url = loadingRequest.request.url else {
            loadingRequest.finishLoading(with: NSError(domain: "Invalid URL", code: 0, userInfo: nil))
            return false
        }

        let task = URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data {
                loadingRequest.dataRequest?.respond(with: data)
                if loadingRequest.dataRequest?.requestedOffset == loadingRequest.dataRequest?.currentOffset {
                    loadingRequest.finishLoading()
                }
            } else if let error = error {
                loadingRequest.finishLoading(with: error)
            }
        }
        task.resume()
        return true
    }

    func resourceLoader(_ resourceLoader: AVAssetResourceLoader,
                        didCancel loadingRequest: AVAssetResourceLoadingRequest) {
        PODLogInfo("Loading request canceled.")
    }
}

// MARK: - AVPlayerManagerActor
@globalActor actor AVPlayerManagerActor: Sendable {
    static let shared = AVPlayerManagerActor()
}
