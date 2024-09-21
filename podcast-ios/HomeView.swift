//
//  HomeView.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 09. 20..
//

import SwiftUI
import ComposableArchitecture

struct HomeView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    HStack {
                        Image(systemName: "music.mic.circle.fill")
                            .resizable()
                            .frame(width: 45, height: 45)
                        Spacer()
                        ZStack {
                            RoundedRectangle(cornerRadius: 32)
                                .fill(Color(red: 31/255, green: 31/255, blue: 31/255, opacity: 0.08))
                                .frame(width: 45, height: 45)
                            HStack {
                                Image(systemName: "bell.fill")
                                    .resizable()
                                    .frame(width: 21, height: 21)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    ZStack {
                        RoundedRectangle(cornerRadius: 32)
                            .fill(Color(red: 31/255, green: 31/255, blue: 31/255, opacity: 0.08))
                            .frame(width: 364, height: 64)
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.black)
                                .padding(.leading, 15)
                            TextField("Search the podcast here...", text: .constant(""))
                                .padding(.leading, 5)
                        }
                        .frame(width: 364, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 32))
                    }
                    .padding()
                    Section(content: {
                        horizontalList(data: [1, 2, 3, 4, 5]) { _ in
                            ListViewHero()
                        }
                    }, header: {
                        HStack {
                            Text("Trending Podcasts")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                    }
                    )
                    Section(content: {
                        LazyVStack(spacing: 10) {
                            ForEach(0..<6) { _ in
                                ListViewCell()
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.horizontal, 16)
                    }, header: {
                        HStack {
                            Text("Trending Podcasts")
                                .fontWeight(.semibold)
                            Spacer()
                            Text("See more..")
                                .foregroundStyle(Color(.blue))
                        }
                        .padding(.horizontal, 16)
                    }
                    )
                }
            }
        }
    }
}

#Preview {
    HomeView()
}
