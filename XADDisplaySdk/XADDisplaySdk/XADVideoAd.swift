//
//  XADVideoAd.swift
//  XADDisplaySdk
//
//  Created by Ray Wu on 1/18/17.
//  Copyright © 2017 Xad. All rights reserved.
//

import Foundation
import SafariServices

public class XADVideoAd: NSObject {
    //MARK: - Public properties
    public weak var testDelegate: XADDisplayTestDelegate?
    public weak var delegate: XADVideoAdDelegate?
    public weak var rootViewController: UIViewController?
    
    public var accessKey: String?
    public var trafficSource: String?
    public var adRequest: XADRequest?
    public fileprivate(set) var hasBeenUsed: Bool = false
    
    //MARK: - Private properties
    fileprivate var player: XADVASTViewController?
    fileprivate weak var sdkBase:XADDisplaySdk?
    fileprivate var hasBeenRequested: Bool = false
    
    //Required params for Video Ad
    fileprivate var vmin: Int
    fileprivate var vmax: Int
    
    public fileprivate(set) var isReady: Bool = false
    
    public init(vmin: Int = 10, vmax: Int = 30) {
        self.vmax = vmax
        self.vmin = vmin
        super.init()
        sdkBase = XADDisplaySdk.shared
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterBackground), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
    }
    
    fileprivate override init() {
        fatalError("Not a public init")
    }
    
    deinit {
        XADLogger.debug(message: "deinit")
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc public func loadAd() {
        assert(self.accessKey != nil, "AccessKey must be set before load ad")
        assert(self.adRequest != nil, "AdRequest must be set before load ad")
        assert(self.rootViewController != nil, "Must assign rootViewController to your current view controller")
        if self.trafficSource == nil {
            self.trafficSource = ""
            XADLogger.error(message: "GroundTruth will fail to record your traffic source, please set tag id before load ad")
        }
        
        guard !hasBeenRequested else {
            XADLogger.warning(message: "Video ad objects can only be used once even with different requests.")
            return
        }
        
        hasBeenRequested = true
        
        let creativeCompletionBlock = {[weak self] (adCreative, adGroupId) in
            DispatchQueue.main.async {
                self?.didReceiveAdCreative(adCreative, adGroupId: adGroupId)
            }
        }
        
        let errorBlock = { [weak self] (issueType) in
            self?.didReceiveError(issueType: issueType)
        }
        
        self.adRequest!.vmin = self.vmin
        self.adRequest!.vmax = self.vmax
        
        sdkBase?.fetchAdCreative(self.accessKey!,
                                 trafficSource: self.trafficSource!,
                                adRequest: self.adRequest!,
                                adSize: nil,
                                adType: .video,
                                creativeStringHandler: creativeCompletionBlock,
                                httpErrorHandler: errorBlock)
    }
    
    fileprivate func didReceiveAdCreative(_ adCreative:String, adGroupId: String) {
        guard !adCreative.isEmpty else {
            XADLogger.error(message: "No ad matched for current request...")
            self.delegate?.videoAdFailedToReceive?(withErrorCode: .noInventory)
            return
        }
        
        guard let rootViewController = self.rootViewController else {
            XADLogger.error(message: "RootViewController is destroyed")
            self.delegate?.videoAdFailedToReceive?(withErrorCode: .unknown)
            return
        }

        guard let vastData = adCreative.data(using: .utf8) else {
            XADLogger.error(message: "Failed to create data obj with current adcreative string.")
            self.delegate?.videoAdFailedToReceive?(withErrorCode: .unknown)
            return
        }
        self.player = XADVASTViewController(delegate: self, withViewController: rootViewController)
        self.player!.testDelegate = self.testDelegate
        self.player!.loadVideoWithData(xmlContent: vastData, adGroupId: adGroupId)
    }
    
    fileprivate func didReceiveError(issueType: Int) {
        switch issueType {
        case kNetworkIssue:
            XADLogger.error(message: "Network is lost...")
            self.delegate?.videoAdFailedToReceive?(withErrorCode: .networkError)
        case kRequestIssue:
            XADLogger.error(message: "Request is not valid...")
            self.delegate?.videoAdFailedToReceive?(withErrorCode: .badRequest)
        case kDecodeIssue:
            sendError(errorCode: .internalError, payload: "data Error")
            XADLogger.error(message: "Error")
            self.delegate?.videoAdFailedToReceive?(withErrorCode: .unknown)
        case kNoDataIssue:
            XADLogger.error(message: "No data return")
        default:
            XADLogger.error(message: "Error")
        }
        
    }
    
    
    public func playVideo() {
        guard let player = self.player,
            player.vastReady else {
            XADLogger.warning(message: "Video is not ready yet.")
            return
        }
        
        player.play()
    }
    
    func appWillEnterBackground() {
        self.delegate?.videoAdWillLeaveApplication?(self)
        if let player = self.player {
            player.pause()
        }
    }
    
    func appWillEnterForeground() {
        if let player = self.player {
            player.resume()
        }
    }
}

extension XADVideoAd: XADVASTViewControllerDelegate {
    func vastReady(vastVC: XADVASTViewController) {
        XADLogger.debug(message: "Video Ad Ready")
        self.isReady = true
        self.delegate?.videoAdDidReceived?(self)
    }
    
    func vastError(vastVC: XADVASTViewController, error: XADVASTError) {
        XADLogger.debug(message: "Video Ad Failed: \(error.rawValue)")
        self.delegate?.videoAdFailedToReceive?(withErrorCode: .unknown)
    }
    
    func vastWillPresentFullScreen(vastVC: XADVASTViewController) {
        XADLogger.debug(message: "Video Ad Show")
        hasBeenUsed = true
        self.delegate?.videoAdDidOpen?(self)
    }
    
    func vastVideoStartPlaying(vastVC: XADVASTViewController) {
        XADLogger.debug(message: "Video Ad Play")
        self.delegate?.videoAdDidStartPlaying?(self)
    }
    
    func vastDidDismissFullScreen(vastVC: XADVASTViewController) {
        XADLogger.debug(message: "Video Ad Close")
        self.delegate?.videoAdDidClose?(self)
    }
    
    func vastOpenBrowseWithUrl(vastVC: XADVASTViewController, url: URL) {
        XADLogger.debug(message: "Click through event: \(url.absoluteURL)")
        //Will use SafariViewController to open url within current app
        let safariVC = SFSafariViewController(url: url)
        vastVC.present(safariVC, animated: true)
    }
    
    func vastTrackingEvent(eventName: String) {
        XADLogger.debug(message: "Video Ad Track Event")
        //TODO: - Need manual impressions or not?
    }
}
