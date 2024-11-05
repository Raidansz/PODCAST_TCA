//
//  ListViewHero.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 09. 20..
//

import SwiftUI
import Kingfisher

struct ListViewHero: View {
    let imageURL: URL?

    init(imageURL: URL?) {
        self.imageURL = imageURL
    }
    var body: some View {
        VStack {
            KFImage(imageURL)
                .resizable()
                .placeholder({
                    Image(systemName: "waveform.badge.mic")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.gray, lineWidth: 0.5)
                        )
                })
                .setProcessor(
                    DownsamplingImageProcessor(size: CGSize(width: 380, height: 380)) |>
                    JPEGCompressProcessor(compressionQuality: 0.5)
                )
                .onSuccess { result in
                    PODLogInfo("Image loaded from cache: \(result.cacheType)")
                }
                .onFailure { error in
                    PODLogError("Error: \(error)")
                }
                .aspectRatio(contentMode: .fit)
                .cornerRadius(10)
                .clipped()
        }
    }
}

struct CategoryViewHero: View {
    let title: String
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.randomReadableBackground)
                .background(Blur(style: .systemMaterial))
                .cornerRadius(20)
                .frame(width: 200, height: 100)
                .shadow(color: Color.randomReadableBackground.opacity(0.2), radius: 10, x: 0, y: 10)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.black.opacity(0.5), lineWidth: 2)
                )

            Text(title)
                .font(.headline)
                .foregroundColor(.black)
                .bold()
                .multilineTextAlignment(.center)
        }
    }
}

struct Blur: UIViewRepresentable {
    var style: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: style))
        return view
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

extension Color {
    static var randomReadableBackground: Color {
        var color: Color
        repeat {
            color = Color(
                red: Double.random(in: 0...1),
                green: Double.random(in: 0...1),
                blue: Double.random(in: 0...1)
            )
        } while color.isTooDark()
        return color
    }

    private func isTooDark() -> Bool {
        guard let components = UIColor(self).cgColor.components, components.count >= 3 else {
            return false
        }
        let brightness = (components[0] * 299 + components[1] * 587 + components[2] * 114) / 1000
        return brightness < 0.5
    }
}
