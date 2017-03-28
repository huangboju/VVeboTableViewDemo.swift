//
//  String+Additions.swift
//  VVeboTableViewDemo
//
//  Created by 伯驹 黄 on 2017/3/27.
//  Copyright © 2017年 伯驹 黄. All rights reserved.
//

import UIKit

extension String {
    
    var encoding: String {
        //        let unreservedChars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
        //        let unreservedCharset = CharacterSet(charactersIn: unreservedChars)
        //        return addingPercentEncoding(withAllowedCharacters: unreservedCharset) ?? self
        return addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? self
    }
    
    func index(of substring: String) -> Int {
        let range = (self as NSString).range(of: substring, options: .caseInsensitive)
        return range.location == NSNotFound ? -1 : range.location
    }
    
    func substring(fromIndex: Int, toIndex: Int) -> String {
        let range = NSRange(location: fromIndex, length: toIndex - fromIndex)
        return substr(with: range)
    }
    
    var decoding: String {
        return removingPercentEncoding ?? self
    }
    
    func index(from: Int) -> Index {
        return index(startIndex, offsetBy: from)
    }
    
    func substring(from: Int) -> String {
        let fromIndex = index(from: from)
        return substring(from: fromIndex)
    }
    
    func substring(to: Int) -> String {
        return substring(to: index(from: to))
    }
    
    func substr(with range: NSRange) -> String {
        let start = index(startIndex, offsetBy: range.location)
        let end = index(endIndex, offsetBy: range.location + range.length - characters.count)
        return substring(with: start ..< end)
    }
    
    subscript(i: Int) -> String {
        return self[Range(i ..< i + 1)]
    }
    
    subscript(r: Range<Int>) -> String {
        let range = Range(uncheckedBounds: (lower: max(0, min(length, r.lowerBound)),
                                            upper: min(length, max(0, r.upperBound))))
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(start, offsetBy: range.upperBound - range.lowerBound)
        return self[Range(start ..< end)]
    }
    
    func sizeWithConstrained(to size: CGSize, fromFont font1: UIFont, lineSpace: CGFloat) -> CGSize {
        var minimumLineHeight = font1.pointSize
        var maximumLineHeight = minimumLineHeight
        var linespace = lineSpace
        
        let font = CTFontCreateWithName(font1.fontName as CFString?, font1.pointSize, nil)
        var lineBreakMode = CTLineBreakMode.byWordWrapping
        //Apply paragraph settings
        var alignment = CTTextAlignment.left
        let alignmentSetting = [
            CTParagraphStyleSetting(spec: .alignment, valueSize: MemoryLayout.size(ofValue: alignment), value: &alignment),
            CTParagraphStyleSetting(spec: .minimumLineHeight, valueSize: MemoryLayout.size(ofValue: minimumLineHeight), value: &minimumLineHeight),
            CTParagraphStyleSetting(spec: .maximumLineHeight, valueSize: MemoryLayout.size(ofValue: maximumLineHeight), value: &maximumLineHeight),
            CTParagraphStyleSetting(spec: .maximumLineSpacing, valueSize: MemoryLayout.size(ofValue: linespace), value: &linespace),
            CTParagraphStyleSetting(spec: .minimumLineSpacing, valueSize: MemoryLayout.size(ofValue: linespace), value: &linespace),
            CTParagraphStyleSetting(spec: .lineBreakMode, valueSize: MemoryLayout.size(ofValue: 1), value: &lineBreakMode)
        ]
        
        let style = CTParagraphStyleCreate(alignmentSetting, alignmentSetting.count)
        let attributes: [String: Any] = [
            kCTFontAttributeName as String: font,
            kCTParagraphStyleAttributeName as String: style
        ]

        let string = NSMutableAttributedString(string: self, attributes: attributes)
        //    [self clearEmoji:string start:0 font:font1];
        let attributedString = string as CFAttributedString
        let framesetter = CTFramesetterCreateWithAttributedString(attributedString)
        let result = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, string.length), nil, size, nil)
        return result
    }

    func sizeWithConstrained(to width: CGFloat, fromFont font1: UIFont, lineSpace: CGFloat) -> CGSize {
        return sizeWithConstrained(to: CGSize(width: width, height: CGFloat.infinity), fromFont: font1, lineSpace: lineSpace)
    }

    func draw(in context: CGContext, with position: CGPoint, andFont font: UIFont, andTextColor textColor: UIColor, andHeight height: CGFloat, andWidth width: CGFloat){
        let size = CGSize(width: width, height: font.pointSize + 10)
        context.textMatrix = .identity
        context.translateBy(x: 0, y: height)
        context.scaleBy(x: 1.0, y: -1.0)
        
        //Determine default text color
        //Set line height, font, color and break mode
        let font1 = CTFontCreateWithName(font.fontName as CFString?, font.pointSize, nil)
        //Apply paragraph settings
        var minimumLineHeight = font.pointSize
        var maximumLineHeight = minimumLineHeight + 10
        var linespace = 5
        
        var lineBreakMode = CTLineBreakMode.byTruncatingTail
        var alignment = CTTextAlignment.left
        //Apply paragraph settings
        let alignmentSetting = [
            CTParagraphStyleSetting(spec: .alignment, valueSize: MemoryLayout.size(ofValue: alignment), value: &alignment),
            CTParagraphStyleSetting(spec: .minimumLineHeight, valueSize: MemoryLayout.size(ofValue: minimumLineHeight), value: &minimumLineHeight),
            CTParagraphStyleSetting(spec: .maximumLineHeight, valueSize: MemoryLayout.size(ofValue: maximumLineHeight), value: &maximumLineHeight),
            CTParagraphStyleSetting(spec: .maximumLineSpacing, valueSize: MemoryLayout.size(ofValue: linespace), value: &linespace),
            CTParagraphStyleSetting(spec: .minimumLineSpacing, valueSize: MemoryLayout.size(ofValue: linespace), value: &linespace),
            CTParagraphStyleSetting(spec: .lineBreakMode, valueSize: MemoryLayout.size(ofValue: 1), value: &lineBreakMode)
        ]
        
        let style = CTParagraphStyleCreate(alignmentSetting, alignmentSetting.count)
        
        let attributes: [String: Any] = [
            kCTFontAttributeName as String: font1,
            kCTForegroundColorAttributeName as String: textColor.cgColor,
            kCTParagraphStyleAttributeName as String: style
        ]
        //Create path to work with a frame with applied margins
        let path = CGMutablePath()
        path.addRect(CGRect(x: position.x, y: height - position.y - size.height, width: size.width, height: size.height))
        
        //Create attributed string, with applied syntax highlighting
        
        let attributedStr = NSMutableAttributedString(string: self, attributes: attributes)
        let attributedString = attributedStr
        
        //Draw the frame
        let framesetter = CTFramesetterCreateWithAttributedString(attributedString)
        let ctframe = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, CFAttributedStringGetLength(attributedString)), path, nil)
        CTFrameDraw(ctframe,context)
        attributedStr.mutableString.setString("")
        context.textMatrix = .identity
        context.translateBy(x: 0, y: height)
        context.scaleBy(x: 1.0, y: -1.0)
    }
    
    func draw(in context: CGContext, with position: CGPoint, andFont font: UIFont, andTextColor color: UIColor, andHeight height: CGFloat){
        draw(in: context, with: position, andFont: font, andTextColor: color, andHeight: height, andWidth: CGFloat.infinity)
    }
}
