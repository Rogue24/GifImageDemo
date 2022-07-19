//
//  ContentView.swift
//  GifImageDemo
//
//  Created by 周健平 on 2022/7/13.
//

import SwiftUI

struct ContentView: View {
    @State var resource: GifResource? = nil
    
    @State var gifs = [
        Gif(tag: "#1", url: URL(fileURLWithPath: Bundle.main.path(forResource: "Cat1", ofType: "gif")!), contentMode: .scaleAspectFill),
        Gif(tag: "#2", url: URL(fileURLWithPath: Bundle.main.path(forResource: "Cat2", ofType: "gif")!), contentMode: .scaleAspectFill),
        Gif(tag: "#3", url: URL(string: "https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/e0ad903a17614d78890f5a8cf4fc3246~tplv-k3u1fbpfcp-zoom-1.image")!, contentMode: .scaleAspectFit),
        Gif(tag: "#4", url: URL(string: "https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/ae0a01c60dc44c3fa1fe662de93c1f02~tplv-k3u1fbpfcp-watermark.image")!, contentMode: .scaleAspectFit),
    ]
    
    @State var isAnimating = true
    @State var operations: [Operation] = [
        .backward,
        .reload(false),
        .forward,
        .animation(true),
    ]
    
    var body: some View {
        VStack {
            title("GifImage")
            gifImage
                .padding(.bottom, 16)
            
            title("AsyncGifImage")
            asyncGifImages
            operationBar
        }
        .background(Image("Blob 1").offset(x: 200, y: -100))
        .onChange(of: isAnimating) { newValue in
            operations[3] = .animation(newValue)
        }
        .task {
            resource = try? await UIImage.decodeGif(fromBundle: "Ayaka")
        }
    }
}

extension ContentView {
    func title(_ text: String) -> some View {
        Text(text)
            .font(.footnote.weight(.semibold))
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, 16)
    }
    
    var gifImage: some View {
        GifImage(resource: resource,
                 contentMode: .scaleAspectFill,
                 isAnimating: .constant(true))
            .frame(width: 150, height: 150)
            .background(.ultraThinMaterial)
            .mask(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 10)
    }
    
    var asyncGifImages: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 16)], spacing: 16) {
            ForEach(Array(gifs.enumerated()), id: \.offset) { index, gif in
                ZStack(alignment: .topLeading) {
                    AsyncGifImage(url: gif.url,
                                  contentMode: gif.contentMode,
                                  transaction: Transaction(animation: .easeInOut),
                                  isAnimating: $isAnimating,
                                  isReLoad: $gifs[index].isReload) { phase in
                        switch phase {
                        // 请求中
                        case .loading: ProgressView()
                        // 请求成功
                        case let .success(image): image
                        // 请求失败
                        case .failure: Text("Failured").font(.body.weight(.bold))
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    Text(gif.tag)
                        .font(.system(size: 15))
                        .foregroundColor(.primary)
                        .frame(width: 30, height: 30)
                        .background(.pink)
                        .clipShape(Circle())
                        .padding()
                }
                .frame(height: 200)
                .frame(minWidth: 160)
                .background(.ultraThinMaterial)
                .mask(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
    }
    
    var operationBar: some View {
        HStack {
            ForEach(Array(operations.enumerated()), id: \.offset) { index, operation in
                Button {
                    switch operation {
                    case .backward:
                        let gif = gifs.removeFirst()
                        gifs.append(gif)
                        
                    case let .reload(isLoading):
                        guard !isLoading else { return }
                        gifs = gifs.map {
                            var gif = $0
                            gif.isReload = true
                            return gif
                        }
                        
                    case .forward:
                        let gif = gifs.removeLast()
                        gifs.insert(gif, at: 0)
                        
                    case let .animation(isAnimating):
                        self.isAnimating = !isAnimating
                    }
                } label: {
                    operation.label
                }
                .frame(width: 50, height: 50)
                .background(.blue)
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                .accentColor(.white)
            }
        }
        .padding(8)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
