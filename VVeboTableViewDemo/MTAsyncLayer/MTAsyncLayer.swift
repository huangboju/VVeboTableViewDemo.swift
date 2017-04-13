//
//  MTAsyncLayer.swift
//  MTAsyncLayer
//
//  Created by 伯驹 黄 on 2017/4/11.
//  Copyright © 2017年 伯驹 黄. All rights reserved.
//

protocol MTAsyncLayerDelegate {
    /// This method is called to return a new display task when the layer's contents need update.
    var newAsyncDisplayTask: MTAsyncLayerDisplayTask { get }
}

let MTAsyncLayerGetReleaseQueue: DispatchQueue = {
    return DispatchQueue.global(qos: .utility)
}()

private let onceToken = UUID().uuidString
/// Global display queue, used for content rendering.
private let MAX_QUEUE_COUNT = 16
private var  queueCount = 0
private var queues = [DispatchQueue](repeating: DispatchQueue(label: ""), count: MAX_QUEUE_COUNT)
private var counter: Int32 = 0
let MTAsyncLayerGetDisplayQueue: DispatchQueue = {
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

class MTAsyncLayer: CALayer {
    public var displaysAsynchronously = true

    private var _sentinel: MTSentinel!

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
        _sentinel = MTSentinel()
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
        guard let mydelegate = delegate as? MTAsyncLayerDelegate else { return }
        let task = mydelegate.newAsyncDisplayTask
        if task.display == nil {
            task.willDisplay?(self)
            contents = nil
            task.didDisplay?(self, true)
            return
        }

        if async {
            task.willDisplay?(self)
            let sentinel = _sentinel
            let value = sentinel!.value
            let isCancelled: (() -> Bool) = {
                return value != sentinel!.value
            }
            let size = bounds.size
            let opaque = isOpaque
            let scale = contentsScale
            let backgroundColor = (opaque && self.backgroundColor != nil) ? self.backgroundColor : nil
            if size.width < 1 || size.height < 1 {
                var image = contents
                contents = nil
                if image != nil {
                    MTAsyncLayerGetReleaseQueue.async {
                        image = nil
                    }
                }
                task.didDisplay?(self, true)
                return
            }

            MTAsyncLayerGetDisplayQueue.async {
                if isCancelled() {
                    return
                }
                UIGraphicsBeginImageContextWithOptions(size, opaque, scale)
                guard let context = UIGraphicsGetCurrentContext() else { return }
                if opaque {
                    context.saveGState()
                    if backgroundColor == nil || backgroundColor!.alpha < 1 {
                        context.setFillColor(UIColor.white.cgColor)
                        context.addRect(CGRect(x: 0, y: 0, width: size.width * scale, height: size.height * scale))
                        context.fillPath()
                    }
                    if let backgroundColor = backgroundColor {
                        context.setFillColor(backgroundColor)
                        context.addRect(CGRect(x: 0, y: 0, width: size.width * scale, height: size.height * scale))
                        context.fillPath()
                    }
                    context.restoreGState()
                }
                task.display?(context, size, isCancelled)
                if isCancelled() {
                    UIGraphicsEndImageContext()
                    DispatchQueue.main.async {
                        task.didDisplay?(self, false)
                    }
                    return
                }
                let image = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
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
                        self.contents = image?.cgImage
                        task.didDisplay?(self, true)
                    }
                }
            }
        } else {
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

/**
 A display task used by MTAsyncLayer to render the contents in background queue.
 */
class MTAsyncLayerDisplayTask {
    
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
