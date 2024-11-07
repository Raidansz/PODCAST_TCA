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
    let theme: Color
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(theme)
                .cornerRadius(20)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 10)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(theme.opacity(0.2), lineWidth: 2)
                )

            Text(title)
                .font(.headline)
                .foregroundColor(scheme == .dark ? .white : .black)
                .bold()
                .multilineTextAlignment(.center)
        }
    }
}
