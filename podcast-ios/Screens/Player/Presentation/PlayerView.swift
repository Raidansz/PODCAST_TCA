//
//  PlayerView.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 09. 21..
//

import SwiftUI
import ComposableArchitecture
import Combine

struct PlayerView: View {
    @Bindable var store: StoreOf<PlayerFeature>
    @Namespace private var animation
    var body: some View {
        GeometryReader {
            let size = $0.size
            let safeArea = $0.safeAreaInsets
            let cornerRadius: CGFloat = safeArea.bottom == 0 ? 0 : 45
            if #available(iOS 18.0, *) {
                ZStack(alignment: .top) {
                    /// Background
                    ZStack {
                        Rectangle()
                            .fill(.playerBackground)

                        Rectangle()
                            .fill(.linearGradient(colors: [.artwork1, .artwork2, .artwork3], startPoint: .top, endPoint: .bottom))
                            .opacity(store.expandPlayer ? 1 : 0)
                    }
                    .clipShape(.rect(cornerRadius: store.expandPlayer ? cornerRadius : 15))
                    .frame(height: store.expandPlayer ? nil : 55)
                    /// Shadows
                    .shadow(color: .primary.opacity(0.06), radius: 5, x: 5, y: 5)
                    .shadow(color: .primary.opacity(0.05), radius: 5, x: -5, y: -5)
                    
                    miniPlayer()
                        .opacity(store.expandPlayer ? 0 : 1)
                    
                    expandedPlayer(size, safeArea)
                        .opacity(store.expandPlayer ? 1 : 0)
                }
                .frame(height: store.expandPlayer ? nil : 55, alignment: .top)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, store.expandPlayer ? 0 : safeArea.bottom + 55)
                .padding(.horizontal, store.expandPlayer ? 0 : 15)
                .offset(y: store.offsetY)
                .gesture(
                    PanGesture { value in
                        guard store.expandPlayer else { return }
                        
                        let translation = max(value.translation.height, 0)
                        store.send(.updateOffsetY(translation))
                        store.send(.updateWindowProgress(max(min(translation / size.height, 1), 0) * 0.1))
                        
                        resizeWindow(0.1 - store.windowProgress)
                    } onEnd: { value in
                        guard store.expandPlayer else { return }
                        
                        let translation = max(value.translation.height, 0)
                        let velocity = value.velocity.height / 5
                        
                        withAnimation(.smooth(duration: 0.3, extraBounce: 0)) {
                            if (translation + velocity) > (size.height * 0.5) {
                                /// Closing View
                                store.send(.updateExpandPlayer(false))
                                store.send(.updateWindowProgress(0))
                                /// Resetting Window To Identity With Animation
                                resetWindowWithAnimation()
                            } else {
                                /// Reset Window To 0.1 With Animation
                                UIView.animate(withDuration: 0.3) {
                                    resizeWindow(0.1)
                                }
                            }
                            
                            store.send(.updateOffsetY(0))
                        }
                    }
                )
                .offset(y: store.hideMiniPlayer && !store.expandPlayer ? safeArea.bottom + 200 : 0)
                .ignoresSafeArea()
            } else {
                // Fallback on earlier versions
            }
        }
        .onAppear {
            if let window = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.keyWindow, store.mainWindow == nil {
                store.send(.updateMainWindow(window))
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



extension PlayerView {
    @ViewBuilder
    func miniPlayer() -> some View {
        HStack(spacing: 12) {
            ZStack {
                if !store.expandPlayer {
                    Image(.artwork)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipShape(.rect(cornerRadius: 10))
                        .matchedGeometryEffect(id: "Artwork", in: animation)
                }
            }
            .frame(width: 45, height: 45)
            
            Text("Calm Down")
            
            Spacer(minLength: 0)
            
            Group {
                Button("", systemImage: "play.fill") {
                    
                }
                
                Button("", systemImage: "forward.fill") {
                    
                }
            }
            .font(.title3)
            .foregroundStyle(Color.primary)
        }
        .padding(.horizontal, 10)
        .frame(height: 55)
        .contentShape(.rect)
        .onTapGesture {
            withAnimation(.smooth(duration: 0.3, extraBounce: 0)) {
                store.send(.updateExpandPlayer(true))
            }
            
            /// Reszing Window When Opening Player
            UIView.animate(withDuration: 0.3) {
                resizeWindow(0.1)
            }
        }

    }
}

extension PlayerView {
    @ViewBuilder
    func expandedPlayer(_ size: CGSize, _ safeArea: EdgeInsets) -> some View {
        VStack(spacing: 12) {
            Capsule()
                .fill(.white.secondary)
                .frame(width: 35, height: 5)
                .offset(y: -10)
            
            /// Sample Player View
            HStack(spacing: 12) {
                ZStack {
                    if store.expandPlayer {
                        Image(.artwork)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .clipShape(.rect(cornerRadius: 10))
                            .matchedGeometryEffect(id: "Artwork", in: animation)
                            .transition(.offset(y: 1))
                    }
                }
                .frame(width: 80, height: 80)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Calm Down")
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                    
                    Text("Rema, Selena Gomez")
                        .font(.caption2)
                        .foregroundStyle(.white.secondary)
                }
                
                Spacer(minLength: 0)
                
                HStack(spacing: 0) {
                    Button("", systemImage: "star.circle.fill") {
                        
                    }
                    
                    Button("", systemImage: "ellipsis.circle.fill") {
                        
                    }
                }
                .foregroundStyle(.white, .white.tertiary)
                .font(.title2)
            }
        }
        .padding(15)
        .padding(.top, safeArea.top)
    }
}


extension PlayerView {
    func resizeWindow(_ progress: CGFloat) {
        if let mainWindow = store.mainWindow?.subviews.first {
            let offsetY = (mainWindow.frame.height * progress) / 2
            
            /// Your Custom Corner Radius
            mainWindow.layer.cornerRadius = (progress / 0.1) * 30
            mainWindow.layer.masksToBounds = true
            
            mainWindow.transform = .identity.scaledBy(x: 1 - progress, y: 1 - progress).translatedBy(x: 0, y: offsetY)
        }
    }
    
    func resetWindowWithAnimation() {
        if let mainWindow = store.mainWindow?.subviews.first {
            UIView.animate(withDuration: 0.3) {
                mainWindow.layer.cornerRadius = 0
                mainWindow.transform = .identity
            }
        }
    }
}














/// MY beloved view

//        NavigationStack {
//            GeometryReader { proxy in
//                VStack {
//                    ListViewHero(imageURL: store.runningItem.episode?.imageUrl)
//                        .aspectRatio(contentMode: .fit)
//                        .frame(width: proxy.size.width, height: proxy.size.height * 0.5) // 382
//                        .clipped()
//                        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 10, y: 10)
//
//                    Spacer()
//                    VStack {
//                        Text(store.runningItem.episode?.title ?? "")
//                            .font(.headline)
//                        Text(store.runningItem.episode?.author ?? "")
//                            .font(.subheadline)
//                    }
//                    Spacer()
//                    HStack {
//                        Text(formatTime(seconds: store.runningItem.currentTime))
//                        Spacer()
//                        Text(formatTime(seconds: store.runningItem.totalTime))
//                    }
//                    .padding(.horizontal, 16)
//
//                    Slider(
//                        value: $store.runningItem.currentTime.sending(\.onCurrentTimeChange),
//                        in: 0...store.runningItem.totalTime,
//                        onEditingChanged: onEditingChanged
//                    )
//                    .padding(.horizontal, 16)
//                    .onReceive(
//                        Publishers.CombineLatest(
//                            AudioPlayer.shared.totalDurationObserver.publisher,
//                            AudioPlayer.shared.elapsedTimeObserver.publisher
//                        )) { totalDuration, elapsedTime in
//                            store.send(.onCurrentTimeChange(elapsedTime))
//                            store.send(.onTotalTimeChange(totalDuration))
//                        }
//                        .onReceive(AudioPlayer.shared.playbackStatePublisher) { state in
//                            if let item = AudioPlayer.shared.playableItem {
//                                if item.id == store.runningItem.episode?.id {
//                                    store.send(.updateIsPlaying(state))
//                                } else {
//                                    store.send(.updateIsPlaying(.stopped))
//                                }
//                            }
//                        }
//
//                    ControllButton(store: store)
//                        .padding(.top, 40)
//                }
//                .onAppear {
//                    store.send(.immeditelyPlay)
//                }
//                .navigationTitle("Now Playing")
//                .navigationBarTitleDisplayMode(.inline)
//            }
//        }
