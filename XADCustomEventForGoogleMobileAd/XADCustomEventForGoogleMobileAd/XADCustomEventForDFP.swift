//
//  XADCustomEventForDFP.swift
//
//  Created by Ray Wu on 11/8/16.
//  Copyright © 2016 Google. All rights reserved.
//
import GoogleMobileAds
import XADDisplaySdk

fileprivate let TAG = "XADCustomEventBannerForDFP"

public class XADCustomEventForDFP: NSObject, GADCustomEventBanner {
    weak public var delegate: GADCustomEventBannerDelegate?
    var xadBannerView:XADBannerView!
    weak var rootViewController:UIViewController?
    
    public func requestAd(_ adSize: GADAdSize, parameter serverParameterAsAccessKey: String?, label serverLabelAsTrafficSource: String?, request: GADCustomEventRequest) {
        var bannerSize:XADBannerSize
        do {
            bannerSize = try createAdSizeFromCGSize(size: adSize.size)
        } catch {
            XADLogger.error(TAG, message: "\(error.localizedDescription)")
            self.delegate?.customEventBanner(self, didFailAd: XADErrorCode.badRequest.toError())
            return
        }
        
        guard let serverParameterAsAccessKey = serverParameterAsAccessKey,
            let serverLabelAsTrafficSource = serverLabelAsTrafficSource else {
                XADLogger.error(TAG, message: "No serverParamter or serverLabel found")
                self.delegate?.customEventBanner(self, didFailAd: XADErrorCode.badRequest.toError())
                return
        }
        
        xadBannerView = XADBannerView(adSize: bannerSize, origin: CGPoint(x: 0, y: 0))
        
        xadBannerView.accessKey = serverParameterAsAccessKey
        xadBannerView.trafficSource = serverLabelAsTrafficSource
        xadBannerView.adRequest = self.buildRequest(from: request)
        xadBannerView.autoRefreshIntervalSeconds = 0
        xadBannerView.delegate = self
        rootViewController = delegate?.viewControllerForPresentingModalView
        xadBannerView.rootViewController = rootViewController
        xadBannerView.loadAd()
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

extension XADCustomEventForDFP: XADBannerDelegate {
    public func bannerViewDidReceived(withAd ad: XADBannerView) {
        delegate?.customEventBanner(self, didReceiveAd: ad)
    }
    
    public func bannerViewDidFailToReceive(withAd ad:XADBannerView, withError error:XADErrorCode) {
        self.delegate?.customEventBanner(self, didFailAd: error.toError())
    }
    
    public func bannerViewWillPresentScreen(withAd ad:XADBannerView) {
        self.delegate?.customEventBannerWillPresentModal(self)
    }
    
    public func bannerViewDidDismissScreen(withAd ad:XADBannerView) {
        self.delegate?.customEventBannerDidDismissModal(self)
    }
    
    public func bannerViewWillLeaveApplication(withAd ad:XADBannerView) {
        self.delegate?.customEventBannerWillLeaveApplication(self)
    }
}
