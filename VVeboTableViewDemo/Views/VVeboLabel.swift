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
let AccountRegular = "[\\u4e00-\\u9fa5a-zA-Z0-9_-]{2,30}"
let TopicRegular = "#[^#]+#"

func CTTextAlignmentFromUITextAlignment(_ alignment: NSTextAlignment) -> CTTextAlignment {
    switch alignment {
    case .left: return .left
    case .center: return .center
    case .right: return .right
    default: return .natural
    }
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
    
    private var labelImageView: UIImageView!
    private var highlightImageView: UIImageView!
    private var highlighting = false
    private var btnLoaded = false
    private var emojiLoaded = false
    private var currentRange = NSRange()
    private var highlightColors: [String: UIColor]?
    private var framesDict: [String: CGRect]?
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
        
        labelImageView = UIImageView(frame: CGRect(x: 0, y: -5, width: frame.width, height: frame.height + 10))
        labelImageView.contentMode = .scaleAspectFit
        labelImageView.tag = Int.min
        labelImageView.clipsToBounds = true
        addSubview(labelImageView)
        
        highlightImageView = UIImageView(frame: CGRect(x: 0, y: -5, width: frame.width, height: frame.height + 10))
        highlightImageView.contentMode = .scaleAspectFit
        highlightImageView.tag = Int.min
        highlightImageView.clipsToBounds = true
        highlightImageView.backgroundColor = UIColor.clear
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
        
        let range = NSRange(location: 0, length: string.lenght)
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
                //                var textColor = highlightColors?[key] ?? self.textColor
                let hasImage = labelImageView.image != nil
                if hasImage && currentRange.location != -1 && currentRange.location >= match.range.location && currentRange.length + currentRange.location <= match.range.length + match.range.location {
                    coloredString.addAttribute(String(kCTForegroundColorAttributeName), value: UIColor(r: 224, g: 44, b: 86).cgColor, range: match.range)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: {
                        self.backToNormal()
                    })
                } else {
                    if let highlightColor = self.highlightColors?[key] {
                        coloredString.addAttribute(String(kCTForegroundColorAttributeName), value: highlightColor.cgColor, range: match.range)
                    }
                }
            }
        }
        return coloredString
    }
    
    
    
    func textDidSet(_ text: String?, oldText: String?) {
        guard let text = text, text.isEmpty else {
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
            framesDict?.removeAll()
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
            context.textMatrix = CGAffineTransform.identity
            context.translateBy(x: 0,y: size.height)
            context.scaleBy(x: 1.0,y: -1.0)
            
            //Determine default text color
            let textColor = self.textColor
            
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
                NSForegroundColorAttributeName: textColor.cgColor,
                NSParagraphStyleAttributeName: style
            ]
            
            //Create attributed string, with applied syntax highlighting
            let attributedStr = NSMutableAttributedString(string: text, attributes: attributes)
            
            let attributedString = self.highlightText(attributedStr) as CFAttributedString
            
            //Draw the frame
            let framesetter = CTFramesetterCreateWithAttributedString(attributedString)
            
            let rect = CGRect(x: 0, y: 5, width: size.width, height: size.height - 5)
            
            guard temp == text else { return }
            self.draw(framesetter: framesetter, attributedString: attributedStr, textRange: CFRangeMake(0, text.length), in: rect, context: context)
            context.textMatrix = CGAffineTransform.identity
            context.translateBy(x: 0, y: size.height)
            context.scaleBy(x: 1.0, y: -1.0)
            let screenShotimage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            let shotImageSize = screenShotimage?.size ?? .zero
            DispatchQueue.main.async {
                attributedStr.mutableString.setString("")

                guard self.drawFlag == flag else { return }
                
                if isHighlight {
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
                //                    [self debugDraw]//绘制可触摸区域
            }
        }
    }
    
    //确保行高一致，计算所需触摸区域
    func draw(framesetter: CTFramesetter, attributedString: NSAttributedString, textRange: CFRange, in rect: CGRect, context: CGContext) {
        
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    
    
    
    public func debugDraw() {
        guard let framesDict = framesDict else { return }

        for rect in framesDict.values {
            let temp = UIView(frame: rect)
            let n = UInt32(255)
            temp.backgroundColor = UIColor(r: CGFloat(arc4random() % n), g: CGFloat(arc4random() % n), b: CGFloat(arc4random() % n), a: 0.5)
            addSubview(temp)
        }
    }
    
    public func clear() {
        
    }
    
    private func backToNormal() {
        //    if (!highlighting) {
        //    return
        //    }
        //    highlighting = NO
        //    currentRange = NSMakeRange(-1, -1)
        //    highlightImageView.image = nil
    }
    
    public func touchPoint(_ point: CGPoint) -> Bool {
        return true
    }
    
    override func removeFromSuperview() {
        highlightColors?.removeAll()
        highlightColors = nil
        framesDict?.removeAll()
        framesDict = nil
        highlightImageView.image = nil
        labelImageView.image = nil
        super.removeFromSuperview()
    }
    
    deinit {
        print("\(#function, self)")
    }
}

extension UIColor {
    convenience init(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat = 0) {
        self.init(red: r, green: g, blue: b, alpha: a)
    }
}

extension String {
    var length: Int {
        return characters.count
    }
}
