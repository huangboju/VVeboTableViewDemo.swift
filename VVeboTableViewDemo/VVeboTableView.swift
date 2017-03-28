//
//  VVeboTableView.swift
//  VVeboTableViewDemo
//
//  Created by 伯驹 黄 on 2017/3/28.
//  Copyright © 2017年 伯驹 黄. All rights reserved.
//

class VVeboTableView: UITableView {
    fileprivate lazy var datas: [[String: Any]] = []
    fileprivate lazy var needLoadArr: [IndexPath] = []
    fileprivate var scrollToToping = false
    
    override init(frame: CGRect, style: UITableViewStyle) {
        super.init(frame: frame, style: style)
        separatorStyle = .none
        dataSource = self
        delegate = self
        
        loadData()
        reloadData()
    }
    
    func loadContent() {
        if scrollToToping {
            return
        }
        if indexPathsForVisibleRows?.isEmpty ?? true {
            return
        }
        if !visibleCells.isEmpty {
            for cell in visibleCells {
                (cell as? VVeboTableViewCell)?.draw()
            }
        }
    }
    
    //用户触摸时第一时间加载内容
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if !scrollToToping {
            needLoadArr.removeAll()
            loadContent()
        }
        return super.hitTest(point, with: event)
    }
    
    //读取信息
    func loadData() {
        
        guard let temp = (NSArray(contentsOfFile: Bundle.main.path(forResource: "data", ofType: "plist") ?? "") as? [[String: Any]]) else { return }
        for dict in temp {
            guard let user = dict["user"] as? [String: Any] else { continue }
            var data = [String: Any]()
            data["avatarUrl"] = user["avatar_large"]
            data["name"] = user["screen_name"]
            var from = dict["source"] as? String ?? ""
            if from.length > 6 {
                let start = from.index(of: "\">") + 2
                let end = from.index(of: "</a>")
                from = from.substring(fromIndex: start, toIndex: end)
            } else {
                from = "未知"
            }
            data["time"] = "2015-05-25"
            data["from"] = from
            setComments(from: dict, to: &data)
            setReposts(from: dict, to: &data)
            data["text"] = dict["text"]

            if let retweet = dict["retweeted_status"] as? [String: Any] {
                var subData = [String: Any]()
                guard let user = retweet["user"] as? [String: Any] else { continue }
                subData["avatarUrl"] = user["avatar_large"]
                subData["name"] = user["screen_name"]
                
                subData["text"] = "\(subData["name"] ?? ""): \(retweet["text"] ?? "")"
                setPicUrls(from: retweet, to: &subData)

                do {
                    let width = UIScreen.screenWidth - SIZE_GAP_LEFT * 2
                    let size = (subData["text"] as? String ?? "").sizeWithConstrained(to: width, fromFont: FontWithSize(SIZE_FONT_SUBCONTENT), lineSpace: 5)
                    var sizeHeight = size.height + 0.5
                    subData["textRect"] =
                        subData["textRect"] = CGRect(x: SIZE_GAP_LEFT, y: SIZE_GAP_BIG, width: width, height: sizeHeight)
                    sizeHeight += SIZE_GAP_BIG
                    if let urls = subData["pic_urls"] as? [String], !urls.isEmpty {
                        sizeHeight += (SIZE_GAP_IMG+SIZE_IMAGE+SIZE_GAP_IMG)
                    }
                    sizeHeight += SIZE_GAP_BIG
                    subData["frame"] = CGRect(x: 0, y: 0, width: UIScreen.screenWidth, height: sizeHeight)
                }
                data["subData"] = subData
            } else {
                setPicUrls(from: dict, to: &data)
            }
            
            do {
                let width = UIScreen.screenWidth - SIZE_GAP_LEFT * 2
                let size = (data["text"] as? String ?? "").sizeWithConstrained(to: width, fromFont: FontWithSize(SIZE_FONT_CONTENT), lineSpace: 5)
                var sizeHeight = (size.height + 0.5)
                data["textRect"] = CGRect(x: SIZE_GAP_LEFT, y: SIZE_GAP_TOP+SIZE_AVATAR+SIZE_GAP_BIG, width: width, height: sizeHeight)
                sizeHeight += SIZE_GAP_TOP+SIZE_AVATAR+SIZE_GAP_BIG
                if let urls = data["pic_urls"] as? [String], urls.count > 0 {
                    sizeHeight += (SIZE_GAP_IMG+SIZE_IMAGE+SIZE_GAP_IMG)
                }

                if let subData = data["subData"] as? [String: Any] {
                    var subData = subData
                    sizeHeight += SIZE_GAP_BIG
                    var frame = subData["frame"] as? CGRect ?? .zero
                    var textRect = subData["textRect"] as? CGRect ?? .zero
                    frame.origin.y = sizeHeight
                    subData["frame"] = frame
                    textRect.origin.y = frame.origin.y + SIZE_GAP_BIG
                    subData["textRect"] = textRect
                    sizeHeight += frame.size.height
                    data["subData"] = subData
                }

                sizeHeight += 30
                data["frame"] = CGRect(x: 0, y: 0, width: UIScreen.screenWidth, height: sizeHeight)
            }
            datas.append(data)
        }
    }
    
    func setComments(from dict: [String: Any], to data: inout [String: Any]) {
        let comments = dict["reposts_count"] as? Double ?? 0
        if comments >= 10000 {
            data["reposts"] = "  \((comments / 10000.0))fw"
        } else {
            if comments > 0 {
                data["reposts"] = "  \(comments)"
            } else {
                data["reposts"] = ""
            }
        }
    }

    func setReposts(from dict: [String: Any], to data: inout [String: Any]) {
        let comments = dict["comments_count"] as? Double ?? 0
        if comments >= 10000 {
            data["comments"] = "  \((comments / 10000.0))fw"
        } else {
            if comments > 0 {
                data["comments"] = "  \(comments)"
            } else {
                data["comments"] = ""
            }
        }
    }

    func setPicUrls(from dict: [String: Any], to data: inout [String: Any]) {
        guard let pic_urls = dict["pic_urls"] as? [String] else { return }
        guard let url = dict["thumbnail_pic"] as? String else { return }
        guard let pic_ids = dict["pic_ids"] as? [String] else { return }
        if pic_ids.count > 1 {
            var typeStr = "jpg"
            if !pic_ids.isEmpty || !url.isEmpty {
                typeStr = url.substring(from: url.length - 3)
            }
            var temp = [[String: String]]()
            for pic_url in pic_ids {
                temp.append([
                    "thumbnail_pic": "http://ww2.sinaimg.cn/thumbnail/\(pic_url).\(typeStr)"
                    ])
            }
            data["pic_urls"] = temp
        } else {
            data["pic_urls"] = pic_urls
        }
    }

    override func removeFromSuperview() {
        for temp in subviews {
            for cell in temp.subviews where cell is VVeboTableViewCell {
                (cell as? VVeboTableViewCell)?.releaseMemory()
            }
        }
        NotificationCenter.default.removeObserver(self)
        datas.removeAll()
        reloadData()
        delegate = nil
        needLoadArr.removeAll()
        super.removeFromSuperview()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension VVeboTableView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datas.count
    }
    
    func draw(cell: VVeboTableViewCell, with indexPath: IndexPath) {
        let data = datas[indexPath.row]
        cell.selectionStyle = .none
        cell.clear()
        cell.data = data
        
        if needLoadArr.count > 0 && needLoadArr.index(of: indexPath) == nil {
            cell.clear()
            return
        }
        if scrollToToping {
            return
        }
        cell.draw()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        draw(cell: cell as! VVeboTableViewCell, with: indexPath)
        return cell
    }
}

