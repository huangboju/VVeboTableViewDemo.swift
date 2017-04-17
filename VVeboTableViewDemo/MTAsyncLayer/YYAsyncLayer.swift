//
//  YYAsyncLayer.swift
//  YYAsyncLayer
//
//  Created by 伯驹 黄 on 2017/4/11.
//  Copyright © 2017年 伯驹 黄. All rights reserved.
//

let YYAsyncLayerGetReleaseQueue: DispatchQueue = {
    return DispatchQueue.global(qos: .utility)
}()

private let onceToken = UUID().uuidString
/// Global display queue, used for content rendering.
private let MAX_QUEUE_COUNT = 16
private var  queueCount = 0
private var queues = [DispatchQueue](repeating: DispatchQueue(label: ""), count: MAX_QUEUE_COUNT)
private var counter: Int32 = 0
let YYAsyncLayerGetDisplayQueue: DispatchQueue = {
    DispatchQueue.once(token: onceToken) {
        // https://cnbin.github.io/blog/2015/05/21/nsprocessinfo-huo-qu-jin-cheng-xin-xi/
        // 获取进程信息
        queueCount = ProcessInfo().activeProcessorCount
        queueCount = queueCount < 1 ? 1 : queueCount > MAX_QUEUE_COUNT ? MAX_QUEUE_COUNT : queueCount
        for i in 0 ..< queueCount {
            queues[i] = DispatchQueue(label: "com.ibireme.MTkit.render")
        }
    }
    var cur = OSAtomicIncrement32(&counter)
    if cur < 0 {
        cur = -cur
    }
    return queues[Int(cur) % queueCount]
}()

class YYAsyncLayer: CALayer {
    public var displaysAsynchronously = true

    private var _sentinel: YYSentinel!

    private let _onceToken = UUID().uuidString

    override class func defaultValue(forKey key: String) -> Any? {
        if key == "displaysAsynchronously" {
            return true
        } else {
            return super.defaultValue(forKey: key)
        }
    }

    lazy var scale: CGFloat = 0 //global

    override init() {
        super.init()
        DispatchQueue.once(token: _onceToken) {
            scale = UIScreen.main.scale
        }
        contentsScale = scale
        _sentinel = YYSentinel()
    }

    deinit {
        _sentinel?.increase()
    }

    override func setNeedsDisplay() {
        _cancelAsyncDisplay()
        super.setNeedsDisplay()
    }

    override func display() {
        super.contents = super.contents
         _displayAsync(displaysAsynchronously)
    }

