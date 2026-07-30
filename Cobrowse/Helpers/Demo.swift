//
//  Demo.swift
//

import Foundation

import SwiftUI
import CobrowseSDK

enum Demo {
    @AppStorage("demo_id")
    static var id = ""

    @AppStorage("license")
    static var license = "trial"

    @AppStorage("api")
    static var api = "https://cobrowse.io"

    @AppStorage("device_name")
    static var deviceName = "Trial iOS Device"

    @AppStorage("device_email")
    static var deviceEmail = "ios@example.com"

    @AppStorage("isAppetize")
    static var isAppetize = false
    
    @discardableResult
    static func setup() -> Bool {
        
        #if APPCLIP
        let isDemo = true
        #else
        let isDemo = Demo.isAppetize
        #endif
        
        if isDemo {
            #if APPCLIP
            let license = "rE6HC6EDX6g2_w"
            let deviceID = Int.random(in: 1000..<9999).description
            let deviceName = "AppClip iOS Device (\(deviceID))"
            let userEmail = "appclip-\(deviceID)@example.com"
            #else
            let license = Demo.license
            let deviceName = Demo.deviceName
            let userEmail = Demo.deviceEmail
            #endif
            
            let cobrowse = CobrowseIO.instance()
            
            cobrowse.license = license
            cobrowse.api = Demo.api
            cobrowse.capabilities = ["arrows", "disappearing_ink", "drawing", "keypress", "laser", "pointer", "rectangles"]
            cobrowse.customData = [
                "demo_id": Demo.id,
                CBIODeviceNameKey: deviceName,
                CBIOUserEmailKey: userEmail
            ]
            
            account.isSignedIn = true
        }
        
        return isDemo
    }
}
