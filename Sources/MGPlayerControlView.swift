//
//  WSPlayerControlView.swift
//  WSPlayer
//
//  Created by Weiwenshe on 2018/2/7.
//  Copyright © 2018年 com.weiwenshe. All rights reserved.
//

import UIKit
import SnapKit

// MARK: - 底部控制条
class WSPlayerBottomView: UIView {
    let margin: CGFloat = 5
    private lazy var playButton: UIButton = {
       let btn = UIButton()
        btn.setTitle("Play", for: .normal)
        btn.setTitle("Pause", for: .selected)
        btn.setTitleColor(.red, for: .normal)
        btn.addTarget(self, action: #selector(playBtnClick(btn:)), for: .touchUpInside)
        return btn
    }()
    
    private lazy var currentTimeLabel: UILabel = {
        let label = UILabel()
        label.text = "00:00"
        label.textColor = UIColor(hex: 0xffffff)
        label.font = UIFont.systemFont(ofSize: 10)
        label.textAlignment = .center
        return label
    }()
    
    //播放进度条
    private lazy var playSlider: UISlider = {
        let slider = UISlider()
        slider.minimumTrackTintColor = .clear
        slider.maximumTrackTintColor = .clear
        slider.setThumbImage(nil, for: .normal)
        slider.addTarget(self, action: #selector(playSliderChange(_:)), for: .valueChanged)
        slider.addTarget(self, action: #selector(playSliderChangeEnd(_:)), for: .touchUpInside)
        slider.addTarget(self, action: #selector(playSliderChangeEnd(_:)), for: .touchUpOutside)
        slider.addTarget(self, action: #selector(playSliderChangeEnd(_:)), for: .touchCancel)
        return slider
    }()
    
    //缓存进度条
    private lazy var progressView: UIProgressView = {
        let view = UIProgressView()
        view.progressTintColor = UIColor(hex: 0xffffff)
        view.trackTintColor = UIColor(hex: 0xffffff, alpha: 0.18)
        view.layer.cornerRadius = 1.5
        view.layer.masksToBounds = true
        view.transform = CGAffineTransform(scaleX: 1, y: 1.5)
        return view
    }()
    
    private lazy var totalTimeLabel: UILabel = {
        let label = UILabel()
        label.text = "00:00"
        label.textColor = UIColor(hex: 0xffffff)
        label.font = UIFont.systemFont(ofSize: 10)
        label.textAlignment = .center
        return label
    }()
    
    private lazy var fullScreenBtn: UIButton = {
       let btn = UIButton()
        btn.setTitle("Full", for: .normal)
        btn.setTitle("Half", for: .selected)
        btn.setTitleColor(.red, for: .normal)
        btn.addTarget(self, action: #selector(fullScreenBtnClick(btn:)), for: .touchUpInside)
        return btn
    }()
    
    private lazy var stopButton: UIButton = {
       let btn = UIButton()
        btn.setImage(nil, for: .normal)
        btn.addTarget(self, action: #selector(stopBtnClick(btn:)), for: .touchUpInside)
        return btn
    }()

    weak var delegate: WSPlayControlDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        [playButton, currentTimeLabel, totalTimeLabel, progressView, playSlider, fullScreenBtn].forEach {
            addSubview($0)
        }
        setConstraint()
    }
    
    private func setConstraint() {
        playButton.snp.makeConstraints { (make) in
            make.left.top.bottom.equalToSuperview()
            make.width.equalTo(44)
        }
        
        currentTimeLabel.snp.makeConstraints { (make) in
            make.left.equalTo(playButton.snp.right).offset(margin)
            make.width.equalTo(52)
            make.top.bottom.equalToSuperview()
        }
        
        fullScreenBtn.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-margin)
            make.width.equalTo(44)
            make.top.bottom.equalToSuperview()
        }
        
        totalTimeLabel.snp.makeConstraints { (make) in
            make.right.equalTo(fullScreenBtn.snp.left).offset(-margin)
            make.top.bottom.equalToSuperview()
            make.width.equalTo(52)
        }
        
        progressView.snp.makeConstraints { (make) in
            make.left.equalTo(currentTimeLabel.snp.right).offset(margin)
            make.right.equalTo(totalTimeLabel.snp.left).offset(-margin)
            make.height.equalTo(2)
            make.top.equalToSuperview().offset(21)
        }
        
        playSlider.snp.makeConstraints { (make) in
            make.left.equalTo(progressView.snp.left)
            make.right.equalTo(progressView.snp.right)
            make.height.equalTo(20)
            make.top.equalToSuperview().offset(12)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - ControlViewEvent
private extension WSPlayerBottomView {
    @objc func playBtnClick(btn: UIButton) {
        delegate?.resumeOrPause()
    }
    
    @objc func fullScreenBtnClick(btn: UIButton) {
        btn.isSelected ? delegate?.halfScreen() : delegate?.fullScreen()
    }
    
    @objc func stopBtnClick(btn: UIButton) {
        delegate?.stop()
    }
    
    @objc func playSliderChange(_ slider: UISlider) {
        updateCurrentTime(slider.value)
    }
    
    @objc func playSliderChangeEnd(_ slider: UISlider) {
        delegate?.seekToTime(slider.value)
        updateCurrentTime(slider.value)
    }
    
}

// MARK: - 更新UI 
extension WSPlayerBottomView {
    func updateCurrentTime(_ time: Float) {
        let str = time.convertToTimeFormate()
        currentTimeLabel.text = str
    }
    
    func updateTotoalTime(_ time: Float) {
        let str = time.convertToTimeFormate()
        totalTimeLabel.text = str
    }
    
    func updateProgressView(_ progress: Float) {
        progressView.progress = progress
    }
    
    func initialSlider(min: Float = 0, max: Float) {
        playSlider.minimumValue = min
        playSlider.maximumValue = max
    }
    
    func updateSlider(_ value: Float) {
        guard value <= playSlider.maximumValue && value >= 0 else { return }
        playSlider.setValue(value, animated: true)
    }
    
    func updatePlayButtonState(_ state: PlayState) {
        playButton.isSelected = state == .playing
    }
    
    func updateFullBtn(selected: Bool) {
        fullScreenBtn.isSelected = selected
    }
}

