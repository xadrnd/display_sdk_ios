//
//  XADVASTEventProcessor.swift
//  XADVAST
//
//  Created by Phillip Corrigan on 8/5/16.
//  Copyright © 2016 xAd, Inc. All rights reserved.
//

import UIKit
import Foundation

enum XADVASTEvent : String {
    case start = "start"
    case firstQuartile = "firstquartile"
    case midpoint = "midpoint"
    case thirdQuartile = "thirdquartile"
    case complete = "complete"
    case close = "close"
    case pause = "pause"
    case resume = "resume"
    //rest of the tracks
    case creativeView = "creativeview"
    case mute = "mute"
    case unmute = "unmute"
    case rewind = "rewind"
    case fullscreen = "fullscreen"
    case expand = "expand"
    case collapse = "collapse"
    case acceptInvitation = "acceptinvitation"
}

class XADVASTEventProcessor: NSObject {
    var trackingEvents:[String: [URL]]?
    weak var delegate:XADVASTViewControllerDelegate?
    weak var testDelegate:XADDisplayTestDelegate?
    
    // designated initializer, uses tracking events stored in VASTModel
    init(trackingEvents: [String: [URL]]?, withDelegate delegate: XADVASTViewControllerDelegate?, withTestDelegate testDelegate: XADDisplayTestDelegate?) {
        super.init()
        self.trackingEvents = trackingEvents
        self.delegate = delegate
        self.testDelegate = testDelegate
    }
    
    func trackEvent(_ vastEvent: XADVASTEvent) {
        delegate?.vastTrackingEvent(eventName: vastEvent.rawValue)
        guard let trackingEvents = self.trackingEvents,
        let trackingURLs = trackingEvents[vastEvent.rawValue] else {
                XADLogger.warning("VAST - Event Processor", message: "No such tracking event found: \(vastEvent.rawValue)")
                return
        }
        
        for aURL in trackingURLs {
            XADLogger.debug("VAST - Event Processor", message: "Sending track event:\(vastEvent.rawValue)")
            self.sendTrackingRequest(aURL)
        }
    }

    // sends the given VASTEvent
    func sendVASTUrlsWithId(_ vastUrls: [XADVASTUrlWithId]) {
        for urlWithId in vastUrls {
            self.sendTrackingRequest(urlWithId.url)
            XADLogger.debug("VAST - Event Processor", message: "Sending http request \(urlWithId.id_) to url: \(urlWithId.url)")
        }
    }

    func sendTrackingRequest(_ trackingURL: URL) {
        let sendTrackRequestQueue = DispatchQueue.global()
        self.testDelegate?.intercept(url: trackingURL)
        sendTrackRequestQueue.async {
            let trackingURLRequest = URLRequest(url: trackingURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 5.0)
            XADLogger.debug("VAST - Event Processor", message: "Event processor sending request to url: \(trackingURL.absoluteString)")
            URLSession.shared.dataTask(with: trackingURLRequest)
            // Send the request only, no response or errors handling
        }
    }
}
