//
//  WSResourceLoader.swift
//  WSPlayer
//
//  Created by Weiwenshe on 2018/2/20.
//  Copyright © 2018年 com.weiwenshe. All rights reserved.
//

import UIKit
import AVKit

protocol WSResourceLoaderDelegate: class {
    func resourceLoader(_: WSResourceLoader, startLoading task: URL)
    func resourceLoader(_: WSResourceLoader, didFinishLoading task: URL)
    func resourceLoader(_: WSResourceLoader, didFailLoading task: URL, error: Error)
}

// MARK: - DownLoaderDelegate
extension WSResourceLoader: DownLoaderDelegate {
    func downLoader(_: WSPlayerDownLoader, downLoadingData url: URL) {
        handleAllLoadingRequest()
    }
    
    func downLoader(_: WSPlayerDownLoader, didDownLoadedData url: URL, error: Error?) {
        if error != nil {
            delegate?.resourceLoader(self, didFailLoading: url, error: error!)
        } else {
            delegate?.resourceLoader(self, didFinishLoading: url)
        }
    }
    
    func downLoader(_: WSPlayerDownLoader, beginDownLoadData url: URL) {
        delegate?.resourceLoader(self, startLoading: url)
    }
}

final class WSResourceLoader: NSObject {
    weak var delegate: WSResourceLoaderDelegate?
    private var loadingRequests: [AVAssetResourceLoadingRequest] = []
    private lazy var downLoader: WSPlayerDownLoader = {
        let downLoader = WSPlayerDownLoader()
        downLoader.delegate = self
        return downLoader
    }()
}

// MARK: - AVAssetResourceLoaderDelegate
extension WSResourceLoader: AVAssetResourceLoaderDelegate {
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        
        guard let url = loadingRequest.request.url?.originScheme() else { return true }
        loadingRequests.append(loadingRequest)
        guard let loadingRequest = loadingRequests.first else { return true }
        let currentOffset = loadingRequest.dataRequest?.currentOffset ?? 0
        if WSPlayerFileManager.isFileExist(with: url, cached: true) {
            //本地文件存在
            handleCacheData(with: loadingRequest, url: url)
        } else if downLoader.downloadSize == 0 {
            // 从没下载过, 从零开始下载
            downLoader.downLoad(with: url, offset: currentOffset)
        } else { //已经下载过的
            if currentOffset < downLoader.offset || currentOffset > (downLoader.offset + downLoader.downloadSize + 300 * 1024) {
                //有下载过, 拼接不上, 重新下载
                //1. 现在请求的offset > 下载的offset + buffer + 下载的大小
                //2. 现在请求的offset < 下载的 offset
                print("//有下载过, 拼接不上, 重新下载")
                downLoader.downLoad(with: url, offset: currentOffset)
            } else {
                handleAllLoadingRequest()
            }
        }
        return true
    }
    
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
        loadingRequests.remove(loadingRequest)
    }
    
}

// MARK: - 响应请求, 返回数据
private extension WSResourceLoader {
    private func handleCacheData(with loadingRequest: AVAssetResourceLoadingRequest, url: URL) {
        //1. 填充信息头
        loadingRequest.contentInformationRequest?.contentLength = WSPlayerFileManager.fileSize(with: url, cached: true)
        loadingRequest.contentInformationRequest?.contentType = WSPlayerFileManager.contentType(with: url)
        loadingRequest.contentInformationRequest?.isByteRangeAccessSupported = true
        
        //2. 填充数据
        let fileURL = URL(fileURLWithPath: WSPlayerFileManager.filePath(with: url, cached: true))
        do {
            let data = try Data(contentsOf: fileURL, options: .mappedIfSafe)
            //32位机型 Int->Int64 有可能溢出
            let requestOffset = Int(loadingRequest.dataRequest?.currentOffset ?? 0)
            let requestLength = loadingRequest.dataRequest?.requestedLength ?? 0
            let subData = data.subdata(in: requestOffset ..< (requestOffset + requestLength))
            loadingRequest.dataRequest?.respond(with: subData)
            //3. 完成请求
            loadingRequests.remove(loadingRequest, onlyFirst: true)
            loadingRequest.finishLoading()
        } catch  {
            print(error)
        }
    }
    
    private func handleAllLoadingRequest() {
        var completeRequests: [AVAssetResourceLoadingRequest] = []
        
//        for loadingRequest in loadingRequests {
            guard let loadingRequest = loadingRequests.first, let url = loadingRequest.request.url?.originScheme() else { return }
            //1. 响应信息头
            loadingRequest.contentInformationRequest?.contentLength = downLoader.totalSize
            loadingRequest.contentInformationRequest?.contentType = downLoader.contentType
            loadingRequest.contentInformationRequest?.isByteRangeAccessSupported = true
            
            //2. 填充数据
            let currentOffset = Int64(loadingRequest.dataRequest?.currentOffset ?? 0)
            let requestLength = Int64(loadingRequest.dataRequest?.requestedLength ?? 0)
    
            let responseOffset = currentOffset - downLoader.offset //请求的起点相对于本地文件起点的 offset,
            if responseOffset > downLoader.downloadSize  { return } //因为可以300kb的缓冲区, 所以offset 可能比已经下载的还多
            let responseLength = min(downLoader.downloadSize + downLoader.offset - currentOffset, requestLength)
            let intResOffset = Int(responseOffset)
            let intResLength = Int(responseLength)
            
            var fileURL = URL(fileURLWithPath: WSPlayerFileManager.filePath(with: url, cached: false))
            var data = try? Data(contentsOf: fileURL, options: .mappedIfSafe)
            if data == nil { //可能已经下载完了, 从 tmp -> cache
                fileURL = URL(fileURLWithPath: WSPlayerFileManager.filePath(with: url, cached: true))
                data = try? Data(contentsOf: fileURL, options: .mappedIfSafe)
            }
            if intResOffset + intResLength > data?.count ?? 0 { return } //文件写入比回调慢, 读取到已下载长度, 但是还没写入完成
        
            if let subData = data?.subdata(in: intResOffset ..< (intResOffset + intResLength)) {
                loadingRequest.dataRequest?.respond(with: subData)
            }
            
            //3. 完成请求
            if downLoader.downloadSize + downLoader.offset >= requestLength + currentOffset {
                completeRequests.append(loadingRequest)
                loadingRequest.finishLoading()
                loadingRequests.remove(loadingRequest)
            }
//        }
//        loadingRequests.remove(objects: completeRequests)
    }
}

