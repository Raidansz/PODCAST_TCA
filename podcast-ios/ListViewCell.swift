//
//  ListViewCell.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 09. 20..
//

import SwiftUI

struct ListViewCell: View {
    let podcast: Item

    var body: some View {
        HStack {
            AsyncImage(url: podcast.image) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .frame(width: 108, height: 96)
                        .cornerRadius(24)
                        .clipped()
                } else {
                    Image(systemName: "waveform.badge.mic")
                        .frame(width: 108, height: 96)
                        .cornerRadius(24)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.gray, lineWidth: 0.5)
                        )

                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(podcast.title)
                    .bold()
                Text("\(podcast.description)")
                    .lineLimit(2)
            }
            .padding(.leading, 8)
            .padding(.trailing, 88)
            Image(systemName: "play.circle.fill")
                .resizable()
                .frame(width: 48, height: 48)
        }
        Divider()
    }
}
