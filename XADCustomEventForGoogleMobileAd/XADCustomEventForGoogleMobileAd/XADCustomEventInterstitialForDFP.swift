//
//  XADCustomEventInterstitialDFP.swift
//  XADCustomEventForGoogleMobileAd
//
//  Created by Ray Wu on 2/3/17.
//  Copyright © 2017 Xad. All rights reserved.
//
import GoogleMobileAds
import XADDisplaySdk

fileprivate let TAG = "XADCustomEventInterstitialForDFP"

public class XADCustomEventInterstitialForDFP: NSObject, GADCustomEventInterstitial {
    weak public var delegate: GADCustomEventInterstitialDelegate?
    var interstitial:XADInterstitial!
    
    public func requestAd(withParameter serverParameterAsAccessKey: String?, label serverLabelAsTrafficSource: String?, request: GADCustomEventRequest) {
        guard let serverParameterAsAccessKey = serverParameterAsAccessKey,
        let serverLabelAsTrafficSource = serverLabelAsTrafficSource else {
            XADLogger.error(TAG, message: "No serverParamter or serverLabel found")
            self.delegate?.customEventInterstitial(self, didFailAd: XADErrorCode.badRequest.toError())
            return
        }
        
        self.interstitial = XADInterstitial()
        self.interstitial.delegate = self
        self.interstitial.accessKey = serverParameterAsAccessKey
        self.interstitial.trafficSource = serverLabelAsTrafficSource
        self.interstitial.adRequest = self.buildRequest(from: request)
        self.interstitial.loadAd()
    }
    
    public func present(fromRootViewController rootViewController: UIViewController) {
        interstitial.rootViewController = rootViewController
        interstitial.showInterstitial()
    }
    
    fileprivate func buildRequest(from request: GADCustomEventRequest) -> XADRequest {
        let xadRequest: XADRequest = XADRequest(gender: self.userGender(from: request.userGender), birthday: request.userBirthday)
        return xadRequest
    }
    
    fileprivate func userGender(from gender: GADGender?) -> Gender {
        guard let gender = gender else{
            return .unknown
        }
        switch gender {
        case .male:
            return .male
        case .female:
            return .female
        case .unknown:
            return .unknown
        }
    }
}

//MARK: - XADInterstitialDelegate
extension XADCustomEventInterstitialForDFP: XADInterstitialDelegate {
    public func interstitialDidFailToReceiveAd(_ interstitial: XADInterstitial, withError error: XADErrorCode) {
        self.delegate?.customEventInterstitial(self, didFailAd: error.toError())
    }
    
    public func interstitialDidReceiveAd(_ interstitial:XADInterstitial) {
        self.delegate?.customEventInterstitialDidReceiveAd(self)
    }
    
    public func interstitialWillPresentScreen(_ interstitial:XADInterstitial) {
        self.delegate?.customEventInterstitialWillPresent(self)
    }
    
    public func interstitialDidFailToPresentScreen(_ interstitial:XADInterstitial) {
        //Nothing
    }
    
    public func interstitialWillDismissScreen(_ interstitial:XADInterstitial) {
        self.delegate?.customEventInterstitialWillDismiss(self)
    }
    
    public func interstitialDidDismissScreen(_ interstitial:XADInterstitial) {
        self.delegate?.customEventInterstitialDidDismiss(self)
    }
    
    public func interstitialWillLeaveApplication(_ interstitial:XADInterstitial) {
        self.delegate?.customEventInterstitialWillLeaveApplication(self)
    }
}
