//
//  ScrollViewExtractor.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 11. 04..
//

import SwiftUI

struct ScrollViewExtractor: UIViewRepresentable {
    var result: (UIScrollView) -> Void
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        DispatchQueue.main.async {
            if let scrollView = view.superview?.superview?.superview as? UIScrollView {
                result(scrollView)
            }
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

/// Preference Keys
struct OffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
