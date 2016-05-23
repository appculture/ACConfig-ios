//
//  LaunchBrain.swift
//  MissionControlDemo
//
//  Created by Marko Tadic on 5/20/16.
//  Copyright © 2016 appculture. All rights reserved.
//

import UIKit
import MissionControl

protocol LaunchDelegate: class {
    
}

enum LaunchState: String {
    case Offline
    case Ready
    case Countdown
    case Launched
    case Failed
    case Aborted
}

class LaunchBrain {
    
    // MARK: - Properties
    
    var view: LaunchView!
    weak var delegate: LaunchDelegate?
    
    var state: LaunchState = .Offline {
        didSet {
            updateUIForState(state)
        }
    }
    
    var seconds: Int = 0 {
        didSet {
            view.countdown.text = String(format: "%02d", seconds)
        }
    }
    
    var timer: NSTimer?
    
    // MARK: - Init
    
    init(view: LaunchView, delegate: LaunchDelegate) {
        self.view = view
        self.delegate = delegate
        
        self.view.didTapButtonAction = { sender in
            self.didTapButton(sender)
        }
        
        updateUI()
        
        /// - TODO: implement delegate callbacks
        let center = NSNotificationCenter.defaultCenter()
        let notification = MissionControl.Notification.ConfigRefreshed
        center.addObserver(self, selector: #selector(updateUI), name: notification, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: - Actions
    
    func didTapButton(sender: AnyObject) {
        switch state {
        case .Offline:
            /// - TODO: implement force sync parameter
            if ConfigBool("Ready") {
                state = .Ready
            } else {
                state = .Failed
            }
        case .Ready:
            state = .Countdown
        case .Countdown:
            state = .Aborted
        case .Failed, .Aborted, .Launched:
            state = .Offline
        }
    }
    
    // MARK: - UI
    
    @objc func updateUI() {
        dispatch_async(dispatch_get_main_queue()) { 
            self.updateUIForState(self.state)
        }
    }
    
    private func updateUIForState(state: LaunchState) {
        updateUIForAnyState(state)
        
        switch state {
        case .Offline:
            updateUIForOfflineState()
        case .Ready:
            updateUIForReadyState()
        case .Countdown:
            updateUIForCountdownState()
        case .Launched:
            updateUIForLaunchedState()
        case .Failed:
            updateUIForFailedState()
        case .Aborted:
            updateUIForAbortedState()
        }
    }
    
    private func updateUIForAnyState(state: LaunchState) {
        view.button.layer.borderColor = colorForState(state).CGColor
        view.buttonTitle.text = commandForState(state)
        
        view.stopBlinkingStatusLight()
        view.statusTitle.text = "STATUS: \(state.rawValue.capitalizedString)"
        view.statusLightOnColor = colorForState(state)
        view.statusLightOn = true
        
        view.countdown.alpha = 1.0
    }
    
    private func updateUIForOfflineState() {
        view.stopAnimatingGradient()
        view.stopRotatingButtonImage()
        
        view.button.layer.borderColor = view.statusLightOffColor.CGColor
        view.countdown.alpha = 0.1
        seconds = 0
        view.startBlinkingStatusLight(timeInterval: 0.5)
    }
    
    private func updateUIForReadyState() {
        seconds = ConfigInt("CountdownDuration", 10)
    }
    
    private func updateUIForCountdownState() {
        startCountdown()
        let duration = ConfigDouble("CountdownRotationDuration", 2.0)
        view.rotateButtonImageWithDuration(duration)
        view.startBlinkingStatusLight(timeInterval: 0.25)
    }
    
    private func updateUIForLaunchedState() {
        view.countdown.text = "OK"
        
        view.animateGradientWithDuration(4.0)
        
        view.stopRotatingButtonImage()
        let duration = ConfigDouble("LaunchedRotationDuration", 1.0)
        view.rotateButtonImageWithDuration(duration)
    }
    
    private func updateUIForFailedState() {
        stopCountdown()
        view.countdown.text = "F"
        view.startBlinkingStatusLight(timeInterval: 0.5)
    }
    
    private func updateUIForAbortedState() {
        stopCountdown()
        view.stopRotatingButtonImage()
        view.countdown.text = "A"
        view.startBlinkingStatusLight(timeInterval: 0.25)
    }
    
    private func commandForState(state: LaunchState) -> String {
        switch state {
        case .Offline:
            return "CONNECT"
        case .Ready:
            return "LAUNCH"
        case .Countdown:
            return "ABORT"
        case .Launched, .Failed, .Aborted:
            return "RETRY"
        }
    }
    
    private func colorForState(state: LaunchState) -> UIColor {
        /// - TODO: implement persistance of latest settings
        switch state {
        case .Offline:
            return UIColor(hex: ConfigString("OfflineColor", "#F8E71C"))
        case .Ready:
            return UIColor(hex: ConfigString("ReadyColor", "#7ED321"))
        case .Countdown:
            return UIColor(hex: ConfigString("CountdownColor", "#F5A623"))
        case .Launched:
            return UIColor(hex: ConfigString("LaunchedColor", "#BD10E0"))
        case .Failed:
            return UIColor(hex: ConfigString("FailedColor", "#D0021B"))
        case .Aborted:
            return UIColor(hex: ConfigString("AbortedColor", "#D0021B"))
        }
    }
    
    // MARK: - Countdown
    
    private func startCountdown() {
        timer = NSTimer.scheduledTimerWithTimeInterval(1.0,
                                                       target: self,
                                                       selector: #selector(timerTick(_:)),
                                                       userInfo: nil, repeats: true)
    }
    
    private func stopCountdown() {
        timer?.invalidate()
        timer = nil
    }
    
    @objc func timerTick(sender: NSTimer) {
        /// - TODO: implement force sync parameter
        if ConfigBool("Abort") {
            state = .Aborted
        } else {
            if seconds - 1 >= 0 {
                seconds -= 1
            } else {
                stopCountdown()
                state = .Launched
            }
        }
    }
    
}
