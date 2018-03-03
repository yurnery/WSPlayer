//
//  WSPlayer.swift
//  WSPlayer
//
//  Created by Weiwenshe on 2018/2/6.
//  Copyright © 2018年 com.weiwenshe. All rights reserved.
//

import UIKit
import AVFoundation

public enum PlayState {
    case buffering, playing, stop, pause
}

public class WSPlayer: UIView {
    /// 播放状态
    public private(set) var state: PlayState = .stop {
        didSet{
            if oldValue != state {
                NotificationCenter.default.post(name: .playingStateChanged, object: state)
                bottomView.updatePlayButtonState(state)
            }
        }
    }
    /// 缓冲进度
    public private(set) var loadedProgress: Float = 0 {
        didSet{
            if oldValue != loadedProgress {
                NotificationCenter.default.post(name: .loadedProgressChanged, object: loadedProgress)
                bottomView.updateProgressView(loadedProgress)
            }
        }
    }
    /// 总时长
    public private(set) var duration: Float = 0 {
        didSet{
            bottomView.initialSlider(max: duration)
            bottomView.updateTotoalTime(duration)
        }
    }
    /// 当前播放时间
    public private(set) var current: Float = 0 {
        didSet{
            bottomView.updateSlider(current)
            bottomView.updateCurrentTime(current)
        }
    }
    /// 播放进度 %
    public var progress: Float {
        if duration == 0 { return 0 }
        return current / duration
    }
    
    public private(set) var isFullScrrrn = false {
        didSet{
            isEnterFullScreenClosure?(isFullScrrrn)
            bottomView.updateFullBtn(selected: isFullScrrrn)
        }
    }
    
    
    /// 进入全屏是退出全屏时会调用 block, 参数 true 表示进入全屏, 外界如果需要隐藏 Navbar 和 statusBar需要自己实现 Closure
    public var isEnterFullScreenClosure: ((Bool) -> Void)?
    public lazy var stopWhenAppDidEnterBackground = true
    
    private lazy var player = AVPlayer()
    private lazy var playerLayer = AVPlayerLayer()
    private lazy var bottomView = WSPlayerBottomView()
    
    private var playBackTimeObserver: Any?
    private var playerItem: AVPlayerItem?
    private var url: URL?
    
    private lazy var isPauseByUser = true
    private var isBuffering = false
    private var originFrame: CGRect = .zero
    private lazy var resourceLoader = WSResourceLoader()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.black
        bottomView = WSPlayerBottomView(frame: CGRect(x: 0, y: bounds.height - 44, width: bounds.width, height: 44))
        addSubview(bottomView)
        originFrame = frame
        bottomView.delegate = self
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit { releasePlayer() }
}

// MARK: - PlayControl
extension WSPlayer: WSPlayControlDelegate {
    public func play(_ url: URL, needCache: Bool = false) {
        self.url = url
        resetPlayState(in: .playing)
        if url.absoluteString.hasPrefix("http") == false { //非流媒体
            setupPlayer(with: url)
        } else { //流媒体
            if needCache {
                guard let customURL = url.customScheme() else { return }
                let asset = AVURLAsset(url: customURL)
                resourceLoader = WSResourceLoader()
                resourceLoader.delegate = self
                asset.resourceLoader.setDelegate(resourceLoader, queue: .main)
                setupPlayer(with: customURL, asset: asset)
            } else {
                setupPlayer(with: url)
            }
        }
        layer.addSublayer(playerLayer)
        bringSubview(toFront: bottomView)
        setPlayerItemKVO()
        addNotification()
    }
    
    public func stop() {
        resetPlayState(in: .stop)
        state = .stop
    }
    
    public func resumeOrPause() {
        switch state {
        case .playing: pause()
        case .pause: resume()
        case .stop:
            if let url = url { play(url) }
        default: break
        }
    }
    
    public func fullScreen() {
        isFullScrrrn = true
        playerLayer.transform = CATransform3DMakeRotation(.pi/2, 0, 0, 1)
        bottomView.transform = CGAffineTransform(rotationAngle: .pi/2)
        frame = UIScreen.main.bounds
        playerLayer.frame = bounds
        bottomView.frame = CGRect(x: 0, y: 0, width: 44, height: bounds.height)
        bringSubview(toFront: bottomView)
    }
    
    public func halfScreen() {
        isFullScrrrn = false
        playerLayer.transform = CATransform3DIdentity
        bottomView.transform = CGAffineTransform.identity
        frame = originFrame
        playerLayer.frame = bounds
        bottomView.frame = CGRect(x: 0, y: bounds.height - 44, width: bounds.width, height: 44)
        bringSubview(toFront: bottomView)
    }
    
    public func seekToTime(_ second: Float) {
        if state == .stop { return }
        var second = second
        second = max(0, second)
        second = min(second, duration)
        player.pause()
        
        let cmtime = CMTimeMakeWithSeconds((Float64(second)), Int32(NSEC_PER_SEC))
        player.seek(to: cmtime) { (result) in
            self.isPauseByUser = false
            self.play()
            if self.playerItem?.isPlaybackLikelyToKeepUp == false {
                self.state = .buffering
            }
        }
    }
    
    /*******管理播放以及播放状态********/
    private func play() {
        player.play()
        state = .playing
    }
    
    private func pause(byUser: Bool = true) {
        player.pause()
        state = .pause
        isPauseByUser = byUser
    }
    
    private func resume() {
        play()
        isPauseByUser = false
    }
    
    private func buffering() {
        pause(byUser: false)
        state = .buffering
    }
}

