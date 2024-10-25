//
//  ListViewCell.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 09. 20..
//

import SwiftUI
import CachedAsyncImage

struct ListViewCell: View {
    let imageURL: URLRequest?
    let author: String?
    let title: String?
    let isPodcast: Bool
    let description: String?
    @State var isDisclosed = false

    init(imageURL: URL?, author: String?, title: String?, isPodcast: Bool, description: String?) {
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
                    Image(systemName: "play.circle.fill")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .cornerRadius(24)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(lineWidth: 0.5)
                        )
                }

                VStack(alignment: .leading, spacing: 16) {
                    Spacer()
                        .frame(maxHeight: 4)
                    Text(title ?? "")
                        .font(.headline)
                        .bold()
                        .lineLimit(1)
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

            if let safeDescription = description, !isPodcast {
                    ContentView(isDisclosed: $isDisclosed, description: safeDescription)
            }

            Divider()
                .background(Color(.systemGray))
        }
        .onLongPressGesture {
            withAnimation(.spring()) {
                isDisclosed.toggle()
            }
        }
        .onDisappear {
            isDisclosed = false
        }
    }
}

struct ContentView: View {
    @Binding var isDisclosed: Bool
    let description: String
    var body: some View {
        VStack {
            HStack {
                Spacer()
                if isDisclosed {
                    Image(systemName: "chevron.compact.down")
                        .foregroundStyle(Color(.systemBlue))
                        .font(.system(size: 24))
                } else {
                    Image(systemName: "chevron.compact.up")
                        .foregroundStyle(Color(.systemBlue))
                        .font(.system(size: 24))
                }
            }
            VStack {
                Text(description)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.subheadline)
                    .padding()
            }
            .frame(height: isDisclosed ? nil : 0, alignment: .leading)
            .clipped()
            .animation(.spring(), value: isDisclosed)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

extension URLCache {
    static let imageCache = URLCache(memoryCapacity: 512_000_000, diskCapacity: 10_000_000_000)
}
