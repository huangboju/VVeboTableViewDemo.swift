//
//  LazyTableView.swift
//  VVeboTableViewDemo
//
//  Created by 伯驹 黄 on 2017/4/10.
//  Copyright © 2017年 伯驹 黄. All rights reserved.
//

class LazyTableView: UITableView {
    fileprivate lazy var datas: [NSMutableDictionary?] = []
    fileprivate var targetRect: CGRect?

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

    func loadVisibleCells() {
        guard let cells = visibleCells as? [VVeboTableViewCell] else { return }
        for cell in cells {
            guard let indexPath = indexPath(for: cell) else { continue }
            draw(cell: cell, with: indexPath)
        }
    }

    func draw(cell: VVeboTableViewCell, with indexPath: IndexPath) {
        let data = datas[indexPath.row]
        cell.selectionStyle = .none
        cell.clear()
        cell.data = data
        var shouldLoadImage = true
        let cellFrame = rectForRow(at: indexPath)
        if let targetRect = targetRect, !targetRect.intersects(cellFrame) {
            shouldLoadImage = false
        }
        guard shouldLoadImage else { return }
        cell.draw()
    }

    //用户触摸时第一时间加载内容（这里触摸一下会调用两次）
//    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
//        return super.hitTest(point, with: event)
//    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension LazyTableView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datas.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        if let cell = cell as? VVeboTableViewCell {
            draw(cell: cell, with: indexPath)
        }
        return cell
    }
}

extension LazyTableView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let dict = datas[indexPath.row]
        let rect = dict?["frame"] as? CGRect ?? .zero
        return rect.height
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        targetRect = nil
        for cell in visibleCells {
            (cell as? VVeboTableViewCell)?.draw()
        }
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let rect = CGRect(origin: targetContentOffset.move(), size: scrollView.frame.size)
        targetRect = rect
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        targetRect = nil
//        loadVisibleCells()
    }
}
