//
//  AudioSliderBarView.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 09. 22..
//

import SwiftUI

struct MusicProgressSlider<T: BinaryFloatingPoint>: View {
    @Binding var value: T
    let inRange: ClosedRange<T>
    let activeFillColor: Color = .accentColor.opacity(0.5)
    let fillColor: Color = .accentColor
    let emptyColor: Color = .gray.opacity(0.2)
    let height: CGFloat = 32
    let onEditingChanged: (Bool) -> Void

    @State private var localRealProgress: T = 0
    @State private var localTempProgress: T = 0
    @GestureState private var isActive: Bool = false
    @State private var progressDuration: T = 0

    init(
        value: Binding<T>,
        inRange: ClosedRange<T>,
        onEditingChanged: @escaping (Bool) -> Void
    ) {
        self._value = value
        self.inRange = inRange
        self.onEditingChanged = onEditingChanged
    }

    var body: some View {
        GeometryReader { bounds in
            ZStack {
                VStack {
                    ZStack(alignment: .center) {
                        Capsule()
                            .fill(emptyColor)
                        Capsule()
                            .fill(isActive ? activeFillColor : fillColor)
                            .mask(
                                HStack {
                                    Rectangle()
                                        .frame(width: max(bounds.size.width * CGFloat(localRealProgress + localTempProgress), 0), alignment: .leading)
                                    Spacer(minLength: 0)
                                }
                            )
                    }

                    HStack {
                        Spacer(minLength: 0)
                    }
                    .font(.system(.headline, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(isActive ? fillColor : emptyColor)
                }
                .frame(width: isActive ? bounds.size.width * 1.04 : bounds.size.width, alignment: .center)
                .animation(animation, value: isActive)
            }
            .frame(width: bounds.size.width, height: bounds.size.height, alignment: .center)
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .updating($isActive) { _, state, _ in
                        state = true
                    }
                    .onChanged { gesture in
                        localTempProgress = T(gesture.translation.width / bounds.size.width)
                        let prg = max(min(localRealProgress + localTempProgress, 1), 0)
                        progressDuration = inRange.upperBound * prg
                        value = max(min(getPrgValue(), inRange.upperBound), inRange.lowerBound)
                    }
                    .onEnded { _ in
                        localRealProgress = max(min(localRealProgress + localTempProgress, 1), 0)
                        localTempProgress = 0
                        progressDuration = inRange.upperBound * localRealProgress
                    }
            )
            .onChange(of: isActive) { newValue in
                value = max(min(getPrgValue(), inRange.upperBound), inRange.lowerBound)
                onEditingChanged(newValue)
            }
            .onAppear {
                localRealProgress = getPrgPercentage(value)
                progressDuration = inRange.upperBound * localRealProgress
            }
            .onChange(of: value) { newValue in
                if !isActive {
                    localRealProgress = getPrgPercentage(newValue)
                }
            }
        }
        .frame(height: isActive ? height * 1.25 : height, alignment: .center)
    }

    private var animation: Animation {
        isActive ? .spring() : .spring(response: 0.5, dampingFraction: 0.5, blendDuration: 0.6)
    }

    private func getPrgPercentage(_ value: T) -> T {
        let range = inRange.upperBound - inRange.lowerBound
        let correctedValue = value - inRange.lowerBound
        return correctedValue / range
    }

    private func getPrgValue() -> T {
        (localRealProgress + localTempProgress) * (inRange.upperBound - inRange.lowerBound) + inRange.lowerBound
    }
}

#Preview {
    MusicProgressSlider(value: .constant(0.5), inRange: 5...10) { _ in }
}
