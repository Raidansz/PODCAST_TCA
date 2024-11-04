//
//  UICoordinator.swift
//  podcast-ios
//
//  Created by Raidan on 2024. 11. 04..
//

import SwiftUI

@Observable
class UICoordinator {
    var scrollView: UIScrollView = .init(frame: .zero)
    var rect: CGRect = .zero
    var selectedItem: Podcast?
    var animationLayer: UIImage?
    var animateView: Bool = false
    var hideLayer: Bool = false
    var hideRootView: Bool = false
    var headerOffset: CGFloat = .zero

    func createVisibleAreaSnapshot() {
        let renderer = UIGraphicsImageRenderer(size: scrollView.bounds.size)
        let image = renderer.image { ctx in
            ctx.cgContext.translateBy(x: -scrollView.contentOffset.x, y: -scrollView.contentOffset.y)
            scrollView.layer.render(in: ctx.cgContext)
        }
        animationLayer = image
    }

    func toogleView(show: Bool, frame: CGRect, post: Podcast) {
        if show {
            selectedItem = post
            rect = frame
            createVisibleAreaSnapshot()
            hideRootView = true
            withAnimation(.easeInOut(duration: 0.3), completionCriteria: .removed) {
                animateView = true
            } completion: {
                self.hideLayer = true
            }
        } else {

            hideLayer = false
            withAnimation(.easeInOut(duration: 0.3), completionCriteria: .removed) {
                animateView = false
            } completion: {
                DispatchQueue.main.async { [weak self] in
                    self?.resetAnimationProperties()
                }
            }
        }
    }

    private func resetAnimationProperties() {
        headerOffset = 0
        selectedItem = nil
        animationLayer = nil
        hideRootView = false
    }
}
