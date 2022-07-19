//
//  UIImage.Gif.swift
//  GifImageDemo
//
//  Created by 周健平 on 2022/7/13.
//

import UIKit

extension UIImage {
    static func decodeGif(fromBundle name: String) async throws -> GifResource {
        guard let path = Bundle.main.path(forResource: name, ofType: "gif") else {
            throw GifError.fileNotExistent
        }
        return try await decodeGif(withUrl: URL(fileURLWithPath: path))
    }
    
    static func decodeGif(withUrl url: URL?) async throws -> GifResource {
        guard let url = url else {
            throw GifError.fileNotExistent
        }
        
        if url.isFileURL {
            do {
                let data = try Data(contentsOf: url)
                return try await decodeGif(withData: data)
            } catch {
                throw GifError.fileNotExistent
            }
        } else {
            do {
                let data = try await URLSession.shared.data(from: url).0
                return try await decodeGif(withData: data)
            } catch {
                let code = (error as NSError).code
                if code == NSURLErrorCancelled {
                    throw GifError.requestCancel
                } else {
                    throw GifError.requestFailed
                }
            }
        }
    }
    
    static func decodeGif(withData data: Data) async throws -> GifResource {
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else {
            throw GifError.decodeFailed
        }
        
        let count = CGImageSourceGetCount(imageSource)
        
        var images: [UIImage] = []
        var duration: TimeInterval = 0
        
        for i in 0 ..< count {
            guard let cgImg = CGImageSourceCreateImageAtIndex(imageSource, i, nil) else { continue }
            
            let img = UIImage(cgImage: cgImg)
            images.append(img)
            
            guard let proertyDic = CGImageSourceCopyPropertiesAtIndex(imageSource, i, nil) else {
                duration += 0.1
                continue
            }
            
            // CFDictionary的使用：https://www.jianshu.com/p/766acdbbe271
            guard let gifDicValue = CFDictionaryGetValue(proertyDic, Unmanaged.passRetained(kCGImagePropertyGIFDictionary).autorelease().toOpaque()) else {
                duration += 0.1
                continue
            }
            
            let gifDic = Unmanaged<CFDictionary>.fromOpaque(gifDicValue).takeUnretainedValue()
            
            guard let delayValue = CFDictionaryGetValue(gifDic, Unmanaged.passRetained(kCGImagePropertyGIFUnclampedDelayTime).autorelease().toOpaque()) else {
                duration += 0.1
                continue
            }
            
            var delayNum = Unmanaged<NSNumber>.fromOpaque(delayValue).takeUnretainedValue()
            var delay = delayNum.doubleValue
            
            if delay <= Double.ulpOfOne {
                if let delayValue2 = CFDictionaryGetValue(gifDic, Unmanaged.passRetained(kCGImagePropertyGIFDelayTime).autorelease().toOpaque()) {
                    delayNum = Unmanaged<NSNumber>.fromOpaque(delayValue2).takeUnretainedValue()
                    delay = delayNum.doubleValue
                }
            }
            
            if delay < 0.02 {
                delay = 0.1
            }
            
            duration += delay
        }
        
        guard images.count > 0, duration > 0 else {
            throw GifError.fileDamaged
        }
        
        return GifResource(images: images, duration: duration)
    }
}

