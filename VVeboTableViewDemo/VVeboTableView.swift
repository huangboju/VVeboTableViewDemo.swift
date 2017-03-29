//
//  VVeboTableView.swift
//  VVeboTableViewDemo
//
//  Created by 伯驹 黄 on 2017/3/28.
//  Copyright © 2017年 伯驹 黄. All rights reserved.
//

class VVeboTableView: UITableView {
    fileprivate lazy var datas: [NSMutableDictionary?] = []
    fileprivate lazy var needLoadArr: [IndexPath] = []
    fileprivate var scrollToToping = false
    
    override init(frame: CGRect, style: UITableViewStyle) {
        super.init(frame: frame, style: style)
        separatorStyle = .none
        dataSource = self
        delegate = self
        
        DataPrenstenter.loadData { (dict) in
            self.datas.append(dict)
        }
        
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
        let rect = dict?["frame"] as? CGRect ?? .zero
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
            for item in arr {
                guard let item = item else { continue }
                for indexPath in item {
                    needLoadArr.append(indexPath)
                }
            }
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
