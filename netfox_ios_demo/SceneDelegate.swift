//
//  SceneDelegate.swift
//  BundleNews
//
//  Created by alisefa on 26.11.2025.
//

import UIKit
import SwiftUI
import netfox_ios

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let _ = (scene as? UIWindowScene) else { return }

        let rootView = BaseView()
            .ignoresSafeArea()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay {
                PerformanceMonitoringView()
            }

        let hostingController = UIHostingController(rootView: rootView)

        window?.rootViewController = hostingController

        window?.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        print("sceneDidDisconnect")
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
    }

    func sceneWillResignActive(_ scene: UIScene) {
        print("sceneDidDisconnect")
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        print("sceneDidDisconnect")
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        print("sceneDidDisconnect")
    }
}
