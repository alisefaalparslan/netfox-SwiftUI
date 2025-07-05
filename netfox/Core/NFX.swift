//
//  NFX.swift
//  netfox
//
//  Copyright © 2016 netfox. All rights reserved.
//

import Foundation
import UIKit

@objc
open class NFX: NSObject {
    
    // MARK: - Properties

    fileprivate var navigationViewController: UIViewController?

    fileprivate enum Constants: String {
        case alreadyStartedMessage = "Already started!"
        case alreadyStoppedMessage = "Already stopped!"
        case startedMessage = "Started!"
        case stoppedMessage = "Stopped!"
        case nibName = "NetfoxWindow"
    }
    
    fileprivate var started: Bool = false
    fileprivate var presented: Bool = false
    fileprivate var enabled: Bool = false
    fileprivate var selectedGesture: ENFXGesture = .shake
    fileprivate var ignoredURLs = [String]()
    fileprivate var ignoredURLsRegex = [NSRegularExpression]()
    fileprivate var lastVisitDate: Date = Date()
    
    internal var cacheStoragePolicy = URLCache.StoragePolicy.notAllowed
    
    // swiftSharedInstance is not accessible from ObjC
    class var swiftSharedInstance: NFX {
        struct Singleton {
            static let instance = NFX()
        }
        return Singleton.instance
    }
    
    // the sharedInstance class method can be reached from ObjC
    @objc open class func sharedInstance() -> NFX {
        return NFX.swiftSharedInstance
    }
    
    @objc public enum ENFXGesture: Int {
        case shake
        case custom
    }

    @objc open func start() {
        guard !started else {
            showMessage(Constants.alreadyStartedMessage.rawValue)
            return
        }

        started = true
        URLSessionConfiguration.implementNetfox()
        register()
        enable()
        fileStorageInit()
        showMessage(Constants.startedMessage.rawValue)
    }
    
    @objc open func stop() {
        guard started else {
            showMessage(Constants.alreadyStoppedMessage.rawValue)
            return
        }
        
        unregister()
        disable()
        clearOldData()
        started = false
        showMessage(Constants.stoppedMessage.rawValue)
    }
    
    fileprivate func showMessage(_ msg: String) {
        print("netfox: \(msg)")
    }
    
    internal func isEnabled() -> Bool {
        return enabled
    }
    
    internal func enable() {
        enabled = true
    }
    
    internal func disable() {
        enabled = false
    }
    
    fileprivate func register() {
        URLProtocol.registerClass(NFXProtocol.self)
    }
    
    fileprivate func unregister() {
        URLProtocol.unregisterClass(NFXProtocol.self)
    }
    
    @objc func motionDetected() {
        guard started else { return }
        toggleNFX()
    }
    
    @objc open func isStarted() -> Bool {
        return started
    }
    
    @objc open func setCachePolicy(_ policy: URLCache.StoragePolicy) {
        cacheStoragePolicy = policy
    }
    
    @objc open func setGesture(_ gesture: ENFXGesture) {
        selectedGesture = gesture
    }
    
    @objc open func show() {
        guard started else { return }
        showNFX()
    }
    
    @objc open func show(on rootViewController: UIViewController) {
        guard started, presented == false else { return }

        showNFX(on: rootViewController)
        presented = true
    }

    @objc open func hide() {
        guard started else { return }
        hideNFX()
    }

    @objc open func toggle()
    {
        guard self.started else { return }
        toggleNFX()
    }
    
    @objc open func ignoreURL(_ url: String) {
        ignoredURLs.append(url)
    }
    
    @objc open func getSessionLog() -> Data? {
        return try? Data(contentsOf: NFXPath.sessionLogURL)
    }
    
    @objc open func ignoreURLs(_ urls: [String]) {
        ignoredURLs.append(contentsOf: urls)
    }
    
    @objc open func ignoreURLsWithRegex(_ regex: String) {
        ignoredURLsRegex.append(NSRegularExpression(regex))
    }
    
    @objc open func ignoreURLsWithRegexes(_ regexes: [String]) {
        ignoredURLsRegex.append(contentsOf: regexes.map { NSRegularExpression($0) })
    }
    
    internal func getLastVisitDate() -> Date {
        return lastVisitDate
    }
    
    fileprivate func showNFX() {
        if presented {
            return
        }
        
        showNFXFollowingPlatform()
        presented = true
    }
    
    fileprivate func hideNFX() {
        if !presented {
            return
        }
        
        hideNFXFollowingPlatform { () -> Void in
            self.presented = false
            self.lastVisitDate = Date()
        }
    }

    fileprivate func toggleNFX() {
        presented ? hideNFX() : showNFX()
    }
    
    private func fileStorageInit() {
        clearOldData()
        NFXPath.deleteOldNFXLogs()
        NFXPath.createNFXDirIfNotExist()
    }
    
    internal func clearOldData() {
        NFXHTTPModelManager.shared.clear()
        
        NFXPath.deleteNFXDir()
        NFXPath.createNFXDirIfNotExist()
    }
    
    func getIgnoredURLs() -> [String] {
        return ignoredURLs
    }
    
    func getIgnoredURLsRegexes() -> [NSRegularExpression] {
        return ignoredURLsRegex
    }
    
    func getSelectedGesture() -> ENFXGesture {
        return selectedGesture
    }
    
}

extension NFX {
    fileprivate var presentingViewController: UIViewController? {
        var rootViewController = UIWindow.keyWindow?.rootViewController
		while let controller = rootViewController?.presentedViewController {
			rootViewController = controller
		}
        return rootViewController
    }

    fileprivate func showNFXFollowingPlatform() {
        showNFX(on: presentingViewController)
    }
    
    fileprivate func showNFX(on rootViewController: UIViewController?) {
        let vc = NFXListController_SwiftUI()
        vc.presentationController?.delegate = self
        rootViewController?.present(vc, animated: true, completion: nil)
        navigationViewController = vc
    }
    
    fileprivate func hideNFXFollowingPlatform(_ completion: (() -> Void)?) {
        navigationViewController?.presentingViewController?.dismiss(animated: true, completion: completion)
        navigationViewController = nil
    }
}

extension NFX: UIAdaptivePresentationControllerDelegate {

    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController)
    {
        guard self.started else { return }
        self.presented = false
    }
}
