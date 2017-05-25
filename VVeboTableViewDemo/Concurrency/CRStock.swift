//
//  CRStock.swift
//  VVeboTableViewDemo
//
//  Created by 伯驹 黄 on 2017/5/25.
//  Copyright © 2017年 伯驹 黄. All rights reserved.
//

struct CRStock {
    let name: NSString
    let smoothingLevelCount: Int = 10

    private var points: [[CGFloat]] = []

    init(name: String) {
        for _ in 0 ..< 10 {
            var cols: [CGFloat] = []
            for _ in 0 ..< 20 {
                cols.append(CGFloat(arc4random_uniform(100)))
            }
            points.append(cols)
        }
        self.name = name as NSString
    }

    func dataPointsWithSmooth(_ i: Int) -> [CGFloat] {
        return points[i]
    }
}
