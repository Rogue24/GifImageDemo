//
//  GifImage.swift
//  GifImageDemo
//
//  Created by 周健平 on 2022/7/13.
//

import SwiftUI
import UIKit

struct GifImage: UIViewRepresentable {
    var resource: GifResource?
    var contentMode: UIView.ContentMode = .scaleAspectFill
    @Binding var isAnimating: Bool
    
    func makeUIView(context: Context) -> MyView { MyView() }
    
    func updateUIView(_ uiView: MyView, context: Context) {
        uiView.contentMode = contentMode
        uiView.updateGifResource(resource, isAnimating)
    }
}

extension GifImage {
    class MyView: UIView {
        private let imageView = UIImageView()
        private var resource: GifResource?
        
        init() {
            super.init(frame: .zero)
            clipsToBounds = true
            
            imageView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(imageView)
            NSLayoutConstraint.activate([
                imageView.widthAnchor.constraint(equalTo: widthAnchor),
                imageView.heightAnchor.constraint(equalTo: heightAnchor),
            ])
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override var contentMode: UIView.ContentMode {
            set { imageView.contentMode = newValue }
            get { imageView.contentMode }
        }
        
        func updateGifResource(_ resource: GifResource?, _ isAnimating: Bool) {
            let isSame = self.resource == resource
            self.resource = resource
            
            if let resource = resource {
                if isAnimating {
                    guard !isSame || !imageView.isAnimating else { return }
                    imageView.animationImages = resource.images
                    imageView.animationDuration = resource.duration
                    imageView.startAnimating()
                } else {
                    imageView.stopAnimating()
                    imageView.animationImages = nil
                    imageView.animationDuration = 0
                    imageView.image = resource.images[0]
                }
            } else {
                imageView.stopAnimating()
                imageView.animationImages = nil
                imageView.animationDuration = 0
            }
        }
    }
}
