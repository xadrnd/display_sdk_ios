//
//  XADBannerView.swift
//  XADDisplaySdk
//
//  Created by Ray Wu on 9/6/16.
//  Copyright © 2016 Xad. All rights reserved.
//

import UIKit
import SafariServices

public class XADBannerView: UIView {
    //MARK: - Public properties
    public weak var testDelegate: XADDisplayTestDelegate?
    @IBOutlet public weak var delegate: XADBannerDelegate?
    @IBOutlet public weak var rootViewController: UIViewController?
    
    @IBInspectable public var accessKey: String?
    @IBInspectable public var autoRefreshIntervalSeconds: Double = 90.0
    @IBInspectable public var trafficSource: String?
    
    open var adRequest:XADRequest?
    
    //MARK: - Private properties
    weak var sdkBase:XADDisplaySdk?
    var bannerRefreshQueue: DispatchQueue?
    var adSize:XADBannerSize!
    var hasBeenRequested: Bool = false
    
    var mraidView: XADMRAIDView?
    override open var isHidden: Bool {
        didSet {
            if let mraidView = mraidView,
                oldValue != self.isHidden {
                if mraidView.state != .resized {
                    mraidView.isViewable = !isHidden
                }
            }
        }
    }
    
    
    // For Storyboard
    required public init?(coder:NSCoder) {
        self.sdkBase = XADDisplaySdk.shared
        super.init(coder: coder)
        do {
            self.adSize = try createAdSizeFromCGSize(size: self.frame.size)
        } catch {
            assertionFailure("Size not match: \(error)")
        }
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterBackground), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        
    }
    
    
    // For handcraft UI
    public init(adSize:XADBannerSize, origin:CGPoint) {
        sdkBase = XADDisplaySdk.shared
        self.adSize = adSize
        let frame = CGRect(x: origin.x, y: origin.y, width: adSize.size().width, height: adSize.size().height)
        super.init(frame: frame)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterBackground), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
    }
    
    deinit {
        XADLogger.debug(message: "deinit")
        NotificationCenter.default.removeObserver(self)
    }
    
    
    public func loadAd() {
        assert(self.accessKey != nil, "AccessKey must be set before load ad")
        assert(self.adRequest != nil, "AdRequest must be set before load ad")
        assert(self.rootViewController != nil, "Must assign rootViewController to your current view controller")
        if self.trafficSource == nil {
            self.trafficSource = ""
            XADLogger.error(message: "GroundTruth will fail to record your traffic source, please set tag id before load ad")
        }

        guard !hasBeenRequested else {
            XADLogger.warning(message: "Banner will auto refresh with certain time, please don't load request multiple times.")
            return
        }
        
        self.hasBeenRequested = true
        
        self.loadNextAd(accessKey: self.accessKey!, adRequest: self.adRequest!)
    }
    
    
    fileprivate func loadNextAd(accessKey: String, adRequest: XADRequest) {
        
        let adReceivedCompletionBlock = {[weak self] (adCreative, adGroupId) in
            DispatchQueue.main.async {
                self?.didReceiveAdCreative(adCreative, adGroupId: adGroupId)
            }
        }
        
        let adErrorCompletionBlock = { [weak self] (issueType) in
            self?.didReceiveError(issueType)
        }
        
        sdkBase?.fetchAdCreative(accessKey,
                                 trafficSource: self.trafficSource!,
                                 adRequest: adRequest,
                                 adSize: self.adSize,
                                 adType: .banner,
                                 creativeStringHandler: adReceivedCompletionBlock,
                                 httpErrorHandler: adErrorCompletionBlock)
        
        if autoRefreshIntervalSeconds > 0.0 {
            if self.autoRefreshIntervalSeconds < 10 {
                self.autoRefreshIntervalSeconds = 10 // Min is 10
            }

            if self.autoRefreshIntervalSeconds > 120 {
                self.autoRefreshIntervalSeconds = 120 // Max is 120
            }

            self.bannerRefreshQueue = DispatchQueue(label: "com.xad.REFRESH")
            bannerRefreshQueue!.asyncAfter(deadline: DispatchTime.now() + autoRefreshIntervalSeconds, execute: {[weak self]() in
                self?.loadNextAd(accessKey: accessKey, adRequest: adRequest)
            })
        }
    }
    
    open func loadAd(docData: String) {
        //Only certain access keys can use this method to load banner with doc data
        //TODO: - Use provisioning to manage key to restrict outside access
        assert(self.accessKey != nil && ["upT9vzr2jgqyw_g7pi5tv6HjLcP0-U68DPdTMcMwvw0."].contains(self.accessKey!), "Only authorized access keys is allowed in order to load ad with doc data")
        if let docDataUrl = URL(string: docData) {
            let adReceivedCompletionBlock = {[weak self] (adCreative, adGroupId) in
                DispatchQueue.main.async {
                    self?.didReceiveAdCreative(adCreative, adGroupId: adGroupId)
                }
            }
            
            let adErrorCompletionBlock = { [weak self] (issueType) in
                self?.didReceiveError(issueType)
            }
            
            sdkBase?.fetchAdCreative(docData: docDataUrl, creativeStringHandler: adReceivedCompletionBlock, httpErrorHandler: adErrorCompletionBlock)
        }
    }
    
    fileprivate func didReceiveAdCreative(_ adCreative:String, adGroupId: String) {
        
        guard !adCreative.isEmpty else {
            XADLogger.warning(message: "No ad matched for current request...")
            self.delegate?.bannerViewDidFailToReceive?(withAd: self, withError: .noInventory)
            return
        }
        
        guard let rootViewController = self.rootViewController else {
            XADLogger.error(message: "Root ViewController is destroyed")
            self.delegate?.bannerViewDidFailToReceive?(withAd: self, withError: .unknown)
            return
        }

        let frame = CGRect(origin: CGPoint(x:0.0, y:0.0), size: self.adSize.size())

        self.mraidView = XADMRAIDView(frame: frame, htmlData: adCreative, adGroupId: adGroupId, baseURL: nil, rootViewController: rootViewController)
        
        self.mraidView!.delegate = self
        self.mraidView!.serviceDelegate = self
        self.mraidView!.testDelegate = self.testDelegate
        
        self.mraidView!.backgroundColor = getSuperColor(self)
        self.subviews.forEach({$0.removeFromSuperview()})
        self.addSubview(mraidView!)
        self.isHidden = false
        self.add(subView: mraidView!, withSize: (Double(self.adSize.width()), Double(self.adSize.height())), toPosition: [(.centerX, 0.0), (.centerY, 0.0)])
    }
    
    fileprivate func didReceiveError(_ issueType: Int) {
        switch issueType {
        case kRequestIssue:
            XADLogger.error(message: "Request is not valid...")
            self.delegate?.bannerViewDidFailToReceive?(withAd: self, withError: .badRequest)
        case kNetworkIssue:
            XADLogger.error(message: "Network is lost...")
            self.delegate?.bannerViewDidFailToReceive?(withAd: self, withError: .networkError)
        case kDecodeIssue:
            XADLogger.error(message: "Internal Error")
            sendError(errorCode: .internalError, payload: "data Error")
            self.delegate?.bannerViewDidFailToReceive?(withAd: self, withError: .unknown)
        case kNoDataIssue:
            XADLogger.error(message: "No data return")
        default:
            XADLogger.error(message: "Error")
        }
    }
    
    fileprivate func getSuperColor(_ view:UIView) -> UIColor {
        var curView = view
        while let superView = curView.superview {
            if let color = superView.backgroundColor {
                if color != UIColor.clear {
                    return color
                }
            }
            curView = superView
        }
        return UIColor.clear
    }
    
    func appWillEnterBackground() {
        if let bannerRefreshQueue = self.bannerRefreshQueue {
            bannerRefreshQueue.suspend()
        }
        self.delegate?.bannerViewWillLeaveApplication?(withAd: self)
    }
    
    func appWillEnterForeground() {
        if let bannerRefreshQueue = self.bannerRefreshQueue {
            bannerRefreshQueue.resume()
        }
    }
}




