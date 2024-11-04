//
//  CustomImageView.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 11. 04..
//

import SwiftUI
import Kingfisher

struct PodcastCardImageView: View {
    var post: Podcast
    var body: some View {
        GeometryReader {
            let size = $0.size
            if let image = post.image {
                KFImage(image)
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
                        PODLogInfo("Image loaded from cache: \(result.cacheType)")
                    }
                    .onFailure { error in
                        PODLogError("Error: \(error)")
                    }
                    .aspectRatio(contentMode: .fill)
                    .cornerRadius(10)
                    .frame(width: size.width, height: size.height)
            }
        }
    }
}
