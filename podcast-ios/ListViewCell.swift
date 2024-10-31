//
//  ListViewCell.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 09. 20..
//

import SwiftUI
import CachedAsyncImage
import CoreHaptics

struct ListViewCell: View {
    let imageURL: URLRequest?
    let author: String?
    let title: String?
    let isPodcast: Bool
    let description: String?
    @State var isDisclosed = false

    init(imageURL: URL?, author: String?, title: String?, isPodcast: Bool, description: String? = nil) {
        self.imageURL = URLRequest(url: imageURL ?? URL(filePath: "")!)
        self.author = author
        self.title = title
        self.isPodcast = isPodcast
        self.description = description
    }

    var body: some View {
        VStack {
            HStack(alignment: .top) {
                if isPodcast {
                    CachedAsyncImage(urlRequest: imageURL, urlCache: .imageCache) { phase in
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
                } else {
//                    VStack {
//                        Spacer()
//                        //Image(systemName: "play.circle.fill")
//                        Text("Play")
//                            .overlay(content: {
//                                RoundedRectangle(cornerRadius: 24)
//                                    
//                                    .stroke(lineWidth: 0.5)
//                                    .frame(width: 60, height: 60)
//                            })
//                           // .resizable()
//                            .frame(width: 60, height: 60)
//                            .cornerRadius(24)
//                    }
//                    .padding(.leading, 16)
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
        .onLongPressGesture {
            RootModule.hapticManager.fireHaptic.send()
        }
    }
}

extension URLCache {
    static let imageCache = URLCache(memoryCapacity: 50_000_000, diskCapacity: 2_000_000_000)
}