//MARK: - XADMRAIDViewDelegate
extension XADBannerView: XADMRAIDViewDelegate {
    
    func mraidViewReady(_ mraidView: XADMRAIDView) {
        XADLogger.debug(message: "\(#function)")
        self.delegate?.bannerViewDidReceived?(withAd: self)
    }
    
    func mraidViewFailed(_ mraidView: XADMRAIDView) {
        XADLogger.debug(message: "\(#function)")
        self.delegate?.bannerViewDidFailToReceive?(withAd:self, withError: .unknown)
    }
    
    func mraidViewWillExpand(_ mraidView: XADMRAIDView) {
        XADLogger.debug(message: "\(#function)")
        self.delegate?.bannerViewWillPresentScreen?(withAd: self)
    }
    
    func mraidViewWillClose(_ mraidView: XADMRAIDView) {
        //Leave blank
    }
    
    // mraidViewDidClose - View implies Expanded or Resized Views
    func mraidViewDidClose(_ mraidView: XADMRAIDView) {
        XADLogger.debug(message: "\(#function)")
        // Show banner once expanded or resized are closed
        // make self visible from resize
        self.isHidden = false
        self.delegate?.bannerViewDidDismissScreen?(withAd: self)
    }
    
    
    // mraidViewWillResize - View implies the mraid banner view, not the expanded or resized
    func mraidViewWillResize(_ mraidView: XADMRAIDView, absolutePosition: CGRect, allowOffscreen: Bool) {
        XADLogger.debug(message: "\(#function)")
        // Hide banner once expanded or resized are added directly on rootViewController
        self.isHidden = true
    }
}




