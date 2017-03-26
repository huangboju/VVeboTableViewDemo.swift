//
//  VVeboTableViewCell.swift
//  VVeboTableViewDemo
//
//  Created by 伯驹 黄 on 2017/3/25.
//  Copyright © 2017年 伯驹 黄. All rights reserved.
//

import Kingfisher

let SIZE_GAP_LEFT: CGFloat = 15
let SIZE_GAP_TOP: CGFloat = 13
let SIZE_AVATAR: CGFloat = 40
let SIZE_GAP_BIG: CGFloat = 10
let SIZE_GAP_IMG: CGFloat = 5
let SIZE_GAP_SMALL: CGFloat = 5
let SIZE_IMAGE: CGFloat = 80
let SIZE_FONT: CGFloat = 17
let SIZE_FONT_NAME: CGFloat = (SIZE_FONT-3)
let SIZE_FONT_SUBTITLE: CGFloat = (SIZE_FONT-8)
let FontWithSize: (CGFloat) -> UIFont =  { UIFont(name: "HelveticaNeue-Light", size: $0)! }
let SIZE_FONT_CONTENT: CGFloat = 17
let SIZE_FONT_SUBCONTENT: CGFloat = (SIZE_FONT_CONTENT-1)

class VVeboTableViewCell : UITableViewCell {
    public var data: [String: Any]? {
        didSet {
            avatarView.setBackgroundImage(nil, for: .normal)
            
            guard let urlStr = data?["avatarUrl"] as? String else { return }
            let url = URL(string: urlStr)
            avatarView.kf.setBackgroundImage(with: url, for: .normal)
        }
    }
    
    private var postBGView: UIImageView!
    private var avatarView: UIButton!
    private var cornerImage: UIImageView!
    private var topLine: UIView!
    private var label: VVeboLabel!
    private var detailLabel: VVeboLabel!
    private var mulitPhotoScrollView: UIScrollView!
    private var drawed = false
    private var drawColorFlag = 0
    private var commentsRect = CGRect.zero
    private var repostsRect = CGRect.zero
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        clipsToBounds = true
        
        postBGView = UIImageView(frame: .zero)
        contentView.insertSubview(postBGView, at: 0)
        
        avatarView = UIButton(type: .custom)
        avatarView.frame = CGRect(x: SIZE_GAP_LEFT, y: SIZE_GAP_TOP, width: SIZE_AVATAR, height: SIZE_AVATAR)
        avatarView.backgroundColor = UIColor(r: 250, g: 250, b: 250)
        avatarView.isHidden = false
        avatarView.tag = Int.max
        avatarView.clipsToBounds = true
        contentView.addSubview(avatarView)
        
        cornerImage = UIImageView(frame: CGRect(x: 0, y: 0, width: SIZE_AVATAR + 5, height: SIZE_AVATAR + 5))
        cornerImage.center = avatarView.center
        cornerImage.image = UIImage(named: "corner_circle")
        cornerImage.tag = Int.max
        contentView.addSubview(cornerImage)
        
        topLine = UIView(frame: CGRect(x: 0, y: frame.height - 0.5, width: UIScreen.screenWidth, height: 0.5))
        topLine.backgroundColor = UIColor(r: 200, g: 200, b: 200)
        topLine.tag = .max
        contentView.addSubview(topLine)
        
        backgroundColor = UIColor(r: 250, g: 250, b: 250)
        
        addLabel()
        
        mulitPhotoScrollView = UIScrollView(frame: .zero)
        mulitPhotoScrollView.scrollsToTop = false
        mulitPhotoScrollView.showsHorizontalScrollIndicator = false
        mulitPhotoScrollView.showsVerticalScrollIndicator = false
        mulitPhotoScrollView.tag = .max;
        mulitPhotoScrollView.isHidden = true
        contentView.addSubview(mulitPhotoScrollView)
        
        let h2 = SIZE_GAP_IMG + SIZE_IMAGE
        
