//
//  ListViewCell.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 09. 20..
//

import SwiftUI
import Kingfisher

struct ListViewCell: View {
    let imageURL: URL?
    let author: String?
    let title: String?
    let shouldShowIcon: Bool
    let description: String?
    @State var isDisclosed = false

    init(imageURL: URL?, author: String?, title: String?, isPodcast: Bool, description: String? = nil) {
        self.imageURL = imageURL
        self.author = author
        self.title = title
        self.shouldShowIcon = isPodcast
        self.description = description
    }

    var body: some View {
        VStack {
            HStack(alignment: .top) {
                if shouldShowIcon {
                    KFImage(imageURL)
                        .resizable()
                        .serialize(as: .PNG)
                        .onSuccess { result in
                            PODLogInfo("Image loaded from cache: \(result.cacheType)")
                        }
                        .onFailure { error in
                            PODLogError("Error: \(error)")
                        }
                        .placeholder {
                            Image(systemName: "waveform.badge.mic")
                                .frame(width: 100, height: 100)
                                .cornerRadius(24)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(Color.gray, lineWidth: 0.5)
                                )
                        }
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .cornerRadius(24)
                        .clipped()
                }

                VStack(alignment: .leading, spacing: 16) {
                    Spacer()
                        .frame(maxHeight: 4)
                    Text(title ?? "")
                        .font(.headline)
                        .bold()
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(author ?? "")
                        .font(.subheadline)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.leading, 8)
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

            Divider()
                .background(Color(.systemGray))
        }
        .contentShape(Rectangle())
    }
}
