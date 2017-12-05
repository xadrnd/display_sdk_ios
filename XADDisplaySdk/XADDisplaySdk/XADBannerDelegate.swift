//
//  XADDelegate.swift
//  XADDisplaySdk
//
//  Created by Ray Wu on 9/6/16.
//  Copyright © 2016 Xad. All rights reserved.
//

import UIKit

@objc public protocol XADBannerDelegate: NSObjectProtocol {
    @objc optional func bannerViewDidReceived(withAd ad:XADBannerView)
    @objc optional func bannerViewDidFailToReceive(withAd ad:XADBannerView, withError errorCode:XADErrorCode)
    @objc optional func bannerViewWillPresentScreen(withAd ad:XADBannerView)
    @objc optional func bannerViewDidDismissScreen(withAd ad:XADBannerView)
    @objc optional func bannerViewWillLeaveApplication(withAd ad:XADBannerView)
}
