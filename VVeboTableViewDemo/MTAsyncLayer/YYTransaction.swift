//
//  MTTransaction.swift
//  YYAsyncLayer
//
//  Created by 伯驹 黄 on 2017/4/11.
//  Copyright © 2017年 伯驹 黄. All rights reserved.
//

private let onceToken = UUID().uuidString

private var transactionSet: Set<MTTransaction>?


let MTRunLoopObserverCallBack: CFRunLoopObserverCallBack = {_,_,_ in 
    if (transactionSet?.count ?? 0) == 0 {
        return
    }
    let currentSet = transactionSet
    transactionSet = Set()
    for item in currentSet! {
        _ = (item.target as? NSObject)?.perform(item.selector)
    }
}
func MTTransactionSetup() {
    DispatchQueue.once(token: onceToken) {
        transactionSet = Set()
        let runloop = CFRunLoopGetMain()
        var observer: CFRunLoopObserver?
        observer = CFRunLoopObserverCreate(kCFAllocatorDefault, CFRunLoopActivity.beforeWaiting.rawValue | CFRunLoopActivity.exit.rawValue, true, 0xFFFFFF, MTRunLoopObserverCallBack, nil)
        CFRunLoopAddObserver(runloop, observer, .commonModes)
        observer = nil
    }
}

class MTTransaction: NSObject {

    var target: Any?
    var selector: Selector?
    /**
     Creates and returns a transaction with a specified target and selector.
     
     @param target    A specified target, the target is retained until runloop end.
     @param selector  A selector for target.
     
     @return A new transaction, or nil if an error occurs.
     */

    static func transaction(with target: Any, selector: Selector) -> MTTransaction {
        let t = MTTransaction()
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
        MTTransactionSetup()
        transactionSet?.insert(self)
    }

    override func isEqual(_ object: Any?) -> Bool {
        if let other = object as? MTTransaction {
            if other == self {
                return true
            }
            return other.selector == selector // TODO: && other.target == target
        } else {
            return false
        }
    }
}
