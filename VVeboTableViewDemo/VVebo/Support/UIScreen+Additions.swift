//
//  UIScreen+Additions.swift
//  VVeboTableViewDemo
//
//  Created by 伯驹 黄 on 2017/3/26.
//  Copyright © 2017年 伯驹 黄. All rights reserved.
//

extension UIScreen {
    static var screenWidth: CGFloat {
        if UIInterfaceOrientationIsLandscape(UIApplication.shared.statusBarOrientation) {
            return UIScreen.main.nativeBounds.height / UIScreen.main.nativeScale
        } else {
            return UIScreen.main.nativeBounds.width / UIScreen.main.nativeScale
        }
    }
}

extension UIColor {
    convenience init(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat = 1) {
        self.init(red: r / 255, green: g / 255, blue: b / 255, alpha: a)
    }
}

extension CGFloat {
    static var max: CGFloat {
        return CGFloat(HUGE)
    }
}

extension CGContext {
    func adjustFrameWithY(_ y: CGFloat) {
        textMatrix = .identity
        translateBy(x: 0, y: y)
        scaleBy(x: 1.0, y: -1.0)
    }
}
