//
//  ListViewCell.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 09. 20..
//

import SwiftUI

struct ListViewCell: View {
    var body: some View {
        HStack {
            AsyncImage(url: URL(string: "https://picsum.photos/108/96")!)
                .aspectRatio(contentMode: .fit)
                .cornerRadius(24)
                .frame(width: 108, height: 96)
                
            VStack(alignment: .leading, spacing: 8) {
                Text("See Mama Be")
                    .bold()
                Text("Creative Studio")
                Text("15 min")
            }
            .padding(.leading, 8)
            .padding(.trailing, 88)
            Image(systemName: "play.circle.fill")
                .resizable()
                .frame(width: 48, height: 48)
        }
    }
}

#Preview {
    ListViewCell()
}