// MARK: - ObserverHandler
extension WSPlayer {
    @objc func appWillResignActive() {
        if stopWhenAppDidEnterBackground {
            pause()
            isPauseByUser = false
        }
    }
    
    @objc func appDidBecomeActive() {
    }
    
    @objc func playItemDidPlaytoEnd(_ notification: Notification) {
        stop()
    }
    
    @objc func playItemPlayBackStalled(_ notification: Notification) {
        // 在 KVO 中监听处理
        print(#function, "网络不好")
    }
}

// MARK: - KVO
extension WSPlayer {
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let playItem = object as? AVPlayerItem {
            if keyPath == AVPlayerItemKeyPath.status {
                playItem.status == .readyToPlay ? monitorPlayback(item: playItem) : stop()
            } else if keyPath == AVPlayerItemKeyPath.loadedTimeRanges { //监听下载进度
                self.calculateDownloadProgress(item: playItem)
            } else if keyPath == AVPlayerItemKeyPath.playbackBufferEmpty {  //正在缓存
                if playItem.isPlaybackBufferEmpty {
                    bufferingSomeSecond()
                }
            } else if keyPath == AVPlayerItemKeyPath.playbackLikelyToKeepUp {
                
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    private func monitorPlayback(item: AVPlayerItem) {
        let totalTime = Int(item.duration.value) / Int(item.duration.timescale)
        duration = Float(totalTime)
        play()
        playBackTimeObserver = player.addPeriodicTimeObserver(forInterval: CMTimeMake(1, 1), queue: nil, using: {[weak self] (time) in
            guard let sself = self else { return }
            let currentSecond = Float(item.currentTime().value) / Float(item.currentTime().timescale)
            if sself.isPauseByUser == false { sself.state = .playing }
            if sself.current != currentSecond {
                sself.current = currentSecond
                NotificationCenter.default.post(name: .progressChanged, object: nil)
            }
        })
    }
    
    private func calculateDownloadProgress(item: AVPlayerItem) {
        let loadedTimeRanges = item.loadedTimeRanges
        guard let timeRange = loadedTimeRanges.first?.timeRangeValue, playerItem != nil else { return } //第一个缓存区域
        let startSec = CMTimeGetSeconds(timeRange.start)
        let durationSec = CMTimeGetSeconds(timeRange.duration)
        let timeInterval = startSec + durationSec
        let duration = CMTimeGetSeconds((playerItem!.duration))
        loadedProgress = Float(timeInterval) / Float(duration)
    }
    
    private func bufferingSomeSecond() {
        if isBuffering { return }
        isBuffering = true
        buffering()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {[ weak self] in
            guard let sself = self else { return }
            sself.isBuffering = false
            if sself.isPauseByUser { return }
            if sself.playerItem?.isPlaybackLikelyToKeepUp == false {
                sself.bufferingSomeSecond()
            }
            sself.play()
        }
    }
}

// MARK: - WSResourceLoaderDelegate
extension WSPlayer: WSResourceLoaderDelegate {
    func resourceLoader(_: WSResourceLoader, startLoading task: URL) {
        
    }
    func resourceLoader(_: WSResourceLoader, didFinishLoading task: URL) {
        
    }
    func resourceLoader(_: WSResourceLoader, didFailLoading task: URL, error: Error) {
        
    }
}

// MARK: - Help Method
private extension WSPlayer {
    func releasePlayer() {
        if playerItem == nil { return }
        NotificationCenter.default.removeObserver(self)
        playerItem?.removeObserver(self, forKeyPath: AVPlayerItemKeyPath.status)
        playerItem?.removeObserver(self, forKeyPath: AVPlayerItemKeyPath.loadedTimeRanges)
        playerItem?.removeObserver(self, forKeyPath: AVPlayerItemKeyPath.playbackBufferEmpty)
        playerItem?.removeObserver(self, forKeyPath: AVPlayerItemKeyPath.playbackLikelyToKeepUp)
        if let ob = playBackTimeObserver {
            player.removeTimeObserver(ob)
            playBackTimeObserver = nil
        }
        playerItem = nil
    }
    
    func resetPlayState(in state: PlayState) {
        player.pause()
        self.state = .stop
        releasePlayer()
        isPauseByUser = state == .stop
        loadedProgress = 0
        duration = 0
        current = 0
    }
    
    func setupPlayer(with url: URL, asset: AVAsset? = nil) {
        if let asset = asset {
            playerItem = AVPlayerItem(asset: asset)
        } else {
            playerItem = AVPlayerItem(url: url)
        }
        player = AVPlayer(playerItem: playerItem)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspect
        playerLayer.frame = bounds
    }
    
    func setPlayerItemKVO() {
        playerItem?.addObserver(self, forKeyPath: AVPlayerItemKeyPath.status, options: .new, context: nil)
        playerItem?.addObserver(self, forKeyPath: AVPlayerItemKeyPath.loadedTimeRanges, options: .new, context: nil)
        playerItem?.addObserver(self, forKeyPath: AVPlayerItemKeyPath.playbackBufferEmpty, options: .new, context: nil)
        playerItem?.addObserver(self, forKeyPath: AVPlayerItemKeyPath.playbackLikelyToKeepUp, options: .new, context: nil)
    }
    
    func addNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(appWillResignActive), name: .UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: .UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(playItemDidPlaytoEnd(_:)), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        NotificationCenter.default.addObserver(self, selector: #selector(playItemPlayBackStalled(_:)), name: .AVPlayerItemPlaybackStalled, object: playerItem)
    }
}


