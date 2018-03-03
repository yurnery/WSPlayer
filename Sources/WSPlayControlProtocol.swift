//
//  WSPlayControlProtocol.swift
//  WSPlayer
//
//  Created by Weiwenshe on 2018/2/6.
//  Copyright © 2018年 com.weiwenshe. All rights reserved.
//

import UIKit

protocol WSPlayControlDelegate: class {
    func resumeOrPause()
    func stop()
    func fullScreen()
    func halfScreen()
    func seekToTime(_ second: Float)
}
