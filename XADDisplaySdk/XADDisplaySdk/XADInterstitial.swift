//
//  XADInterstitial.swift
//  XADDisplaySdk
//
//  Created by Ray Wu on 10/3/16.
//  Copyright © 2016 Xad. All rights reserved.
//

import UIKit
import SafariServices

public class XADInterstitial: NSObject {
    //MARK: - Public properties
    public weak var testDelegate: XADDisplayTestDelegate?
    public weak var delegate:XADInterstitialDelegate?
    public weak var rootViewController:UIViewController?
    
    public var accessKey:String?
    public var trafficSource: String?
    public var adRequest:XADRequest?
    public fileprivate(set) var hasBeenUsed: Bool = false

    //MARK: - Private properties
    fileprivate var mraidViewAsInterstitial: XADMRAIDView?
    fileprivate weak var sdkBase:XADDisplaySdk?
    fileprivate var hasFailed: Bool = false
    fileprivate var hasBeenRequested: Bool = false
    
    public var isReady: Bool = false
    //MARK: -
    
    public override init() {
        sdkBase = XADDisplaySdk.shared
        super.init()
    }
    
    deinit {
        XADLogger.debug(message: "deinit")
        NotificationCenter.default.removeObserver(self)
    }
    
    public func loadAd(){
        assert(self.accessKey != nil, "AccessKey must be set before load ad")
        assert(self.adRequest != nil, "AdRequest must be set before load ad")
        assert(self.rootViewController != nil, "Must assign rootViewController to your current view controller")
        if self.trafficSource == nil {
            self.trafficSource = ""
            XADLogger.error(message: "GroundTruth will fail to record your traffic source, please set tag id before load ad")
        }
        
        guard !hasBeenRequested else {
            XADLogger.warning(message: "Interstitial ad objects can only be used once even with different requests.")
            return
        }
        
        hasBeenRequested = true
        
        let createInterstitialBlock = {[weak self] (adCreative, adGroupId) in
            DispatchQueue.main.async{
                self?.didReceiveAdCreative(adCreative, adGroupId: adGroupId)
            }
        }
        
        let errorBlock = { [weak self](issueType) in
            DispatchQueue.main.async{
                self?.didReceiveError(issueType)
            }
            
        }
        
        sdkBase?.fetchAdCreative(accessKey!,
                                 trafficSource: self.trafficSource!,
                                 adRequest: self.adRequest!,
                                 adSize: getInterstitialSize(),
                                 adType: .interstitial,
                                 creativeStringHandler: createInterstitialBlock,
                                 httpErrorHandler: errorBlock)
    }
    
    fileprivate func didReceiveAdCreative(_ adCreative:String, adGroupId: String) {
        guard !adCreative.isEmpty else {
            self.delegate?.interstitialDidFailToReceiveAd?(self, withError: .noInventory)
            XADLogger.warning(message: "No ad matched for current request...")
            return
        }
        
        guard let rootViewController = self.rootViewController else {
            XADLogger.error(message: "Root ViewController is destroyed")
            self.delegate?.interstitialDidFailToReceiveAd?(self, withError: .unknown)
            return
        }
        
        self.mraidViewAsInterstitial = XADMRAIDView(frame: CGRect.zero, htmlData: adCreative, adGroupId: adGroupId, baseURL: nil, asInterstitial: true, rootViewController: rootViewController)
        self.mraidViewAsInterstitial!.delegate = self
        self.mraidViewAsInterstitial!.serviceDelegate = self
        self.mraidViewAsInterstitial!.testDelegate = self.testDelegate
    }
    
    fileprivate func didReceiveError(_ issueType: Int) {
        switch issueType {
        case kRequestIssue:
            XADLogger.error(message: "Request is not valid...")
            delegate?.interstitialDidFailToReceiveAd?(self, withError: .badRequest)
        case kNetworkIssue:
            XADLogger.error(message: "Network is lost...")
            delegate?.interstitialDidFailToReceiveAd?(self, withError: .networkError)
        case kDecodeIssue:
            XADLogger.error(message: "Internal Error")
            sendError(errorCode: .internalError, payload: "data Error")
            delegate?.interstitialDidFailToReceiveAd?(self, withError: .unknown)
        case kNoDataIssue:
            XADLogger.error(message: "No data return")
        default:
            XADLogger.error(message: "Error")
        }
    }
    
    
    public func showInterstitial() {
        guard let interstitial = self.mraidViewAsInterstitial,
            self.isReady else  {
                XADLogger.warning(message: "Interstitial is not ready. Please wait until you receive \"interstitialDidReceiveAd\" delegate.")
                return
        }
        
        if self.hasFailed {
            XADLogger.error(message: "Failed to present due to internal error")
            self.delegate?.interstitialDidFailToPresentScreen?(self)
        } else {
            interstitial.showAsInterstitial()
        }
    }
}

