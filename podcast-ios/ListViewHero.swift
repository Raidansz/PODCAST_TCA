//
//  ListViewHero.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 09. 20..
//

import SwiftUI

struct ListViewHero: View {
    var body: some View {
        VStack {
            AsyncImage(url: URL(string: "https://picsum.photos/331/200")!)
                .aspectRatio(contentMode: .fit)
                .cornerRadius(24)
                .frame(width: 331, height: 200)
        }
    }
}

#Preview {
    ListViewHero()
}