extension VVeboTableView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let dict = datas[indexPath.row]
        let rect = dict["frame"] as? CGRect ?? .zero
        return rect.height
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        needLoadArr.removeAll()
    }
    
    //按需加载 - 如果目标行与当前行相差超过指定行数，只在目标滚动范围的前后指定3行加载。
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        guard let cip = indexPathsForVisibleRows?.first,
        let ip = indexPathForRow(at: CGPoint(x: 0, y: targetContentOffset.move().y))
            else { return }
        let skipCount = 8
        if labs(cip.row - ip.row) > skipCount {
            let temp = indexPathsForRows(in: CGRect(x: 0, y: targetContentOffset.move().y, width: frame.width, height: frame.height))
            var arr = [temp]
            if velocity.y < 0 {
                if let indexPath = temp?.last, indexPath.row + 3 < datas.count {
                    (1...3).forEach() {
                        arr.append([IndexPath(row: indexPath.row + $0, section: 0)])
                    }
                }
            } else {
                if let indexPath = temp?.first, indexPath.row > 3 {
                    (1...3).reversed().forEach() {
                        arr.append([IndexPath(row: indexPath.row - $0, section: 0)])
                    }
                }
            }
//            needLoadArr.append(arr)
        }
    }
    
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        scrollToToping = true
        return true
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        scrollToToping = false
        loadContent()
    }
    
    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        scrollToToping = false
        loadContent()
    }
}
