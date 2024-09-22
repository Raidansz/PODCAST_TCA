//
//  View+Extension.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 09. 20..
//

import SwiftUI

extension View {
    func horizontalList<Data, Content>(
        data: Data,
        spacing: CGFloat = 20,
        content: @escaping (Data.Element) -> Content
    ) -> some View where Data: RandomAccessCollection, Data.Element: Hashable, Content: View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: spacing) {
                ForEach(data, id: \.self) { item in
                    content(item)
                        .shadow(color: .black.opacity(0.3), radius: 10, x: 5, y: 5)
                }
            }
            .padding()
        }
    }
}
