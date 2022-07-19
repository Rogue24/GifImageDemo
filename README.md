# SwiftUI 播放GIF的实现方案

> 突然发现SwiftUI的Image貌似不支持播放GIF，那就只能自己尝试实现一把。

## 1. SwiftUI中使用UIKit - UIViewRepresentable

`SwiftUI`的`Image`和`AsyncImage`目前发现并不支持播放GIF，既然如此，最简单的实现就是将`UIKit`的`UIImageView`应用到`SwiftUI`中。

在`SwiftUI`中使用`UIKit`控件，就得用到`UIViewRepresentable`协议去实现了：
```swift
import SwiftUI
import UIKit

struct GifImage: UIViewRepresentable {
    // GIF模型
    var resource: GifResource?
    // UIKit的内容显示模式
    var contentMode: UIView.ContentMode = .scaleAspectFill
    // 用于控制GIF的播放/暂停
    @Binding var isAnimating: Bool
    
    func makeUIView(context: Context) -> MyView { MyView() }
    
    func updateUIView(_ uiView: MyView, context: Context) {
        uiView.contentMode = contentMode
        uiView.updateGifResource(resource, isAnimating)
    }
    
    ......
}
```
- `GifResource`是提供GIF的图片、时长的模型类；
- `func makeUIView(context: Context) -> MyView`和`func updateUIView(_ uiView: MyView, context: Context)`是`UIViewRepresentable`协议必须实现的两个函数，前者是创建你想用的`UIView`，后者是用来刷新该`UIView`，系统自己会调用，例如给`resource`属性赋值就会调起，所以我们应该在这个函数中设置内容。

其中`MyView`是我自己自定义的一个`UIView`，上面放着一个`UIImageView`专门播放GIF：
```swift
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
        
    ......
}
```
- 为什么不直接使用`UIImageView`？如果直接使用`UIImageView`，整个视图的尺寸在`SwiftUI`将不受控制（图片多大视图就多大），这个目前我也不知道为什么，但神奇的是在其上面放入`UIImageView`并添加约束即可限制大小。
- 其实这里使用第三方的GIF加载方式（`SDWebImage`、`KingFisher`）应该会更好，本文只是介绍实现方案，所以用最简单的方式实现。

## 2. 解码GIF文件

GIF的解码过程我写在了`UIImage`的分类中，并且使用了`async/await`适配SwiftUI，方便调起：
```swift
import UIKit

extension UIImage {
    static func decodeGif(fromBundle name: String) async throws -> GifResource {
        ......
    }
    
    static func decodeGif(withUrl url: URL?) async throws -> GifResource {
        ......
    }
    
    static func decodeGif(withData data: Data) async throws -> GifResource {
        ......
    }
}
```
- 具体实现可以查看Demo，都是参考`YYKit`的做法然后“翻译”成Swift语言（Maybe会有问题，目前还没发现任何问题，凑合着用）。

## 3. 用起来

```swift
struct ContentView: View {
    @State var resource: GifResource? = nil
    
    var body: some View {
        VStack {
            GifImage(resource: resource, 
                     contentMode: .scaleAspectFit, 
                     isAnimating: .constant(true))
                .frame(width: 150, height: 150)
                .background(.ultraThinMaterial)
                .mask(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 10)
        }
        .task {
            resource = try? await UIImage.decodeGif(fromBundle: "Cat2")
        }
    }
}
```
## 4. AsyncGifImage - 异步加载远程/本地GIF

基于`GifImage`的扩展，一个可异步加载远程/本地GIF的`View`：
```swift
/// 仿照`AsyncImage`
AsyncGifImage(url: url,
              contentMode: .scaleAspectFit,
              transaction: Transaction(animation: .easeInOut),
              isAnimating: $isAnimating,
              isReLoad: $isReload) { phase in
    switch phase {
        // 请求中
        case .loading: ProgressView()
        // 请求成功
        case let .success(image): image // image为GifImage
        // 请求失败
        case .failure: Text("Failure").font(.body.weight(.bold))
    }
}
```
- 让使用者根据`phase`返回不同状态，自定义去提供不同时期的`View`；
- `transaction`：根据`phase`切换不同的`View`的过渡效果；
- `isAnimating`：控制GIF的播放/暂停；
- `isReload`：重载GIF。

# 最终效果

![effect.gif](https://p6-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/e231a83f768b4ed495f15fd9fec06118~tplv-k3u1fbpfcp-watermark.image?)

OK, done.