    private func _displayAsync(_ async: Bool) {
        /// 如果需要使用异步绘制的地方没有实现该代理，直接返回
        guard let mydelegate = delegate as? YYAsyncLayerDelegate else { return }
        /// 接收来自需要异步绘制类的任务对象
        let task = mydelegate.newAsyncDisplayTask

        /// 如果display闭包为空，直接返回
        if task.display == nil {
            task.willDisplay?(self)
            contents = nil
            task.didDisplay?(self, true)
            return
        }

        // 是否需要异步绘制，默认是开启异步绘制的
        if async {
            /// 绘制将要开始
            task.willDisplay?(self)
            /// https://github.com/ibireme/YYAsyncLayer/issues/6
            /*
                一个Operation/Task对应唯一一个isCancelled，在NSOperation中是函数调用，在这里是这个isCancelled block。所以每次提交到queue的task的isCancelled block是不同的block对象，其中捕获的value的值都是这个task创建时sentinel.value的值，而捕获的sentinel的引用都是这个layer的sentinel的引用，最后在block执行的时候，value的值就是捕获的value，而sentinel.value则可能已经发生了变化。
             */
            let sentinel = _sentinel
            let value = sentinel!.value
            let isCancelled: (() -> Bool) = {
                return value != sentinel!.value
            }
            let size = bounds.size
            let opaque = isOpaque
            let scale = contentsScale
            let backgroundColor = (opaque && self.backgroundColor != nil) ? self.backgroundColor : nil
            /// 太小不绘制
            if size.width < 1 || size.height < 1 {
                var image = contents
                contents = nil
                if image != nil {
                    YYAsyncLayerGetReleaseQueue.async {
                        image = nil
                    }
                }
                task.didDisplay?(self, true)
                return
            }

            /// 将绘制操作放入自定义队列中
            YYAsyncLayerGetDisplayQueue.async {
                if isCancelled() {
                    return
                }
                /// 第一个参数表示所要创建的图片的尺寸；
                /// 第二个参数用来指定所生成图片的背景是否为不透明，如上我们使用true而不是false，则我们得到的图片背景将会是黑色，显然这不是我想要的；
                /// 第三个参数指定生成图片的缩放因子，这个缩放因子与UIImage的scale属性所指的含义是一致的。传入0则表示让图片的缩放因子根据屏幕的分辨率而变化，所以我们得到的图片不管是在单分辨率还是视网膜屏上看起来都会很好。
                
                /// 注意这个与UIGraphicsEndImageContext()成对出现
                /// iOS10 中新增了UIGraphicsImageRenderer(bounds: _)
                UIGraphicsBeginImageContextWithOptions(size, opaque, scale)

                /// 获取绘制画布
                /// 每一个UIView都有一个layer，每一个layer都有个content，这个content指向的是一块缓存，叫做backing store。
                /// UIView的绘制和渲染是两个过程，当UIView被绘制时，CPU执行drawRect，通过context将数据写入backing store
                /// http://vizlabxt.github.io/blog/2012/10/22/UIView-Rendering/
                guard let context = UIGraphicsGetCurrentContext() else { return }
                if opaque {
                    
                    /*
                     成对出现
                     CGContextSaveGState与CGContextRestoreGState的作用
                     
                     使用Quartz时涉及到一个图形上下文，其中图形上下文中包含一个保存过的图形状态堆栈。在Quartz创建图形上下文时，该堆栈是空的。CGContextSaveGState函数的作用是将当前图形状态推入堆栈。之后，您对图形状态所做的修改会影响随后的描画操作，但不影响存储在堆栈中的拷贝。在修改完成后。

                     您可以通过CGContextRestoreGState函数把堆栈顶部的状态弹出，返回到之前的图形状态。这种推入和弹出的方式是回到之前图形状态的快速方法，避免逐个撤消所有的状态修改；这也是将某些状态（比如裁剪路径）恢复到原有设置的唯一方式。
                     */
                    context.saveGState()
                    if backgroundColor == nil || backgroundColor!.alpha < 1 {
                        context.setFillColor(UIColor.white.cgColor) // 设置填充颜色，setStrokeColor为边框颜色

                        context.addRect(CGRect(x: 0, y: 0, width: size.width * scale, height: size.height * scale))
                        context.fillPath() // 填充路径

                        // 上面两句与这句等效
//                        context.fill(CGRect(x: 0, y: 0, width: size.width * scale, height: size.height * scale))
                    }
                    if let backgroundColor = backgroundColor {
                        context.setFillColor(backgroundColor)
                        context.addRect(CGRect(x: 0, y: 0, width: size.width * scale, height: size.height * scale))
                        context.fillPath()
                    }
                    context.restoreGState()
                }

                // 回调绘制
                task.display?(context, size, isCancelled)

                // 如果取消，提前结束绘制
                if isCancelled() {
                    UIGraphicsEndImageContext()
                    DispatchQueue.main.async {
                        task.didDisplay?(self, false)
                    }
                    return
                }

                // 从画布中获取图片，与UIGraphicsEndImageContext()成对出现
                let image = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()

                // 如果取消，提前结束绘制
                if isCancelled() {
                    DispatchQueue.main.async {
                        task.didDisplay?(self, false)
                    }
                    return
                }

                DispatchQueue.main.async {
                    if isCancelled() {
                        task.didDisplay?(self, false)
                    } else {
                        // 绘制成功
                        self.contents = image?.cgImage
                        task.didDisplay?(self, true)
                    }
                }
            }
        } else {
            // 同步绘制
            _sentinel.increase()
            task.willDisplay?(self)
            UIGraphicsBeginImageContextWithOptions(bounds.size, isOpaque, contentsScale)
            guard let context = UIGraphicsGetCurrentContext() else { return }
            if isOpaque {
                var size = bounds.size
                size.width *= contentsScale
                size.height *= contentsScale
                context.saveGState()
                if backgroundColor == nil || backgroundColor!.alpha < 1 {
                    context.setFillColor(UIColor.white.cgColor)
                    context.addRect(CGRect(origin: .zero, size: size))
                    context.fillPath()
                }
                if let backgroundColor = backgroundColor {
                    context.setFillColor(backgroundColor)
                    context.addRect(CGRect(origin: .zero, size: size))
                    context.fillPath()
                }
                context.restoreGState()
            }
            task.display?(context, bounds.size, {return false })
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            contents = image?.cgImage
            task.didDisplay?(self, true)
        }
    }

    private func _cancelAsyncDisplay() {
        _sentinel?.increase()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

protocol YYAsyncLayerDelegate {
    /// This method is called to return a new display task when the layer's contents need update.
    var newAsyncDisplayTask: YYAsyncLayerDisplayTask { get }
}

/**
 A display task used by YYAsyncLayer to render the contents in background queue.
 */
class YYAsyncLayerDisplayTask {
    
    /**
     This block will be called before the asynchronous drawing begins.
     It will be called on the main thread.
     
     @param layer  The layer.
     */
    public var willDisplay: ((CALayer) -> Void)?
    
    /**
     This block is called to draw the layer's contents.
     
     @discussion This block may be called on main thread or background thread,
     so is should be thread-safe.
     
     @param context      A new bitmap content created by layer.
     @param size         The content size (typically same as layer's bound size).
     @param isCancelled  If this block returns `YES`, the method should cancel the
     drawing process and return as quickly as possible.
     */
    public var display: ((_ context: CGContext, _ size: CGSize, _ isCancelled: (() -> Bool)?) -> Void)?

    /**
     This block will be called after the asynchronous drawing finished.
     It will be called on the main thread.
     
     @param layer  The layer.
     @param finished  If the draw process is cancelled, it's `false`, otherwise it's `true`
     */
    public var didDisplay: ((_ layer: CALayer, _ finished: Bool) -> Void)?
}
