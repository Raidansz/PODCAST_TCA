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
                .serialize(as: .PNG)
                .placeholder({
                    Image(systemName: "waveform.badge.mic")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.gray, lineWidth: 0.5)
                        )
                })
                .onSuccess { result in
                    print("Image loaded from cache: \(result.cacheType)")
                }
                .onFailure { error in
                    print("Error: \(error)")
                }
                .aspectRatio(contentMode: .fit)
                .cornerRadius(10)
                .clipped()
        }
    }
}
