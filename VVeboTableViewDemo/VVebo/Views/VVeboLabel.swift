//
//  VVeboLabel.swift
//  VVeboTableViewDemo
//
//  Created by 伯驹 黄 on 2017/3/24.
//  Copyright © 2017年 伯驹 黄. All rights reserved.
//

let kRegexHighlightViewTypeURL = "url"
let kRegexHighlightViewTypeAccount = "account"
let kRegexHighlightViewTypeTopic = "topic"
let kRegexHighlightViewTypeEmoji = "emoji"

let URLRegular = "(http|https)://(t.cn/|weibo.com/)+(([a-zA-Z0-9/])*)"
let EmojiRegular = "(\\[\\w+\\])"
let AccountRegular = "@[一-龥a-zA-Z0-9_-]{2,30}"
let TopicRegular = "#[^#]+#"

extension DispatchQueue {
    
    private static var _onceTracker = [String]()
    
    public class func once(token: String, block: () -> Void) {
        objc_sync_enter(self); defer { objc_sync_exit(self) }
        
        if _onceTracker.contains(token) {
            return
        }
        
        _onceTracker.append(token)
        block()
    }
}

func CGFloat_ceil(_ cgfloat: CGFloat) -> CGFloat {
    #if CGFLOAT_IS_DOUBLE
        return ceil(cgfloat)
    #else
        return CGFloat(ceilf(Float(cgfloat)))
    #endif
}

func CTTextAlignmentFromUITextAlignment(_ alignment: NSTextAlignment) -> CTTextAlignment {
    switch alignment {
    case .left: return .left
    case .center: return .center
    case .right: return .right
    default: return .natural
    }
}

private let _onceToken = UUID().uuidString

func AccountRegularExpression() -> NSRegularExpression? {
    var accountRegularExpression: NSRegularExpression?
    DispatchQueue.once(token: _onceToken) {
        accountRegularExpression = try? NSRegularExpression(pattern: AccountRegular, options: .caseInsensitive)
    }
    return accountRegularExpression
}

private let onceToken = UUID().uuidString

func TopicRegularExpression() -> NSRegularExpression? {
    var topicRegularExpression: NSRegularExpression?
    DispatchQueue.once(token: onceToken) {
        topicRegularExpression = try? NSRegularExpression(pattern: TopicRegular, options: .caseInsensitive)
    }
    return topicRegularExpression
}

class VVeboLabel : UIView {
    public var text: String? {
        willSet {
            textDidSet(newValue, oldText: text)
        }
    }
    public var textColor: UIColor = UIColor.black
    public var font: UIFont = UIFont(name: "HelveticaNeue-Light", size: 17)!
    public var lineSpace = 5
    public var textAlignment: NSTextAlignment = .left

    private lazy var labelImageView: UIImageView = {
        let labelImageView = UIImageView(frame: CGRect(x: 0, y: -5, width: self.frame.width, height: self.frame.height + 10))
        labelImageView.contentMode = .scaleAspectFit
        labelImageView.tag = Int.min
        labelImageView.clipsToBounds = true
        return labelImageView
    }()
    private lazy var highlightImageView: UIImageView = {
        let highlightImageView = UIImageView(frame: CGRect(x: 0, y: -5, width: self.frame.width, height: self.frame.height + 10))
        highlightImageView.contentMode = .scaleAspectFit
        highlightImageView.tag = Int.min
        highlightImageView.clipsToBounds = true
        highlightImageView.backgroundColor = UIColor.clear
        return highlightImageView
    }()
    private var highlighting = false
    private var btnLoaded = false
    private var emojiLoaded = false
    private var currentRange = NSRange()
    private lazy var  highlightColors: [String: UIColor] = [:]
    private lazy var framesDict: [String: CGRect] = [:] // 可以点击高亮的位置
    private var drawFlag: Int = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        drawFlag = Int(arc4random())

        highlightColors = [
            kRegexHighlightViewTypeAccount: UIColor(r: 106, g: 140, b: 181),
            kRegexHighlightViewTypeURL: UIColor(r: 106, g: 140, b: 181),
            kRegexHighlightViewTypeEmoji: UIColor(r: 106, g: 140, b: 181),
            kRegexHighlightViewTypeTopic: UIColor(r: 106, g: 140, b: 181)
        ]
        addSubview(labelImageView)

        addSubview(highlightImageView)
        
