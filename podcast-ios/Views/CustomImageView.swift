//
//  CustomImageView.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 11. 04..
//

import SwiftUI
import Kingfisher

struct PodcastCardImageView: View {
    var post: Catagory
    var body: some View {
        GeometryReader {
            let size = $0.size
            Image(uiImage: post.image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .cornerRadius(10)
                .frame(width: size.width, height: size.height)
        }
    }
}
