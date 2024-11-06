//
//  BannerView.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 11. 06..
//

import SwiftUI

extension ExloreView {
    @ViewBuilder
    public func presentAlert(_ error: ErrorMessage) -> some View {
        HStack(spacing: 12) {
            let symbolImage = error.color == .red ? "bolt.trianglebadge.exclamationmark" : error.color == .green ? "bolt.ring.closed" : "bolt.heart"
            
            Image(systemName: symbolImage)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(error.color)
            
            let title = error.text
            
            Text(title)
                .font(.callout)
            
            Spacer(minLength: 0)
            
            Button {
                toastsData.delete(error.id)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
            }
        }
        .foregroundStyle(Color.primary)
        .padding([.vertical, .trailing], 12)
        .padding(.leading, 15)
        .background {
            Capsule()
                .fill(.background)
                /// Shadows
                .shadow(color: .black.opacity(0.06), radius: 3, x: -1, y: -3)
                .shadow(color: .black.opacity(0.06), radius: 2, x: 1, y: 3)
        }
        .padding(.horizontal, 25)
    }

}
