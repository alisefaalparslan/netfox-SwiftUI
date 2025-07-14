//
//  monitorFPS.swift
//  netfox
//
//  Created by alisefa on 14.07.2025.
//  Copyright © 2025 kasketis. All rights reserved.
//

import Foundation
import Combine
import QuartzCore

class FPSMonitor: ObservableObject {
    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0
    private var frameCount: Int = 0
    private var interval: TimeInterval = 0.5

    var fpsUpdateHandler: ((Double) -> Void)?

    func start(with interval: TimeInterval = 0.5) {
        stop() // in case already running
        
        lastTimestamp = 0
        frameCount = 0
        self.interval = interval

        displayLink = CADisplayLink(target: self, selector: #selector(tick))
        displayLink?.add(to: .main, forMode: .common)
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func tick(link: CADisplayLink) {
        if lastTimestamp == 0 {
            lastTimestamp = link.timestamp
            return
        }

        frameCount += 1
        let delta = link.timestamp - lastTimestamp

        if delta >= self.interval {
            let fps = Double(frameCount) / delta
            fpsUpdateHandler?(fps)
            frameCount = 0
            lastTimestamp = link.timestamp
        }
    }
}
