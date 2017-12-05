//
//  XADMRAIDServiceProvider.swift
//  XADDisplaySdk
//
//  Created by Ray Wu on 9/6/16.
//  Copyright © 2016 Xad. All rights reserved.
//

import UIKit
import EventKit
import AVKit
import AVFoundation
import SafariServices

class XADMRAIDServiceProvider{
    
    enum XADMRAIDServiceProviderError: Error {
        case featureNotSupported
        case malformedUrl
    }
    
    class func playVideoWithUrlString(_ urlString: String?, presentViewController: UIViewController?) {
        if let urlString = urlString,
            let videoURL = URL(string: urlString){
            let player = AVPlayer(url: videoURL)
            let playerViewController = AVPlayerViewController()
            playerViewController.player = player
            if let presentViewController = presentViewController {
                presentViewController.present(playerViewController, animated: true) {
                    playerViewController.player?.play()
                }
            }
        } else {
            XADLogger.error(message: "Error occurs when playing video with url: \(String(describing: urlString))")
        }
    }
    
    class func createCalendarEventWithEventJSON(_ eventJSON: String?) {
        XADLogger.debug(message: "Due to iOS 10 compatibility issue, save to calendar is deprecated")
    }
    
    class func storePictureWithUrlString(_ urlString: String?) {
        XADLogger.debug(message: "Due to iOS 10 compatibility issue, store picture is deprecated")
    }
    
    class func callTel(_ urlString: String?) throws {
        if let urlString = urlString,
            let url = URL(string: urlString),
            UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.openURL(url)
        } else {
            throw XADMRAIDServiceProviderError.malformedUrl
        }
    }
    
    class func sendSms(_ urlString: String?) throws {
        if let urlString = urlString,
            let url = URL(string: urlString),
            UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.openURL(url)
        } else {
            throw XADMRAIDServiceProviderError.malformedUrl
        }
    }
}
