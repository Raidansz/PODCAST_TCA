//
//  ListViewHero.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 09. 20..
//

import SwiftUI

struct ListViewHero: View {
    let podcast: Item

    var body: some View {
        VStack {
            AsyncImage(url: podcast.image) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 300, height: 300)
                        .cornerRadius(20)
                        .clipped()
                } else {
                    Image(systemName: "waveform.badge.mic")
                        .frame(width: 300, height: 300)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.gray, lineWidth: 0.5)
                        )
                }
            }
            .frame(width: 300, height: 300)
            .cornerRadius(20)
        }
    }
}
