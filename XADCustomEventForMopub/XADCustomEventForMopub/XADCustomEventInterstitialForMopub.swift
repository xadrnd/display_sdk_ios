//
//  XADCustomEventInterstitialForMopub.swift
//  XADCustomEventForMopub
//
//  Created by Ray Wu on 2/3/17.
//  Copyright © 2017 Xad. All rights reserved.
//

open class XADCustomEventInterstitialForMopub: MPInterstitialCustomEvent {
    //weak open var delegate: MPInterstitialCustomEventDelegate!
    var interstitial:XADInterstitial?
    override open func requestInterstitial(withCustomEventInfo info: [AnyHashable : Any]!) {
        guard let accessKey = info["accesskey"] as? String,
            let trafficSource = info["trafficsource"] as? String else {
                self.delegate.interstitialCustomEvent(self, didFailToLoadAdWithError: NSError(domain: "No access key or traffic source found", code: -1, userInfo: nil))
                return
        }
        
        self.interstitial = XADInterstitial()
        if let interstitial = interstitial {
            interstitial.accessKey = accessKey
            interstitial.trafficSource = trafficSource
            interstitial.delegate = self
            interstitial.adRequest = self.buildRequest(from: info)
            interstitial.loadAd()
        }
    }
    
    override open func showInterstitial(fromRootViewController rootViewController: UIViewController!) {
        if let interstitial = self.interstitial {
            interstitial.rootViewController = rootViewController
            interstitial.showInterstitial()
        }
    }
    
    override open func enableAutomaticImpressionAndClickTracking() -> Bool {
        return true
    }
    
    fileprivate func buildRequest(from customEventInfo: [AnyHashable : Any]!) -> XADRequest {
        //TODO: - How to get gender and age from mopub
        let request = XADRequest()
        var infoCopy:[AnyHashable : Any]! = customEventInfo
        if let isTestingString = infoCopy["test_mode"] as? String,
            let isTesting = Bool(isTestingString) {
            request.isTesting = isTesting
            infoCopy.removeValue(forKey: "test_mode")
        }
        
        request.extras = infoCopy as? [String: String]
        return request
    }
}

extension XADCustomEventInterstitialForMopub: XADInterstitialDelegate {
    public func interstitialDidFailToReceiveAd(_ interstitial:XADInterstitial, withError error:XADErrorCode) {
        self.delegate.interstitialCustomEvent(self, didFailToLoadAdWithError: error.toError())
    }
    public func interstitialDidReceiveAd(_ interstitial:XADInterstitial) {
        self.delegate.interstitialCustomEvent(self, didLoadAd: self.interstitial)
    }
    public func interstitialWillPresentScreen(_ interstitial:XADInterstitial) {
        self.delegate.interstitialCustomEventWillAppear(self)
    }
    public func interstitialDidFailToPresentScreen(_ interstitial:XADInterstitial) {
    }
    public func interstitialWillDismissScreen(_ interstitial:XADInterstitial) {
        self.delegate.interstitialCustomEventWillDisappear(self)
    }
    public func interstitialDidDismissScreen(_ interstitial:XADInterstitial) {
        self.delegate.interstitialCustomEventDidDisappear(self)
    }
    public func interstitialWillLeaveApplication(_ interstitial:XADInterstitial) {
        
    }
}
