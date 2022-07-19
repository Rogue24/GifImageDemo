//
//  GifDefined.swift
//  GifImageDemo
//
//  Created by aa on 2022/7/18.
//

import SwiftUI
import UIKit

struct GifResource: Equatable {
    let id = UUID()
    let images: [UIImage]
    let duration: TimeInterval
    
    static func == (lhs: GifResource, rhs: GifResource) -> Bool {
        lhs.id == rhs.id
    }
}

enum GifError: Error {
    /// 请求取消
    case requestCancel
    /// 请求失败
    case requestFailed
    /// 文件不存在
    case fileNotExistent
    /// 文件已损坏
    case fileDamaged
    /// 解码失败
    case decodeFailed
}

enum AsyncGifImagePhase {
    /// 加载中
    case loading
    /// 加载成功
    case success(GifImage)
    /// 加载失败
    case failure(GifError)
}
