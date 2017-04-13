//
//  MTSentinel.swift
//  MTAsyncLayer
//
//  Created by 伯驹 黄 on 2017/4/11.
//  Copyright © 2017年 伯驹 黄. All rights reserved.
//

import UIKit


/**
 YYSentinel is a thread safe incrementing counter.
 It may be used in some multi-threaded situation.
 */
class MTSentinel {
    private var _value: Int32 = 0
    /// Returns the current value of the counter.
    public var value: Int32 {
        return _value
    }

    /// Increase the value atomically.
    /// @return The new value.
    @discardableResult
    public func increase() -> Int32 {
        return OSAtomicIncrement32(&_value)
    }
}
