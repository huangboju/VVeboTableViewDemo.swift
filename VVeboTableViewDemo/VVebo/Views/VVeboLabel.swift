//
//  VVeboLabel.swift
//  VVeboTableViewDemo
//
//  Created by 伯驹 黄 on 2017/3/24.
//  Copyright © 2017年 伯驹 黄. All rights reserved.
//

// 对应高亮颜色、正则表达式的key
let kRegexHighlightViewTypeURL = "url"
let kRegexHighlightViewTypeAccount = "account"
let kRegexHighlightViewTypeTopic = "topic"
let kRegexHighlightViewTypeEmoji = "emoji"

// 正则表达式
let URLRegular = "(http|https)://(t.cn/|weibo.com/)+(([a-zA-Z0-9/])*)"
let EmojiRegular = "(\\[\\w+\\])"
let AccountRegular = "@[一-龥a-zA-Z0-9_-]{2,30}"
let TopicRegular = "#[^#]+#"

// 精度处理
func CGFloat_ceil(_ cgfloat: CGFloat) -> CGFloat {
    #if CGFLOAT_IS_DOUBLE
        return ceil(cgfloat)
    #else
        return CGFloat(ceilf(Float(cgfloat)))
    #endif
}

// NSTextAlignment 转换为 CTTextAlignment
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

    // 用于显示绘制text的图片
    private lazy var labelImageView: UIImageView = {
        let labelImageView = UIImageView(frame: CGRect(x: 0, y: -5, width: self.frame.width, height: self.frame.height + 10))
        labelImageView.contentMode = .scaleAspectFit
        labelImageView.tag = Int.min
        labelImageView.clipsToBounds = true
        return labelImageView
    }()

    // 用于显示绘制text高亮时的图片，会叠在labelImageView上面
    private lazy var highlightImageView: UIImageView = {
        let highlightImageView = UIImageView(frame: CGRect(x: 0, y: -5, width: self.frame.width, height: self.frame.height + 10))
        highlightImageView.contentMode = .scaleAspectFit
        highlightImageView.tag = Int.min
        highlightImageView.clipsToBounds = true
        highlightImageView.backgroundColor = UIColor.clear
        return highlightImageView
    }()
    private var highlighting = false
    private var btnLoaded = false // 没有用到
    private var emojiLoaded = false // 没有用到
    private var currentRange = NSRange() // 高亮的range
    private lazy var  highlightColors: [String: UIColor] = [:]
    private lazy var framesDict: [String: CGRect] = [:] // 可以点击高亮的位置
    private var drawFlag: Int = 0 // 判断是否绘制

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
                    // 不需要特殊处理的字符串
                    coloredString.addAttribute(NSAttributedStringKey.foregroundColor, value: UIColor(r: 224, g: 44, b: 86).cgColor, range: match.range)

                    // ???: touchEnd中已处理，这里是否不需要
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: {
//                        // 对高亮颜色点击处理
//                        self.backToNormal()
//                    })
                } else {
                    // 正则中定义需要特殊处理的字符串
                    guard let highlightColor = highlightColors[key] else { continue }
                    coloredString.addAttribute(NSAttributedStringKey.foregroundColor, value: highlightColor, range: match.range)
                }
            }
        }
        return coloredString
    }

    // 核心方法
    func textDidSet(_ text: String?, oldText: String?) {
        // 当 text为nil或者是empty，加labelImageView和highlightImageView设置为nil，结束
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

        // 将文本绘制放入全局队列，以减轻主线程压力
        DispatchQueue.global().async {
            let temp = text

            var size = self.frame.size
            size.height += 10

            // 如果有颜色绘制将会绘制颜色
            let isNotClear = self.backgroundColor != .clear

            /// 第一个参数表示所要创建的图片的尺寸；
            /// 第二个参数用来指定所生成图片的背景是否为不透明，如上我们使用true而不是false，则我们得到的图片背景将会是黑色，显然这不是我想要的；
            /// 第三个参数指定生成图片的缩放因子，这个缩放因子与UIImage的scale属性所指的含义是一致的。传入0则表示让图片的缩放因子根据屏幕的分辨率而变化，所以我们得到的图片不管是在单分辨率还是视网膜屏上看起来都会很好。

            /// 注意这个与UIGraphicsEndImageContext()成对出现
            /// iOS10 中新增了UIGraphicsImageRenderer(bounds: _)
            UIGraphicsBeginImageContextWithOptions(size, isNotClear, 0)

            /// 获取绘制画布
            /// 每一个UIView都有一个layer，每一个layer都有个content，这个content指向的是一块缓存，叫做backing store。
            /// UIView的绘制和渲染是两个过程，当UIView被绘制时，CPU执行drawRect，通过context将数据写入backing store
            /// http://vizlabxt.github.io/blog/2012/10/22/UIView-Rendering/
            guard let context = UIGraphicsGetCurrentContext() else { return }

            if isNotClear {
                /// 这句相当于这两句
                /// self.backgroundColor?.setFill() 设置填充颜色
                /// self.backgroundColor?.setStroke() 设置边框颜色
                self.backgroundColor?.set()
            
                /// 绘制一个实心矩形
                /// stroke(_ rect: CGRect) 用这个方法得到的是边框为你设置颜色的空心矩形
                context.fill(CGRect(origin: .zero, size: size))
            }

            /// 坐标反转，固定写法，因为Core Text中坐标起点是左下角
            context.textMatrix = .identity
            context.translateBy(x: 0, y: size.height) //向上平移
            context.scaleBy(x: 1.0, y: -1.0) //在y轴缩放-1相当于沿着x张旋转180
            
            
            
            //MARK: - 这里属于 Core Text技术

            //Set line height, font, color and break mode
            var minimumLineHeight = self.font.pointSize
            var maximumLineHeight = minimumLineHeight
            var linespace = self.lineSpace

            let font = CTFontCreateWithName((self.font.fontName as CFString?)!, self.font.pointSize, nil)

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

            let attributes: [NSAttributedStringKey: Any] = [
                .font: font,
                .foregroundColor: self.textColor.cgColor,
                .paragraphStyle: style
            ]

            //Create attributed string, with applied syntax highlighting
            let attributedStr = NSMutableAttributedString(string: text, attributes: attributes)

            // 通过正则匹配出需要高亮的子串，设置对应的属性
            let attributedString: CFAttributedString = self.highlightText(attributedStr)

            //Draw the frame
            // 生成framesetter
            // 通过CFAttributedString(NSAttributeString 也可以无缝桥接)进行初始化
            let framesetter = CTFramesetterCreateWithAttributedString(attributedString)

            let rect = CGRect(x: 0, y: 5, width: size.width, height: size.height - 5)

            // 这里应该不需要，因为在Swift中text为let
//            guard temp == text else { return }

            // 确保行高一致，计算所需触摸区域
            // 这里采用的是逐行绘制，因为emoji需要特殊处理（文本高度和间隔不一致）
            self.draw(framesetter: framesetter, attributedString: attributedStr, textRange: CFRangeMake(0, text.length), in: rect, context: context)

            // ???: 上面已经反转
//            context.textMatrix = .identity
//            context.translateBy(x: 0, y: size.height) //向上平移
//            context.scaleBy(x: 1.0, y: -1.0)

            // 新绘制的图
            let screenShotimage = UIGraphicsGetImageFromCurrentImageContext()
            let shotImageSize = screenShotimage?.size ?? .zero
            // 结束绘制
            UIGraphicsEndImageContext()
    
            /// 回到主线程设置绘制文本的图片
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
                } else { //默认状态
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
//                self.debugDraw() // 绘制可触摸区域，主要用于调试
            }
        }
    }

    /// 确保行高一致，计算所需触摸区域
    /// 这里属于Core Text
    /// 推荐文章：
    /// http://www.jianshu.com/p/e52a38e60e7c
    /// https://developer.apple.com/library/content/documentation/StringsTextFonts/Conceptual/CoreText_Programming/Introduction/Introduction.html#//apple_ref/doc/uid/TP40005533
    func draw(framesetter: CTFramesetter, attributedString: NSAttributedString, textRange: CFRange, in rect: CGRect, context: CGContext) {
        let path = CGMutablePath() // 文本绘制路径，你可以自定义为你想要的任何形状
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

    // 通过正则匹配点击的区域是否需要高亮处理
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

    // 电话等打断触摸过程时，会调用这个方法。
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

    deinit {
        print("\(#function, self)")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
