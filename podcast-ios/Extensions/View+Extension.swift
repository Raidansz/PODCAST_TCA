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
                }
            }
            .padding()
        }
    }
}

extension View {
    var safeArea: UIEdgeInsets {
        if let safeArea = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.keyWindow?.safeAreaInsets {
            return safeArea
        }
        return .zero
    }

    @ViewBuilder
    func offsetY(result: @escaping (CGFloat) -> Void) -> some View {
        self
            .overlay {
                GeometryReader {
                    let minY = $0.frame(in: .scrollView(axis: .vertical)).minY
                    Color.clear
                        .preference(key: OffsetKey.self, value: minY)
                        .onPreferenceChange(OffsetKey.self, perform: { value in
                            result(value)
                        })
                }
            }
    }
}
