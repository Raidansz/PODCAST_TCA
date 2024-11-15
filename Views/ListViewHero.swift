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
    let title: String?
    let randomTheme = getRandomTheme()

    init(imageURL: URL?, title: String?) {
        self.imageURL = imageURL
        self.title = title
    }

    var body: some View {
        VStack(alignment: .leading) {
            KFImage(imageURL)
                .resizable()
                .placeholder({
                    Rectangle()
                    .fill(randomTheme.mainColor)
                    .frame(width: 120, height: 120)
                    .scaledToFill()
                    .cornerRadius(7)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.gray, lineWidth: 0.5)
                    )
                    .clipped()
                })
                .setProcessor(
                    DownsamplingImageProcessor(size: CGSize(width: 120, height: 120)) |>
                    JPEGCompressProcessor(compressionQuality: 0.5)
                )
                .onSuccess { result in
                    PODLogInfo("Image loaded from cache: \(result.cacheType)")
                }
                .onFailure { error in
                    PODLogError("Error: \(error)")
                }
                .scaledToFill()
                .frame(width: 120, height: 120)
                .cornerRadius(7)
                .clipped()
            Text(title ?? "")
                .font(.system(size: 20))
                .fontWeight(.semibold)
                .foregroundColor(Color.primary)
                .frame(width: 120, height: 20, alignment: .leading)
                .lineLimit(1)
        }
    }
}

struct HeroCell: View {
    let imageURL: URL?
    let title: String?
    let randomTheme = getRandomTheme()

    init(imageURL: URL?, title: String?) {
        self.imageURL = imageURL
        self.title = title
    }

    var body: some View {
        VStack(alignment: .leading) {
            KFImage(imageURL)
                .resizable()
                .placeholder({
                    Rectangle()
                    .fill(randomTheme.mainColor)
                    .frame(width: 380, height: 380)
                    .scaledToFill()
                    .cornerRadius(7)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.gray, lineWidth: 0.5)
                    )
                    .clipped()
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
                .scaledToFill()
                .frame(width: 380, height: 380)
                .cornerRadius(7)
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
