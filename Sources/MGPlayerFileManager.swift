//
//  WSPlayerFileManager.swift
//  WSPlayer
//
//  Created by Weiwenshe on 2018/2/21.
//  Copyright © 2018年 com.weiwenshe. All rights reserved.
//

import UIKit
import MobileCoreServices

struct WSPlayerFileManager {
    static let cacheFilePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
    static let tempFilePath = NSTemporaryDirectory()
    
    static func isFileExist(with url: URL, cached: Bool) -> Bool {
        let path = filePath(with: url, cached: cached)
        return FileManager.default.fileExists(atPath: path)
    }
    
    static func filePath(with url: URL, cached: Bool) -> String {
        let filename = url.absoluteString.replacingOccurrences(of: "/", with: "_")
        if cached {
            return cacheFilePath + "/" + filename
        } else {
            return tempFilePath + "/" + filename
        }
    }
    
    static func fileSize(with url: URL, cached: Bool) -> Int64 {
        if isFileExist(with: url, cached: cached) == false { return 0 }
        let path = filePath(with: url, cached: cached)
        let info = try? FileManager.default.attributesOfItem(atPath: path)
        return info?[FileAttributeKey.size] as? Int64 ?? 0
    }
    
    static func contentType(with url: URL) -> String? {
        let extention = url.pathExtension
        let CFType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, extention as CFString, nil)
        let type = CFType?.takeRetainedValue() as String?
//        swift 中系统的 CF API中的对象会自动 ARC, 第三方才需要自己 release
//        CFType?.release()
        return type
    }
    
    static func removeFile(with url: URL, cached: Bool) {
        guard isFileExist(with: url, cached: cached) else { return }
        try? FileManager.default.removeItem(atPath: filePath(with: url, cached: cached))
    }
    
    static func moveTempFileToCache(with url: URL) {
        guard isFileExist(with: url, cached: false) else { return }
        let temp = filePath(with: url, cached: false)
        let cache = filePath(with: url, cached: true)
        try? FileManager.default.moveItem(atPath: temp, toPath: cache)
    }
}
