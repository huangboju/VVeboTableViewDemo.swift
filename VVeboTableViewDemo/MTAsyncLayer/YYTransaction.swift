//
//  YYTransaction.swift
//  YYAsyncLayer
//
//  Created by 伯驹 黄 on 2017/4/11.
//  Copyright © 2017年 伯驹 黄. All rights reserved.
//

private let onceToken = UUID().uuidString

private var transactionSet: Set<YYTransaction>?

func YYTransactionSetup() {
    DispatchQueue.once(token: onceToken) {
        transactionSet = Set()
        /// 获取main RunLoop
        let runloop = CFRunLoopGetMain()
        var observer: CFRunLoopObserver?

        let YYRunLoopObserverCallBack: CFRunLoopObserverCallBack = {_,_,_ in
            if (transactionSet?.count ?? 0) == 0 {
                return
            }
            let currentSet = transactionSet
            transactionSet = Set()
            for item in currentSet! {
                _ = (item.target as? NSObject)?.perform(item.selector)
            }
        }

        /// http://www.jianshu.com/p/6757e964b956
        ///  创建一个RunLoop的观察者
        /// allocator：该参数为对象内存分配器，一般使用默认的分配器kCFAllocatorDefault。或者nil
        /// activities：该参数配置观察者监听Run Loop的哪种运行状态。在示例中，我们让观察者监听Run Loop的所有运行状态。
        /// repeats：该参数标识观察者只监听一次还是每次Run Loop运行时都监听。
        /// order: 观察者优先级，当Run Loop中有多个观察者监听同一个运行状态时，那么就根据该优先级判断，0为最高优先级别。
        /// callout：观察者的回调函数，在Core Foundation框架中用CFRunLoopObserverCallBack重定义了回调函数的闭包。
        /// context：观察者的上下文。 (类似与KVO传递的context，可以传递信息，)因为这个函数创建ovserver的时候需要传递进一个函数指针，而这个函数指针可能用在n多个oberver 可以当做区分是哪个observer的状机态。（下面的通过block创建的observer一般是一对一的，一般也不需要Context，），还有一个例子类似与NSNOtificationCenter的 SEL和 Block方式。
        observer = CFRunLoopObserverCreate(
            kCFAllocatorDefault,
            CFRunLoopActivity.beforeWaiting.rawValue | CFRunLoopActivity.exit.rawValue,
            true, 0xFFFFFF,
            YYRunLoopObserverCallBack,
            nil
        )
        //将观察者添加到主线程runloop的common模式下的观察中
        CFRunLoopAddObserver(runloop, observer, .commonModes)
        observer = nil
    }
}

class YYTransaction: NSObject {

    var target: Any?
    var selector: Selector?
    /**
     Creates and returns a transaction with a specified target and selector.
     
     @param target    A specified target, the target is retained until runloop end.
     @param selector  A selector for target.
     
     @return A new transaction, or nil if an error occurs.
     */

    static func transaction(with target: Any, selector: Selector) -> YYTransaction {
        let t = YYTransaction()
        t.target = target
        t.selector = selector
        return t
    }

    /**
     Commit the trancaction to main runloop.
     
     @discussion It will perform the selector on the target once before main runloop's
     current loop sleep. If the same transaction (same target and same selector) has
     already commit to runloop in this loop, this method do nothing.
     */
    func commit() {
        if target == nil || selector == nil { return }
        YYTransactionSetup()
        transactionSet?.insert(self)
    }

    // 这里不确定
    override var hash: Int {
        let v1 = selector?.hashValue ?? 0
        let v2 = (target as? NSObject)?.hashValue ?? 0
        return v1 ^ v2
    }

    override func isEqual(_ object: Any?) -> Bool {
        if let other = object as? YYTransaction {
            if other == self {
                return true
            }
            return other.selector == selector // TODO: && other.target == target
        } else {
            return false
        }
    }
}