        for i in 0 ..< 9 {
            let g = SIZE_GAP_IMG
            let width = SIZE_IMAGE
            let x = SIZE_GAP_LEFT + (g + width) * CGFloat(i % 3)
            let y = CGFloat(i) / 3 * h2
            
            let thumb1 = UIImageView(frame: CGRect(x: x, y: y + 2, width: SIZE_IMAGE, height: SIZE_IMAGE))
            thumb1.tag = i + 1
            mulitPhotoScrollView.addSubview(thumb1)
        }
        
    }

    override var frame: CGRect {
        didSet {
            contentView.bringSubview(toFront: topLine)
            topLine.frame.origin.y = frame.height - 0.5
        }
    }
    
    func addLabel() {
        if label != nil  {
            label.removeFromSuperview()
            label = nil
        }
        if detailLabel != nil {
            detailLabel = nil
        }
        
        label = VVeboLabel(frame: data?["textRect"] as? CGRect ?? .zero)
        
        label.textColor = UIColor(r: 50, g: 50, b: 50)
        label.backgroundColor = backgroundColor
        contentView.addSubview(label)
        
        detailLabel = VVeboLabel(frame: data?["subTextRect"] as? CGRect ?? .zero)
        detailLabel.font = FontWithSize(SIZE_FONT_SUBCONTENT)
        detailLabel.textColor = UIColor(r: 50, g: 50, b: 50)
        detailLabel.backgroundColor = UIColor(r: 243, g: 243, b: 243)
        contentView.addSubview(detailLabel)
    }
    
    //将主要内容绘制到图片上
    public func draw() {
        if drawed {
            return
        }
        let flag = drawColorFlag
        drawed = true
        DispatchQueue.global().async {
            let rect = self.data?["frame"] as? CGRect ?? .zero
            UIGraphicsBeginImageContextWithOptions(rect.size, true, 0)
            let context = UIGraphicsGetCurrentContext()
            UIColor(r: 250, g: 250, b: 250).set()
            context?.fill(rect)
            
            if let subdata = self.data?["subData"] as? [String: Any] {
                UIColor(r: 243, g: 243, b: 243).set()
                let subFrame = subdata["frame"] as? CGRect ?? .zero
                context?.fill(subFrame)
                UIColor(r: 200, g: 200, b: 200).set()
                context?.fill(CGRect(x: 0, y: subFrame.minY, width: rect.width, height: 0.5))
            }

            do {
                let leftX = SIZE_GAP_LEFT+SIZE_AVATAR+SIZE_GAP_BIG
                let x = leftX
                var y = (SIZE_AVATAR-(SIZE_FONT_NAME+SIZE_FONT_SUBTITLE+6))/2-2+SIZE_GAP_TOP+SIZE_GAP_SMALL-5
                [_data[@"name"] drawInContext:context withPosition:CGPointMake(x, y) andFont:FontWithSize(SIZE_FONT_NAME)
                    andTextColor:[UIColor colorWithRed:106/255.0 green:140/255.0 blue:181/255.0 alpha:1]
                    andHeight:rect.size.height];
                y += SIZE_FONT_NAME + 5
                let fromX = leftX;
                let size = UIScreen.screenWidth - leftX
                NSString *from = [NSString stringWithFormat:@"%@  %@", _data[@"time"], _data[@"from"]];
                [from drawInContext:context withPosition:CGPointMake(fromX, y) andFont:FontWithSize(SIZE_FONT_SUBTITLE)
                andTextColor:[UIColor colorWithRed:178/255.0 green:178/255.0 blue:178/255.0 alpha:1]
                andHeight:rect.size.height andWidth:size];
            }
                
                do {
                    let countRect = CGRect(x: 0, y: rect.height-30,  width: UIScreen.screenWidth, height: 30)
                    UIColor(r: 250, g: 250, b: 250).set()
                    context?.fill(countRect)
                    let alpha = 1

                    let x = UIScreen.screenWidth - SIZE_GAP_LEFT - 10
                    NSString *comments = _data[@"comments"];
                    if (comments) {
                        CGSize size = [comments sizeWithConstrainedToSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) fromFont:FontWithSize(SIZE_FONT_SUBTITLE) lineSpace:5];
                        
                        x -= size.width
                        [comments drawInContext:context withPosition:CGPointMake(x, 8+countRect.origin.y)
                            andFont:FontWithSize(12)
                            andTextColor:[UIColor colorWithRed:178/255.0 green:178/255.0 blue:178/255.0 alpha:1]
                            andHeight:rect.size.height];
                        [[UIImage imageNamed:@"t_comments.png"] drawInRect:CGRectMake(x-5, 10.5+countRect.origin.y, 10, 9) blendMode:kCGBlendModeNormal alpha:alpha];
                        commentsRect = CGRectMake(x-5, self.height-50, [UIScreen screenWidth]-x+5, 50);
                        x -= 20;
                    }
                    
                    NSString *reposts = _data[@"reposts"];
                    if (reposts) {
                        let size = [reposts sizeWithConstrainedToSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) fromFont:FontWithSize(SIZE_FONT_SUBTITLE) lineSpace:5];
                        
                        x -= max(size.width, 5)+SIZE_GAP_BIG;
                        [reposts drawInContext:context withPosition:CGPointMake(x, 8+countRect.origin.y)
                            andFont:FontWithSize(12)
                            andTextColor:[UIColor colorWithRed:178/255.0 green:178/255.0 blue:178/255.0 alpha:1]
                            andHeight:rect.size.height];
                        
                        [[UIImage imageNamed:@"t_repost.png"] drawInRect:CGRectMake(x-5, 11+countRect.origin.y, 10, 9) blendMode:kCGBlendModeNormal alpha:alpha];
                        repostsRect = CGRectMake(x-5, self.height-50, commentsRect.origin.x-x, 50);
                        x -= 20;
                    }
                    
                    [@"•••" drawInContext:context
                    withPosition:CGPointMake(SIZE_GAP_LEFT, 8+countRect.origin.y)
                    andFont:FontWithSize(11)
                    andTextColor:[UIColor colorWithRed:178/255.0 green:178/255.0 blue:178/255.0 alpha:.5]
                    andHeight:rect.size.height];
                    
                    if ([_data valueForKey:@"subData"]) {
                        UIColor(r: 200, g: 200, b: 200).set()
                        context?.fill(CGRect(x: 0, y: rect.height - 30.5, width: rect.width, height: 0.5))
                    }
            }
            
            let temp = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            DispatchQueue.main.async {
                if flag == self.drawColorFlag {
                    self.postBGView.frame = rect
                    self.postBGView.image = nil
                    self.postBGView.image = temp
                }
            }
            self.drawText()
            self.loadThumb()
        }
    }

        //将文本内容绘制到图片上
        func drawText () {
            if label == nil || detailLabel == nil {
                addLabel()
            }
            //        label.frame = [_data[@"textRect"] CGRectValue];
            //        [label setText:_data[@"text"]];
            //        if ([_data valueForKey:@"subData"]) {
            //            detailLabel.frame = [[_data valueForKey:@"subData"][@"textRect"] CGRectValue];
            //            [detailLabel setText:[_data valueForKey:@"subData"][@"text"]];
            //            detailLabel.isHidden = false
            //        }
        }

        func loadThumb() {
//            float y = 0;
//            NSArray *urls;
//            if ([_data valueForKey:@"subData"]) {
//                CGRect subPostRect = [_data[@"subData"][@"textRect"] CGRectValue];
//                y = subPostRect.origin.y+subPostRect.size.height+SIZE_GAP_BIG;
//                urls = [_data valueForKey:@"subData"][@"pic_urls"];
//            } else {
//                CGRect postRect = [_data[@"textRect"] CGRectValue];
//                y = postRect.origin.y+postRect.size.height+SIZE_GAP_BIG;
//                urls = _data[@"pic_urls"];
//            }
//            if (urls.count>0) {
//                mulitPhotoScrollView.hidden = NO;
//                mulitPhotoScrollView.y = y;
//                mulitPhotoScrollView.frame = CGRectMake(0, y, [UIScreen screenWidth], SIZE_GAP_IMG+((SIZE_GAP_IMG+SIZE_IMAGE)*(urls.count)));
//                for (NSInteger i=0; i<9; i++) {
//                    UIImageView *thumbView = (UIImageView *)[mulitPhotoScrollView viewWithTag:i+1];
//                    thumbView.contentMode = UIViewContentModeScaleAspectFill;
//                    thumbView.backgroundColor = [UIColor lightGrayColor];
//                    thumbView.clipsToBounds = YES;
//                    if (i<urls.count) {
//                        thumbView.frame = CGRectMake(SIZE_GAP_LEFT+(SIZE_GAP_IMG+SIZE_IMAGE)*i, .5, SIZE_IMAGE, SIZE_IMAGE);
//                        thumbView.hidden = NO;
//                        NSDictionary *url = urls[i];
//                        [thumbView sd_setImageWithURL:[NSURL URLWithString:url[@"thumbnail_pic"]]];
//                    } else {
//                        thumbView.hidden = YES;
//                    }
//                }
//                float cw = SIZE_GAP_LEFT*2+(SIZE_GAP_IMG+SIZE_IMAGE)*urls.count;
//                if (cw<self.width) {
//                    cw = self.width;
//                }
//                if (mulitPhotoScrollView.contentSize.width!=cw) {
//                    mulitPhotoScrollView.contentSize = CGSizeMake(cw, 0);
//                }
//            }
        }
        
        public func clear() {
            if !drawed {
                return
            }
            postBGView.frame = .zero
            postBGView.image = nil
            label.clear()
            if !detailLabel.isHidden {
                detailLabel.isHidden = true
                detailLabel.clear()
            }
            for thumb1 in mulitPhotoScrollView.subviews {
                if !thumb1.isHidden {
                    (thumb1 as? UIImageView)?.kf.cancelDownloadTask()
                }
            }
            if mulitPhotoScrollView.contentOffset.x != 0 {
                mulitPhotoScrollView.contentOffset = .zero
            }
            mulitPhotoScrollView.isHidden = true
            drawColorFlag = Int(arc4random())
            drawed = false
        }
        
        public func releaseMemory() {
            NotificationCenter.default.removeObserver(self)
            //	if ([self.delegate keepCell:self]) {
            //		return;
            //	}
            clear()
            super.removeFromSuperview()
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
            print("postview dealloc \(self)")
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
}
