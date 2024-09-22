//
//  PlayerView.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 09. 21..
//

import SwiftUI

struct PlayerView: View {
    @State private var playerDuration: TimeInterval = 100
    private let maxDuration = TimeInterval(240)
    @State private var volume: Double = 0.3
    private var maxVolume: Double = 1
    @State private var sliderValue: Double = 10
    private var maxSliderValue: Double = 100
    @State private var color: Color = .white

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
                MusicProgressSlider(value: $playerDuration, inRange: TimeInterval.zero...maxDuration, activeFillColor: color, fillColor: .blue, emptyColor: .gray, height: 32) { started in
                }
                .frame(height: 40)
                .padding(.horizontal, 16)

                ControllButton()
                    .padding(.top, 40)
            }
            .navigationTitle("Now Playing")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    PlayerView()
}

struct ControllButton: View {
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
                    ()
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
