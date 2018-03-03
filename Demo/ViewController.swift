//
//  ViewController.swift
//  Demo
//
//  Created by Weiwenshe on 2018/3/3.
//  Copyright © 2018年 com.weiwenshe. All rights reserved.
//

import UIKit
import WSPlayer

class ViewController: UIViewController {
    var statusBarHidden = false
    let playerView = WSPlayer(frame: CGRect(x: 0, y: 100, width: UIScreen.main.bounds.width, height: 400))
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(playerView)
        playerView.isEnterFullScreenClosure = { (isFull) in
            self.navigationController?.navigationBar.isHidden = isFull
            self.statusBarHidden = isFull
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let str = "http://video-cdn.luoo.net/20171012.mov-720x480-8d61d0d6.mp4"
        let url = URL(string: str)!
        playerView.play(url, needCache: true)
        playerView.fullScreen()
    }
    

}

