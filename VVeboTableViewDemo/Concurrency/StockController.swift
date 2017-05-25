//
//  StockController.swift
//  VVeboTableViewDemo
//
//  Created by 伯驹 黄 on 2017/5/25.
//  Copyright © 2017年 伯驹 黄. All rights reserved.
//

let ROW_IMAGE_SIZE = CGSize(width: UIScreen.main.bounds.width - 30, height: 80)

class StockController: UIViewController {

    let _queue =  OperationQueue()
    var _stocks: [CRStock] = []
    var _stockNamesToRenders: [NSString: CRStockRender] = [:]
    var _stockNamesToRenderingOperations: [NSString: BlockOperation] = [:]

    fileprivate lazy var tableView: UITableView = {
        let tableView = UITableView(frame: self.view.frame)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 80
        return tableView
    }()

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        _queue.cancelAllOperations()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.white

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        view.addSubview(tableView)

        fetchData()
    }

    func fetchData() {
        let operation = BlockOperation()

        operation.addExecutionBlock { [unowned operation] in
            var datas: [CRStock] = []
            for i in 0 ..< 1000 {
                let tag = String(describing: UnicodeScalar(65 + i)!)
                let stock = CRStock(name: "股票\(tag)")
                datas.append(stock)
            }

            if operation.isCancelled { return }
            
            OperationQueue.main.addOperation {
                self._stocks = datas
                self.tableView.reloadData()
            }
        }
        
        _queue.addOperation(operation)
    }
}

extension StockController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return _stocks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.selectionStyle = .none

        let stock = _stocks[indexPath.row]

        var render = _stockNamesToRenders[stock.name]

        if render?.hasRendered ?? false {
            cell.imageView?.image = render?.renderedGraph(of: ROW_IMAGE_SIZE)
        } else {
            if render == nil {
                render = CRStockRender(stock: stock)
                _stockNamesToRenders[stock.name] = render
                let operation = BlockOperation() {
                    let renderedImage = render?.renderedGraph(of: ROW_IMAGE_SIZE)
                    OperationQueue.main.addOperation {
                        tableView.cellForRow(at: indexPath)?.imageView?.image = renderedImage
                    }
                }
                _queue.addOperation(operation)
                _stockNamesToRenderingOperations[stock.name] = operation
            }
            cell.imageView?.image = render?.placeholderImage(of: ROW_IMAGE_SIZE)
        }

        return cell
    }
}

extension StockController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let stockName = _stocks[indexPath.row].name
        if let operation = _stockNamesToRenderingOperations[stockName] {
            operation.cancel()
            _stockNamesToRenderingOperations.removeValue(forKey: stockName)
        }
    }
}
