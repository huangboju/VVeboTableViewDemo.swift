//
//  ViewController.swift
//  VVeboTableViewDemo
//
//  Created by 伯驹 黄 on 2017/3/24.
//  Copyright © 2017年 伯驹 黄. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let tableView = VVeboTableView(frame: view.bounds, style: .plain)
        tableView.register(VVeboTableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        tableView.scrollIndicatorInsets = tableView.contentInset
        view.addSubview(tableView)

        let statusBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 20))
        view.addSubview(statusBar)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

