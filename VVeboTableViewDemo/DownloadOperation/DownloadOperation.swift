//
//  DownloadOperation.swift
//  VVeboTableViewDemo
//
//  Created by 伯驹 黄 on 2017/5/27.
//  Copyright © 2017年 伯驹 黄. All rights reserved.
//

class DownloadOperation: Operation {
    let url: URL
    var task: URLSessionTask!

    var _isExecuting = false {
        willSet {
            willChangeValue(forKey: "isExecuting")
        }
        didSet {
            didChangeValue(forKey: "isExecuting")
        }
    }
    var _isConcurrent = false {
        willSet {
            willChangeValue(forKey: "isConcurrent")
        }
        didSet {
            didChangeValue(forKey: "isConcurrent")
        }
    }
    var _isFinished = false {
        willSet {
            willChangeValue(forKey: "isFinished")
        }
        didSet {
            didChangeValue(forKey: "isFinished")
        }
    }

    init(url: URL) {
        self.url = url
    }
    
    override func start() {
        let request = URLRequest(url: url)
        _isExecuting = true
        _isConcurrent = true
        _isFinished = false
        let queue = OperationQueue.main
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: queue)
        task = session.dataTask(with: request)
    }

    override func cancel() {
        super.cancel()
        task.cancel()
        _isFinished = true
        _isExecuting = false
    }
}

extension DownloadOperation: URLSessionDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
    }
}
