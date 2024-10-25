//
//  ListViewHero.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 09. 20..
//

import SwiftUI
import CachedAsyncImage

struct ListViewHero: View {
    let imageURL: URLRequest?

    init(imageURL: URL?) {
        self.imageURL = URLRequest(url: imageURL ?? URL(filePath: "")!)
    }
    var body: some View {
        VStack {
            CachedAsyncImage(urlRequest: imageURL, urlCache: .imageCache) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .cornerRadius(20)
                        .clipped()
                } else {
                    Image(systemName: "waveform.badge.mic")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.gray, lineWidth: 0.5)
                        )
                }
            }
            .cornerRadius(20)
        }
    }
}
