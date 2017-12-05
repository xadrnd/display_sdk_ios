//
//  XADUtils.swift
//  XADDisplaySdk
//
//  Created by Stephen Anderson on 4/7/17.
//  Copyright © 2017 Xad. All rights reserved.
//

import Foundation
import CoreLocation
import CoreTelephony
import AdSupport

open class XADUtils : NSObject {

    
    class func doNotTrack() -> Bool {
        return !ASIdentifierManager.shared().isAdvertisingTrackingEnabled
    }
    
    
    class func isSimulator() -> Bool {
        #if arch(i386) || arch(x86_64)
            return true
        #else
            return false
        #endif
    }
    
    
    class func appname() -> String? {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
    }
    
    
    class func appver() -> String? {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }
    
    
    class func bundleName() -> String? {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleIdentifier") as? String
    }
    
    
    class func carrierName() -> String? {
        let netInfo = CTTelephonyNetworkInfo()
        if let carrier = netInfo.subscriberCellularProvider {
            return carrier.carrierName
        }
        return nil
    }
    
    class func sdkVersion() -> String? {
        if let bundle = Bundle(identifier: "com.xad.XADDisplaySdk") {
            return bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        }
        
        return nil
    }
    
    class func deviceType() -> String? {
        let uiIdiom = UIDevice.current.userInterfaceIdiom
        switch uiIdiom {
        case .phone:
            return "phone"
        case .pad:
            return "tablet"
        case .carPlay:
            return "car"
        case .tv:
            return "television"
        default:
            return nil
        }
    }
    
    class func userAgent() {
        DispatchQueue.main.async {
            guard kUserAgent.isEmpty else {
                return
            }
            
            let webView: UIWebView = UIWebView()
            webView.loadHTMLString("<html></html>", baseURL: nil)
            if let userAgent = webView.stringByEvaluatingJavaScript(from: "navigator.userAgent") {
                kUserAgent = userAgent
            } else {
                kUserAgent = "Unknown"
            }
        }
    }
    
    static var kUserAgent: String = ""
}

