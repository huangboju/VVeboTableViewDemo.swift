//
//  MTSentinel.swift
//  YYAsyncLayer
//
//  Created by 伯驹 黄 on 2017/4/11.
//  Copyright © 2017年 伯驹 黄. All rights reserved.
//

import UIKit


/**
 YYSentinel is a thread safe incrementing counter.
 It may be used in some multi-threaded situation.
 */
class YYSentinel {
    private var _value: Int32 = 0
    /// Returns the current value of the counter.
    public var value: Int32 {
        return _value
    }

    /// Increase the value atomically.
    /// @return The new value.
    @discardableResult
    public func increase() -> Int32 {
        // http://southpeak.github.io/2014/10/17/osatomic-operation/
        // OSAtomic原子操作更趋于数据的底层，从更深层次来对单例进行保护。同时，它没有阻断其它线程对函数的访问。
        return OSAtomicIncrement32(&_value)
    }
}
