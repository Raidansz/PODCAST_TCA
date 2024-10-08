//
//  ListViewCell.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 09. 20..
//

import SwiftUI

struct ListViewCell: View {
    let podcast: Podcast

    var body: some View {
        HStack(alignment: .top) {
            AsyncImage(url: podcast.image) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .cornerRadius(24)
                        .clipped()
                } else {
                    Image(systemName: "waveform.badge.mic")
                        .frame(width: 100, height: 100)
                        .cornerRadius(24)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.gray, lineWidth: 0.5)
                        )
                }
            }
            .frame(width: 100, height: 100)
            .cornerRadius(24)

            VStack(alignment: .leading, spacing: 16) {
                Spacer()
                    .frame(maxHeight: 4)
                Text(podcast.title ?? "")
                    .font(.headline)
                    .bold()
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(podcast.author ?? "")
                    .font(.subheadline)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.leading, 8)
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()
        }
        .frame(alignment: .center)
        Divider()
            .background(Color(.systemGray))
    }
}





struct ListEpisodeViewCell: View {
    let episode: Episode

    var body: some View {
        HStack(alignment: .top) {
            AsyncImage(url: URL(string: episode.imageUrl ?? "")) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .cornerRadius(24)
                        .clipped()
                } else {
                    Image(systemName: "waveform.badge.mic")
                        .frame(width: 100, height: 100)
                        .cornerRadius(24)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.gray, lineWidth: 0.5)
                        )
                }
            }
            .frame(width: 100, height: 100)
            .cornerRadius(24)

            VStack(alignment: .leading, spacing: 16) {
                Spacer()
                    .frame(maxHeight: 4)
                Text(episode.title)
                    .font(.headline)
                    .bold()
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(episode.description)
                    .font(.subheadline)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.leading, 8)
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()
        }
        .frame(alignment: .center)
        Divider()
            .background(Color(.systemGray))
    }
}
