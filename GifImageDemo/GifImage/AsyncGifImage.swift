//
//  AsyncGifImage.swift
//  GifImageDemo
//
//  Created by 周健平 on 2022/7/13.
//

import SwiftUI

struct AsyncGifImage<Content>: View where Content : View {
    var url: URL?
    var contentMode: UIView.ContentMode = .scaleAspectFill
    var transaction: Transaction = Transaction()
    @Binding var isAnimating: Bool
    @Binding var isReLoad: Bool
    @ViewBuilder var content: (AsyncGifImagePhase) -> Content
    
    @State private var phase: AsyncGifImagePhase = .loading
    @State private var isLoading = false
    @State private var isLoaded = false
    @State private var task: Task<Void, Never>? = nil
    @State private var gifError: GifError? = nil
    @State private var resource: GifResource? = nil
    
    var body: some View {
        content(phase)
            .onAppear() {
                guard !isLoaded, !isLoading else { return }
                task?.cancel()
                task = Task {
                    isLoading = false
                    isLoaded = false
                    await reloadGif(url)
                }
            }
            .onChange(of: url) { [url] newValue in
                guard url != newValue else { return }
                task?.cancel()
                task = Task {
                    isLoading = false
                    isLoaded = false
                    await reloadGif(newValue)
                }
            }
            .onChange(of: isReLoad) { newValue in
                guard newValue, !isLoading else { return }
                task?.cancel()
                task = Task {
                    isLoading = false
                    isLoaded = false
                    await reloadGif(url)
                }
            }
            .onChange(of: resource) { [resource] newValue in
                guard resource != newValue else { return }
                withTransaction(transaction) {
                    guard let kResource = newValue, kResource.images.count > 0 else {
                        phase = .failure(gifError ?? .fileNotExistent)
                        return
                    }
                    phase = .success(GifImage(resource: kResource,
                                              contentMode: contentMode,
                                              isAnimating: $isAnimating))
                }
            }
    }
    
    private func reloadGif(_ url: URL?) async {
        guard !isLoaded, !isLoading else { return }
        isLoading = true
        
        // 非本地的才切换为加载中状态
        if let url = url, !url.isFileURL {
            withTransaction(transaction) {
                phase = .loading
            }
        }
        
        var resource: GifResource? = nil
        var gifError: GifError? = nil
        do {
            resource = try await UIImage.decodeGif(withUrl: url)
        } catch {
            gifError = error as? GifError
        }
        
        if let error = gifError, error == GifError.requestCancel {
            // [url变动]或[重载]会主动取消上个请求，此时已经开始了新的请求，
            // 以新的请求为准，停止上个请求的后续操作。
            return
        }
        
        isLoading = false
        isLoaded = true
        isReLoad = false
        task = nil
        
        self.gifError = gifError
        self.resource = resource
        
//        withTransaction(transaction) {
//            guard let resource = resource, resource.images.count > 0 else {
//                phase = .failure(gifError ?? .fileNotExistent)
//                return
//            }
//            phase = .success(GifImage(resource: resource,
//                                      contentMode: contentMode,
//                                      isAnimating: $isAnimating))
//        }
    }
}
