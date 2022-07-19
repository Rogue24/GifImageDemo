//
//  Model.swift
//  GifImageDemo
//
//  Created by aa on 2022/7/18.
//

import SwiftUI

struct Gif: Identifiable {
    let id = UUID()
    let tag: String
    let url: URL
    let contentMode: UIView.ContentMode
    var isReload = false
}

enum Operation {
    case backward
    case reload(_ isLoading: Bool)
    case forward
    case animation(_ isAnimating: Bool)
    
    @ViewBuilder
    var label: some View {
        switch self {
        case .backward:
            Image(systemName: "arrow.backward")
        case let .reload(isLoading):
            if isLoading {
                ProgressView()
            } else {
                Image(systemName: "goforward")
            }
        case .forward:
            Image(systemName: "arrow.forward")
        case let .animation(isAnimating):
            Image(systemName: "\(isAnimating ? "pause.fill" : "play.fill")")
        }
    }
}
