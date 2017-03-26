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
