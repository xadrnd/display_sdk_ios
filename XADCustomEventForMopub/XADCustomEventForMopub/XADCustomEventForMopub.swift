//
//  XADCustomEventForMopub.swift
//  XADDisplaySdk
//
//  Created by Ray Wu on 1/19/17.
//  Copyright © 2017 Xad. All rights reserved.
//

fileprivate let TAG = "XADCustomEventForMopub"

open class XADCustomEventForMopub: MPBannerCustomEvent {
//just for info    weak open var delegate: MPBannerCustomEventDelegate!
    
    var xadBannerView:XADBannerView!
    weak var rootViewController:UIViewController!
    
    override open func requestAd(with size: CGSize, customEventInfo info: [AnyHashable : Any]!) {
        do {
            let bannerSize:XADBannerSize = try createAdSizeFromCGSize(size: size)
            guard let accessKey = info["accesskey"] as? String,
                let trafficSource = info["trafficsource"] as? String else {
                    delegate.bannerCustomEvent(self, didFailToLoadAdWithError: NSError(domain: "No access key or traffic source found", code: -1, userInfo: nil))
                    return
            }
            
            self.xadBannerView = XADBannerView(adSize: bannerSize, origin: CGPoint(x: 0, y: 0))
            self.xadBannerView.accessKey = accessKey
            self.xadBannerView.trafficSource = trafficSource
            self.xadBannerView.autoRefreshIntervalSeconds = 0
            self.xadBannerView.delegate = self
            let adRequest = self.buildRequest(from: info)
            self.xadBannerView.adRequest = adRequest
            self.xadBannerView.rootViewController = self.delegate.viewControllerForPresentingModalView()
            self.xadBannerView.loadAd()
        } catch {
            XADLogger.error(message: "Wrong ad size passed by mopub")
            delegate.bannerCustomEvent(self, didFailToLoadAdWithError: error)
        }
    }
    
    override open func rotate(to newOrientation: UIInterfaceOrientation) {
        
    }
    
    override open func didDisplayAd() {
        XADLogger.verbose(message: "GroundTruth banner has showed successfully.")
    }
    
    override open func enableAutomaticImpressionAndClickTracking() -> Bool {
        return true
    }
    
    fileprivate func buildRequest(from customEventInfo: [AnyHashable : Any]) -> XADRequest {
        //TODO: - How to get gender and age from mopub
        let request = XADRequest()
        var infoCopy:[AnyHashable : Any]! = customEventInfo
        if let isTestingString = infoCopy["testmode"] as? String,
            let isTesting = Bool(isTestingString) {
            request.isTesting = isTesting
        }
        
        request.extras = customEventInfo["extras"] as? [String : Any]
        return request
    }
}

//MARK: - XADBannerDelegate
extension XADCustomEventForMopub: XADBannerDelegate {
    public func bannerViewDidReceived(withAd ad:XADBannerView) {
        self.delegate.bannerCustomEvent(self, didLoadAd: ad)
    }
    public func bannerViewDidFailToReceive(withAd ad:XADBannerView, withError errorCode:XADErrorCode) {
        delegate.bannerCustomEvent(self, didFailToLoadAdWithError: errorCode.toError())
    }
    public func bannerViewWillPresentScreen(withAd ad:XADBannerView) {
        delegate.bannerCustomEventWillBeginAction(self)
    }
    public func bannerViewDidDismissScreen(withAd ad:XADBannerView) {
        delegate.bannerCustomEventDidFinishAction(self)
    }
    public func bannerViewWillLeaveApplication(withAd ad:XADBannerView) {
        delegate.bannerCustomEventWillLeaveApplication(self)
    }
}
