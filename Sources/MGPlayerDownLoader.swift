//
//  WSPlayerDownLoader.swift
//  WSPlayer
//
//  Created by Weiwenshe on 2018/2/21.
//  Copyright © 2018年 com.weiwenshe. All rights reserved.
//

import UIKit

protocol DownLoaderDelegate : class {
    func downLoader(_: WSPlayerDownLoader, downLoadingData url: URL)
    func downLoader(_: WSPlayerDownLoader, didDownLoadedData url: URL, error: Error?)
    func downLoader(_: WSPlayerDownLoader, beginDownLoadData url: URL)
}

final class WSPlayerDownLoader: NSObject {
    var downloadSize: Int64 = 0
    var totalSize: Int64 = 0
    var offset: Int64 = 0
    var contentType: String?
    weak var delegate: DownLoaderDelegate?
    
    private var url: URL?
    private var session: URLSession?
    private var outputStram: OutputStream?
}

extension WSPlayerDownLoader {
    func downLoad(with url: URL, offset: Int64) {
        self.url = url
        self.offset = offset
        cancel()
        var request = URLRequest(url: url)
        request.setValue("bytes=\(offset)-", forHTTPHeaderField: "Range")
        session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
        let task = session?.dataTask(with: request)
        task?.resume()
    }
    
    private func cancel() {
        session?.invalidateAndCancel()
        session = nil
        outputStram?.close()
        outputStram = nil

        WSPlayerFileManager.removeFile(with: url!, cached: false)
        downloadSize = 0
        totalSize = 0
        contentType = nil
    }
}

// MARK: - URLSessionDataDelegate
extension WSPlayerDownLoader: URLSessionDataDelegate {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        let response = response as? HTTPURLResponse
        if let str = response?.allHeaderFields["Content-Range"] as? String,
            let total = str.components(separatedBy: "/").last,
            let lenght = Int64(total) {
            totalSize = lenght
        }
        contentType = response?.mimeType
        outputStram = OutputStream(toFileAtPath: WSPlayerFileManager.filePath(with: (response?.url)!, cached: false), append: true)
        outputStram?.open()
        completionHandler(.allow)
        delegate?.downLoader(self, beginDownLoadData: url!)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        data.withUnsafeBytes { (point) -> Void in
            self.outputStram?.write(point, maxLength: data.count)
        }
        downloadSize = downloadSize + Int64(data.count)
        delegate?.downLoader(self, downLoadingData: url!)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if error == nil && WSPlayerFileManager.fileSize(with: url!, cached: false) == totalSize {
            WSPlayerFileManager.moveTempFileToCache(with: url!)
        }
        delegate?.downLoader(self, didDownLoadedData: url!, error: error)
        outputStram?.close()
    }
}

