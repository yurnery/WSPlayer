//
//  WSPlayerCommon.swift
//  WSPlayer
//
//  Created by Weiwenshe on 2018/2/6.
//  Copyright © 2018年 com.weiwenshe. All rights reserved.
//

import UIKit

struct AVPlayerItemKeyPath {
    static let status = "status"
    static let loadedTimeRanges = "loadedTimeRanges"
    static let playbackBufferEmpty = "playbackBufferEmpty"
    static let playbackLikelyToKeepUp = "playbackLikelyToKeepUp"
}

struct MagicNumber {
    static let mainW = UIScreen.main.bounds.width
    static let mainH = UIScreen.main.bounds.height
}

extension Array where Element : Equatable {
    mutating func remove(_ object: Element, onlyFirst: Bool = true) {
        if onlyFirst == false {
            self = filter { $0 != object }
        } else {
            var index: Int?
            for (i ,item) in enumerated() {
                if item == object {
                    index = i
                    break
                }
            }
            if let i = index { remove(at: i) }
        }
    }
    
    mutating func remove(objects subArray: [Element]) {
        for item in subArray {
            remove(item, onlyFirst: false)
        }
    }
}

extension URL {
    private var saltStr: String { return "custom" }
    func customScheme() -> URL? {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: true)
        components?.scheme?.append(saltStr)
        return components?.url
    }
    
    func originScheme() -> URL? {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: true)
        let origin = components?.scheme?.replacingOccurrences(of: saltStr, with: "")
        components?.scheme = origin
        return components?.url
    }
    
    func isCustomScheme() -> Bool {
        return scheme?.contains(saltStr) ?? false
    }
}

public extension NSNotification.Name {
    static var playingStateChanged: NSNotification.Name {
        return self.init("WSPlyaerPlayingStateChange")
    }
    
    static var progressChanged: NSNotification.Name {
        return self.init("WSPlyaerProgressChanged")
    }
    
    static var loadedProgressChanged: NSNotification.Name {
        return self.init("WSPlyaerLoadedProgressChanged")
    }
}

extension UIColor {
    convenience init(hex: Int, alpha: CGFloat = 1) {
        let red = CGFloat((hex >> 16) & 0xff)
        let green = CGFloat((hex >> 8) & 0xff)
        let blue = CGFloat(hex & 0xff)
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        self.init(red: red / 255, green: green / 255, blue: blue / 255, alpha: alpha)
    }
}

extension Float {
    func convertToTimeFormate() -> String {
        let value = Int(ceil(self))
        var str: String = ""
        if value < 3600 {
            let minStr = String(format: "%02d", value / 60)
            let secStr = String(format: "%02d", value % 60)
            str = "\(minStr):\(secStr)"
        } else {
            let h = value / 3600
            let m = (value % 3600) / 60
            let s = value - h * 3600 - m * 60
            let hourStr = String(format: "%02d", h)
            let minStr = String(format: "%02d", m)
            let secStr = String(format: "%02d", s)
            str = "\(hourStr):\(minStr):\(secStr)"
        }
        return str
    }
}
