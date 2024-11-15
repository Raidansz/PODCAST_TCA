//
//  ListViewCell.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 09. 20..
//

import SwiftUI
import Kingfisher
import AppLogger

struct ListViewCell: View {
    let imageURL: URL?
    let author: String?
    let title: String?
    let shouldShowIcon: Bool
    let description: String?
    @State var isDisclosed = false
    let randomTheme = getRandomTheme()

    init(imageURL: URL?, author: String?, title: String?, isPodcast: Bool, description: String? = nil) {
        self.imageURL = imageURL
        self.author = author
        self.title = title
        self.shouldShowIcon = isPodcast
        self.description = description
    }

    var body: some View {
        VStack {
            HStack {
                KFImage(imageURL)
                    .resizable()
                    .onSuccess { result in
                        PODLogInfo("Image loaded from cache: \(result.cacheType)")
                    }
                    .onFailure { error in
                        PODLogError("Error: \(error)")
                    }
                    .placeholder {
                        Rectangle()
                            .fill(randomTheme.mainColor)
                            .frame(width: 64, height: 64)
                            .scaledToFill()
                            .cornerRadius(7)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(Color.gray, lineWidth: 0.5)
                            )
                            .clipped()
                    }
                    .setProcessor(
                        DownsamplingImageProcessor(size: CGSize(width: 64, height: 64)) |>
                        JPEGCompressProcessor(compressionQuality: 0.1)
                    )
                    .scaledToFill()
                    .frame(width: 64, height: 64)
                    .cornerRadius(7)
                    .clipped()

                HStack {
                    VStack(alignment: .leading, spacing: 7) {
                        Text(title ?? "")
                            .font(.system(size: 20))
                            .fontWeight(.semibold)
                            .foregroundColor(Color.primary)
                        Text(author ?? "")
                            .font(.system(size: 18))
                            .fontWeight(.regular)
                            .foregroundColor(Color.secondary)
                    }
                    Spacer()
                    VStack(spacing: 0.5) {
                        Image(systemName: "circle.fill")
                            .resizable()
                            .scaledToFit()
                        Image(systemName: "circle.fill")
                            .resizable()
                            .scaledToFit()
                        Image(systemName: "circle.fill")
                            .resizable()
                            .scaledToFit()
                    }
                    .frame(width: 5)
                    .foregroundColor(.white)
                }
                .padding(.leading)
            }
        }
        .contentShape(Rectangle())
    }
}

struct JPEGCompressProcessor: ImageProcessor {
    let identifier = "com.atwsmf.jpegcompressor"
    var compressionQuality: CGFloat

    func process(item: ImageProcessItem, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage? {
        guard case let .image(image) = item else { return nil }
        return image.jpegData(compressionQuality: compressionQuality).flatMap { UIImage(data: $0) }
    }
}