        isUserInteractionEnabled = true
        backgroundColor = UIColor.clear
        clipsToBounds = false
    }

    override var frame: CGRect {
        didSet {
            if labelImageView.image?.size !=  frame.size {
                labelImageView.image = nil
                highlightImageView.image = nil
            }
            let rect = CGRect(x: 0, y: -5, width: frame.width, height: frame.height + 10)
            labelImageView.frame = rect
            highlightImageView.frame = rect
        }
    }

    //高亮处理
    func highlightText(_ coloredString: NSMutableAttributedString) -> NSMutableAttributedString{
        //Create a mutable attribute string to set the highlighting
        let string = coloredString.string

        let range = NSRange(location: 0, length: string.length)
        //Define the definition to use
        let definition = [
            kRegexHighlightViewTypeAccount: AccountRegular,
            kRegexHighlightViewTypeURL: URLRegular,
            kRegexHighlightViewTypeTopic: TopicRegular,
            kRegexHighlightViewTypeEmoji: EmojiRegular,
            ]
        //For each definition entry apply the highlighting to matched ranges
        for (key, expression) in definition {

            guard let matches = try? NSRegularExpression(pattern: expression, options: .dotMatchesLineSeparators).matches(in: string, options: [], range: range) else { continue }
            for match in matches {
                //Get the text color, if it is a custom key and no color was defined, choose black
                let hasImage = labelImageView.image != nil
                if hasImage && currentRange.location != -1 && currentRange.location >= match.range.location && currentRange.length + currentRange.location <= match.range.length + match.range.location {
                    coloredString.addAttribute(NSForegroundColorAttributeName, value: UIColor(r: 224, g: 44, b: 86).cgColor, range: match.range)

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: {
                        self.backToNormal()
                    })
                } else {
                    guard let highlightColor = highlightColors[key] else { continue }
                    coloredString.addAttribute(NSForegroundColorAttributeName, value: highlightColor, range: match.range)
                }
            }
        }
        return coloredString
    }

    func textDidSet(_ text: String?, oldText: String?) {
        guard let text = text, !text.isEmpty else {
            labelImageView.image = nil
            highlightImageView.image = nil
            return
        }

        if text == oldText {
            if !highlighting || currentRange.location == -1 {
                return
            }
        }
        if highlighting && labelImageView.image == nil {
            return
        }
        if !highlighting {
            framesDict.removeAll()
            currentRange = NSRange(location: -1, length: -1)
        }

        let flag = drawFlag
        let isHighlight = highlighting

        DispatchQueue.global().async {
            let temp = text

            var size = self.frame.size
            size.height += 10

            let isNotClear = self.backgroundColor != .clear

            UIGraphicsBeginImageContextWithOptions(size, isNotClear, 0)

            guard let context = UIGraphicsGetCurrentContext() else { return }

            if isNotClear {
                self.backgroundColor?.set()
                context.fill(CGRect(origin: .zero, size: size))
            }
            context.adjustFrameWithY(size.height)

            //Set line height, font, color and break mode
            var minimumLineHeight = self.font.pointSize
            var maximumLineHeight = minimumLineHeight
            var linespace = self.lineSpace

            let font = CTFontCreateWithName(self.font.fontName as CFString?, self.font.pointSize, nil)

            var lineBreakMode = CTLineBreakMode.byWordWrapping
            var alignment = CTTextAlignmentFromUITextAlignment(self.textAlignment)
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
                NSFontAttributeName: font,
                NSForegroundColorAttributeName: self.textColor.cgColor,
                NSParagraphStyleAttributeName: style
            ]

            //Create attributed string, with applied syntax highlighting
            let attributedStr = NSMutableAttributedString(string: text, attributes: attributes)

            let attributedString: CFAttributedString = self.highlightText(attributedStr)

            //Draw the frame
            let framesetter = CTFramesetterCreateWithAttributedString(attributedString)

            let rect = CGRect(x: 0, y: 5, width: size.width, height: size.height - 5)

            guard temp == text else { return }

            self.draw(framesetter: framesetter, attributedString: attributedStr, textRange: CFRangeMake(0, text.length), in: rect, context: context)

            context.adjustFrameWithY(size.height)
            // 新绘制的图
            let screenShotimage = UIGraphicsGetImageFromCurrentImageContext()
            let shotImageSize = screenShotimage?.size ?? .zero
            // 结束绘制
            UIGraphicsEndImageContext()
            DispatchQueue.main.async {
                attributedStr.mutableString.setString("")

                guard self.drawFlag == flag else { return }

                if isHighlight { //点击高亮进入
                    guard self.highlighting else { return }

                    self.highlightImageView.image = nil

                    if self.highlightImageView.frame.width != shotImageSize.width {
                        self.highlightImageView.frame.size.width = shotImageSize.width
                    }
                    if self.highlightImageView.frame.height != shotImageSize.height {
                        self.highlightImageView.frame.size.height = shotImageSize.height
                    }
                    self.highlightImageView.image = screenShotimage
                } else {
                    guard temp == text else { return }
                    if self.labelImageView.frame.width != shotImageSize.width {
                        self.labelImageView.frame.size.width = shotImageSize.width
                    }
                    if self.labelImageView.frame.height != shotImageSize.height {
                        self.labelImageView.frame.size.height = shotImageSize.height
                    }
                    self.highlightImageView.image = nil
                    self.labelImageView.image = nil
                    self.labelImageView.image = screenShotimage
                }
//                self.debugDraw() //绘制可触摸区域
            }
        }
    }

    //确保行高一致，计算所需触摸区域
    func draw(framesetter: CTFramesetter, attributedString: NSAttributedString, textRange: CFRange, in rect: CGRect, context: CGContext) {
        let path = CGMutablePath()
        path.addRect(rect)

        let frame = CTFramesetterCreateFrame(framesetter, textRange, path, nil)

        let lines = CTFrameGetLines(frame)
        let numberOfLines = CFArrayGetCount(lines)
        let truncateLastLine = false //tailMode

        var lineOrigins = [CGPoint](repeating: .zero, count: numberOfLines)
        CTFrameGetLineOrigins(frame, CFRange(location: 0, length: numberOfLines), &lineOrigins)

        for lineIndex in 0 ..< numberOfLines {
            var lineOrigin = lineOrigins[lineIndex]
            lineOrigin = CGPoint(x: CGFloat_ceil(lineOrigin.x), y: CGFloat_ceil(lineOrigin.y))

            context.textPosition = lineOrigin

            let line = unsafeBitCast(CFArrayGetValueAtIndex(lines, lineIndex), to: CTLine.self)

            var descent: CGFloat = 0.0
            var ascent: CGFloat = 0.0
            var lineLeading: CGFloat = 0
            CTLineGetTypographicBounds(line, &ascent, &descent, &lineLeading)

            // Adjust pen offset for flush depending on text alignment
            let flushFactor: NSTextAlignment = .left
            var penOffset: CGFloat = 0
            var y: CGFloat = 0

            if lineIndex == numberOfLines - 1 && truncateLastLine {
                // Check if the range of text in the last line reaches the end of the full attributed string
                let lastLineRange = CTLineGetStringRange(line)

                if !(lastLineRange.length == 0 && lastLineRange.location == 0) && lastLineRange.location + lastLineRange.length < textRange.location + textRange.length {
                    // Get correct truncationType and attribute position
                    let truncationType = CTLineTruncationType.end
                    let truncationAttributePosition = lastLineRange.location

                    let truncationTokenString = "@"

                    let truncationTokenStringAttributes = attributedString.attributes(at: truncationAttributePosition, effectiveRange: nil)
    
                    let attributedTokenString = NSAttributedString(string: truncationTokenString, attributes: truncationTokenStringAttributes)
                    let truncationToken = CTLineCreateWithAttributedString(attributedTokenString)

                    // Append truncationToken to the string
                    // because if string isn't too long, CT wont add the truncationToken on it's own
                    // There is no change of a double truncationToken because CT only add the token if it removes characters (and the one we add will go first)
                    let truncationString = attributedString.attributedSubstring(from: NSRange(location: lastLineRange.location, length: lastLineRange.length)).mutableCopy() as! NSMutableAttributedString
                    if lastLineRange.length > 0 {
                        // Remove any newline at the end (we don't want newline space between the text and the truncation token). There can only be one, because the second would be on the next line.

                        let lastCharacter = (truncationString.string as NSString).character(at: (lastLineRange.length - 1))

                        if CharacterSet.newlines.hasMember(inPlane: UInt8(lastCharacter)) {
                            truncationString.deleteCharacters(in: NSRange(location: (lastLineRange.length - 1), length: 1))
                        }
                    }
                    truncationString.append(attributedTokenString)
                    let truncationLine = CTLineCreateWithAttributedString(truncationString)
                    
                    // Truncate the line in case it is too long.
                    let truncatedLine = CTLineCreateTruncatedLine(truncationLine, Double(rect.width), truncationType, truncationToken)

                    penOffset = CGFloat(CTLineGetPenOffsetForFlush(truncatedLine!, CGFloat(flushFactor.rawValue), Double(rect.width)))
                    y = lineOrigin.y - descent - self.font.descender
                    context.textPosition = CGPoint(x: penOffset, y: y)

                    CTLineDraw(truncatedLine!, context)
                } else {
                    penOffset = CGFloat(CTLineGetPenOffsetForFlush(line , CGFloat(flushFactor.rawValue), Double(rect.width)))
                    y = lineOrigin.y - descent - self.font.descender
                    context.textPosition = CGPoint(x: penOffset, y: y)
                    CTLineDraw(line , context)
                }
            } else {
                penOffset = CGFloat(CTLineGetPenOffsetForFlush(line , CGFloat(flushFactor.rawValue), Double(rect.width)))
                y = lineOrigin.y - descent - self.font.descender
                context.textPosition = CGPoint(x: penOffset, y: y)
                CTLineDraw(line, context)
            }
            guard !highlighting && superview != nil else { continue }
            let runs = CTLineGetGlyphRuns(line) as! [CTRun]
            for j in 0 ..< runs.count {
                var runAscent: CGFloat = 0
                var runDescent: CGFloat = 0
                let run = runs[j]

                let attributes = CTRunGetAttributes(run) as! [String: Any]

                guard let fgColor = attributes["NSColor"] else { continue }

                if (fgColor as! CGColor) != textColor.cgColor {
                    let range = CTRunGetStringRange(run)
                    var runRect = CGRect()
                    runRect.size.width = CGFloat(CTRunGetTypographicBounds(run, CFRange(location: 0, length: 0), &runAscent, &runDescent, nil))
                    let offset = CTLineGetOffsetForStringIndex(line, range.location, nil)
                    let height = runAscent
                    runRect = CGRect(x: lineOrigin.x + offset, y: (self.frame.height + 5) - y - height + runDescent / 2, width: runRect.width, height: height)
                    let nRange = NSRange(location: range.location, length: range.length)
                    framesDict[NSStringFromRange(nRange)] = runRect
                }
            }
        }
    }

    public func clear() {
        drawFlag = Int(arc4random())
        self.text = ""
        labelImageView.image = nil
        highlightImageView.image = nil
        removeSubviewExcept(tag: .min)
    }

    func removeSubviewExcept(tag: Int) {
        for subview in subviews where subview.tag != tag {
            if let imageView = subview as? UIImageView {
                imageView.image = nil
            }
            subview.removeFromSuperview()
        }
    }

    public func debugDraw() {
        for rect in framesDict.values {
            let temp = UIView(frame: rect)
            let n = UInt32(255)
            temp.backgroundColor = UIColor(r: CGFloat(arc4random() % n), g: CGFloat(arc4random() % n), b: CGFloat(arc4random() % n), a: 0.5)
            addSubview(temp)
        }
    }

    func highlightWord() {
        highlighting = true
        textDidSet(text, oldText: text)
    }

    private func backToNormal() {
        if !highlighting {
            return
        }
        highlighting = false
        currentRange = NSRange(location: -1, length: -1)
        highlightImageView.image = nil
    }

    public func touchPoint(_ point: CGPoint) -> Bool {
        func matching(range: NSRange, matches: [NSTextCheckingResult]) -> Bool {
            for match in matches {
                if range.location != -1 && range.location >= match.range.location && range.length+range.location<=match.range.length+match.range.location {
                    return true
                }
            }
            return false
        }

        let str = self.text ?? ""
        let length = str.length
        for (key, rect) in framesDict where rect.contains(point) {
            let range = NSRangeFromString(key)
            guard let matches = AccountRegularExpression()?.matches(in: str, options: [], range: NSRange(location: 0, length: length)) else { continue }
            if matching(range: range, matches: matches) {
                return true
            }

            guard let _matches = TopicRegularExpression()?.matches(in: str, options: [], range: NSRange(location: 0, length: length)) else { continue }
            if matching(range: range, matches: _matches) {
                return true
            }
        }
        return false
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let location = touches.first?.location(in: self) ?? .zero
        for (key, rect) in framesDict where rect.contains(location) {
            var range = NSRangeFromString(key)
            range = NSRange(location: range.location, length: range.length - 1)
            currentRange = range
            highlightWord()
            break
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        guard highlighting else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.backToNormal()
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        if highlighting {
            backToNormal()
        }
    }

    override func removeFromSuperview() {
        highlightColors.removeAll()
        framesDict.removeAll()
        highlightImageView.image = nil
        labelImageView.image = nil
        super.removeFromSuperview()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        print("\(#function, self)")
    }
}
