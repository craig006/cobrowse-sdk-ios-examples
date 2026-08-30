//
//  AppDelegate.swift
//  PBD
//
//  Created by Ste on 29/08/2026.
//

import UIKit
import CobrowseSDK

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    /// Held for the session's lifetime — `CobrowseIO` does not retain it.
    private let redactionDelegate = RedactByDefaultDelegate()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        HostingRootRedaction.install()

        let cobrowse = CobrowseIO.instance()
        cobrowse.license = "ste"
        cobrowse.delegate = redactionDelegate
        cobrowse.start()

        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}