//MARK: - XADMRAIDServiceDelegate
extension XADBannerView: XADMRAIDServiceDelegate {
    
    func mraidServiceCreateCalendarEventWithEventJSON(_ eventJSON: String?) {
        XADMRAIDServiceProvider.createCalendarEventWithEventJSON(eventJSON)
    }
    
    func mraidServiceStorePictureWithUrlString(_ urlString: String?) {
        XADMRAIDServiceProvider.storePictureWithUrlString(urlString)
    }
    
    func mraidServicePlayVideoWithUrlString(_ urlString: String?, presentViewController: UIViewController?) {
        XADMRAIDServiceProvider.playVideoWithUrlString(urlString, presentViewController: presentViewController)
    }
    
    func mraidServiceCallTel(_ urlString: String?, presentViewController: UIViewController?) {
        if Constants.kSupportedFeatures.contains(.tel){
            do  {
                try XADMRAIDServiceProvider.callTel(urlString)
                self.delegate?.bannerViewWillLeaveApplication?(withAd: self)
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
                self.delegate?.bannerViewWillLeaveApplication?(withAd: self)
            } catch {
                XADLogger.error(message: "Fail to open \(String(describing: urlString))")
            }
        } else {
            XADLogger.warning(message: "Sending SMS is not support")
        }
    }
    
    
    func mraidServiceOpenBrowser(_ urlString: String?, presentViewController: UIViewController?) {
        
        XADLogger.debug(message: "open in landing page: \(String(describing: urlString))")
        //Will use SafariViewController to open url within current app
        if let presentViewController = presentViewController,
            let urlString = urlString,
            let url = URL(string: urlString),
            UIApplication.shared.canOpenURL(url){
            let safariVC = SFSafariViewController(url: url)
            safariVC.delegate = self
            self.delegate?.bannerViewWillPresentScreen?(withAd: self)
            presentViewController.present(safariVC, animated: true)
        } else {
            XADLogger.error(message: "Fail to open \(String(describing: urlString))")
        }
    }
}


extension XADBannerView: SFSafariViewControllerDelegate {
    public func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        self.delegate?.bannerViewDidDismissScreen?(withAd: self)
    }
}


