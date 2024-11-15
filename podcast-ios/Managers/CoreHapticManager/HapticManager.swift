//
//  HapticManager.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 10. 25..
//
import CoreHaptics
import Combine
import AppLogger

final class HapticManager: HapticManagerProtocol, @unchecked Sendable {
    private var engine: CHHapticEngine?
    let fireHaptic: PassthroughSubject<Void, Never> = .init()
    var cancellables: Set<AnyCancellable> = []
    private let hapticsQueue = DispatchQueue(label: "com.raidan.podcast.haptics", qos: .userInteractive)

    init() {
        prepareHaptics()
        fireHaptic.sink { [weak self] _ in
            guard let self else { return }
            hapticsQueue.async {
                self.complexSuccess()
            }
        }
        .store(in: &cancellables)
    }
    deinit {
        PODLogInfo("HapticManager was deinitialized")
    }
}

extension HapticManager {
    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }

        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            PODLogError("There was an error creating the engine: \(error.localizedDescription)")
        }
    }

    func complexSuccess() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        var events = [CHHapticEvent]()

        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 1)
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
        events.append(event)

        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            PODLogError("Failed to play pattern: \(error.localizedDescription).")
        }
    }
}

protocol HapticManagerProtocol {
    var fireHaptic: PassthroughSubject<Void, Never> { get }
}
