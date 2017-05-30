//
//  CRStockRender.swift
//  VVeboTableViewDemo
//
//  Created by 伯驹 黄 on 2017/5/25.
//  Copyright © 2017年 伯驹 黄. All rights reserved.
//

let offSetX: CGFloat = 230

class CRStockRender {
    let _stock: CRStock
    var _renderedGraph: UIImage?
    
    init(stock: CRStock) {
        _stock = stock
    }

    func placeholderImage(of size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)

        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }

        ctx.saveGState()
    
        ctx.scaleBy(x: size.width, y: size.height)
        let deviceColorSpace = CGColorSpaceCreateDeviceRGB()

        let colors = [
            UIColor.white.cgColor,
            UIColor(white: 0.5, alpha: 0.4).cgColor,
            ] as CFArray
        let gradient = CGGradient(colorsSpace: deviceColorSpace, colors: colors, locations: nil)
        ctx.drawLinearGradient(gradient!, start: .zero, end: CGPoint(x: 0, y: 1), options: .drawsAfterEndLocation)
        
        ctx.restoreGState()
        
        UIColor.white.set()

        let style = NSMutableParagraphStyle()
        style.lineBreakMode = .byClipping

        _stock.name.draw(at: CGPoint(x: offSetX, y: 31), withAttributes: [
            NSFontAttributeName: UIFont.boldSystemFont(ofSize: 16),
            NSParagraphStyleAttributeName: style
            ]
        )
        
        UIColor.black.set()

        _stock.name.draw(at: CGPoint(x: offSetX, y: 30), withAttributes: [
            NSFontAttributeName: UIFont.boldSystemFont(ofSize: 16),
            NSParagraphStyleAttributeName: style
            ]
        )

        let output = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return output
    }

    func renderedGraph(of size: CGSize) -> UIImage? {
        if let _renderedGraph = _renderedGraph {
            return _renderedGraph
        }

        UIGraphicsBeginImageContextWithOptions(size, false, 0)

        let desiredGraphSize = CGSize(width: size.width * 2/3, height: size.height * 3/4)

        var maximumSample = CGFloat(-HUGE)
        var minimumSample = CGFloat(HUGE)

        for i in 0 ..< _stock.smoothingLevelCount {
            let dataPoints = _stock.dataPointsWithSmooth(i)
            for dataPoint in dataPoints {
                maximumSample = max(maximumSample, dataPoint)
                minimumSample = min(minimumSample, dataPoint)
            }
        }

        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }

        ctx.saveGState()
        // 为图形上下文设置打开或关闭反锯齿。
        ctx.setShouldAntialias(true)
        ctx.translateBy(x: 10, y: 10)
        ctx.scaleBy(x: desiredGraphSize.width, y: desiredGraphSize.height)

        let deviceColorSpace = CGColorSpaceCreateDeviceRGB()
        let colors = [
            UIColor.white.cgColor,
            UIColor(white: 0.5, alpha: 0.4).cgColor,
            ] as CFArray
        let gradient = CGGradient(colorsSpace: deviceColorSpace, colors: colors, locations: nil)
        ctx.drawLinearGradient(gradient!, start: .zero, end: CGPoint(x: 0, y: 1), options: .drawsAfterEndLocation)


        let radialColors = [
            UIColor(white: 1, alpha: 0.3).cgColor,
            UIColor(white: 0.6, alpha: 0.3).cgColor,
            ] as CFArray
        let radialGradient = CGGradient(colorsSpace: deviceColorSpace, colors: radialColors, locations: nil)
        ctx.drawRadialGradient(radialGradient!, startCenter: CGPoint(x: 0.5, y: 0.2), startRadius: 0, endCenter: CGPoint(x: 0.5, y: 0.2), endRadius: 1, options: .drawsAfterEndLocation)

        let colorTable = [
            UIColor.blue,
            UIColor.green,
            UIColor.yellow,
            UIColor.red,
            UIColor.purple
        ]
        
        for i in 0 ..< _stock.smoothingLevelCount {
            let color = colorTable[i % colorTable.count]
            ctx.setShadow(offset: .zero, blur: 1, color: color.cgColor)
            color.set()
            ctx.beginPath()
            
            let dataPoints = _stock.dataPointsWithSmooth(i)
            var x: CGFloat = 0
            
            for dataPoint in dataPoints {
                let normalizedX = x / CGFloat(dataPoints.count)
                let normalizedY = (dataPoint - minimumSample) / (maximumSample - minimumSample)

                let point = CGPoint(x: normalizedX, y: normalizedY)

                if x == 0 {
                    ctx.move(to: point)
                } else {
                    ctx.addLine(to: point)
                }
                
                x += 1
            }
            ctx.setLineWidth(0.005)
            ctx.strokePath()
        }
        ctx.restoreGState()

        UIColor.white.set()

        let style = NSMutableParagraphStyle()
        style.lineBreakMode = .byClipping
        _stock.name.draw(at: CGPoint(x: offSetX, y: 31), withAttributes: [
            NSFontAttributeName: UIFont.boldSystemFont(ofSize: 16),
            NSParagraphStyleAttributeName: style
            ]
        )

        UIColor.black.set()
        _stock.name.draw(at: CGPoint(x: offSetX, y: 30), withAttributes: [
            NSFontAttributeName: UIFont.boldSystemFont(ofSize: 16),
            NSParagraphStyleAttributeName: style
            ]
        )
        
        _renderedGraph = UIGraphicsGetImageFromCurrentImageContext()
        
        
        UIGraphicsEndImageContext()
        
        return _renderedGraph
    }
    
    var hasRendered: Bool {
        return _renderedGraph != nil
    }
}