//MARK: - XADMRAIDViewDelegate
extension XADInterstitial: XADMRAIDViewDelegate {
    func mraidViewReady(_ mraidView: XADMRAIDView) {
        XADLogger.debug(message: "\(#function)")
        self.isReady = true
        self.delegate?.interstitialDidReceiveAd?(self)
    }
    func mraidViewFailed(_ mraidView: XADMRAIDView) {
        XADLogger.error(message: "\(#function)")
        self.hasFailed = true
    }
    func mraidViewWillExpand(_ mraidView: XADMRAIDView) {
        XADLogger.debug(message: "\(#function)")
        self.delegate?.interstitialWillPresentScreen?(self)
        self.hasBeenUsed = true
    }
    func mraidViewWillClose(_ mraidView: XADMRAIDView) {
        XADLogger.debug(message: "\(#function)")
        self.delegate?.interstitialWillDismissScreen?(self)
    }
    func mraidViewDidClose(_ mraidView: XADMRAIDView) {
        XADLogger.debug(message: "\(#function)")
        self.delegate?.interstitialDidDismissScreen?(self)
    }
    
    func mraidViewWillResize(_ mraidView: XADMRAIDView, absolutePosition: CGRect, allowOffscreen: Bool) {
        //Interstitial ad should never be resized
    }
}

//MARK: - XADMRAIDServiceDelegate
extension XADInterstitial: XADMRAIDServiceDelegate {
    func mraidServiceCreateCalendarEventWithEventJSON(_ eventJSON: String?) {
        XADMRAIDServiceProvider.createCalendarEventWithEventJSON(eventJSON)
    }
    func mraidServicePlayVideoWithUrlString(_ urlString: String?, presentViewController: UIViewController?) {
        XADMRAIDServiceProvider.playVideoWithUrlString(urlString, presentViewController: presentViewController)
    }
    func mraidServiceStorePictureWithUrlString(_ urlString: String?) {
        XADMRAIDServiceProvider.storePictureWithUrlString(urlString)
    }
    func mraidServiceCallTel(_ urlString: String?, presentViewController: UIViewController?) {
        if Constants.kSupportedFeatures.contains(.tel){
            do  {
                try XADMRAIDServiceProvider.callTel(urlString)
                self.delegate?.interstitialWillLeaveApplication?(self)
            } catch {
                XADLogger.error(message: "Fail to open \(String(describing: urlString))")
            }
        } else {
            XADLogger.warning(message: "Sending TEL is not support")
        }
    }
    
    func mraidServiceSendSMS(_ urlString: String?, presentViewController: UIViewController?) {
        if Constants.kSupportedFeatures.contains(.sms){
            do  {
                try XADMRAIDServiceProvider.sendSms(urlString)
                self.delegate?.interstitialWillLeaveApplication?(self)
            } catch {
                XADLogger.error(message: "Fail to open \(String(describing: urlString))")
            }
        } else {
            XADLogger.warning(message: "Sending SMS is not support")
        }
    }
    
    func mraidServiceOpenBrowser(_ urlString: String?, presentViewController: UIViewController?) {
        XADLogger.debug("XADBannerView", message: "open in landing page: \(String(describing: urlString))")
        //Will use SafariViewController to open url within current app
        if let presentViewController = presentViewController,
            let urlString = urlString,
            let url = URL(string: urlString),
            UIApplication.shared.canOpenURL(url){
            self.delegate?.interstitialWillPresentScreen?(self)
            let safariVC = SFSafariViewController(url: url)
            presentViewController.present(safariVC, animated: true)
        } else {
            XADLogger.error(message: "Fail to open \(String(describing: urlString))")
        }
    }
}
