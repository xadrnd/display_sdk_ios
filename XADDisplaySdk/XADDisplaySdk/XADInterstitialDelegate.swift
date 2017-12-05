//
//  XADInterstitialDelegate.swift
//  XADDisplaySdk
//
//  Created by Ray Wu on 10/5/16.
//  Copyright © 2016 Xad. All rights reserved.
//

import UIKit

@objc public protocol XADInterstitialDelegate: NSObjectProtocol {
    @objc optional func interstitialDidFailToReceiveAd(_ interstitial:XADInterstitial, withError error:XADErrorCode)
    @objc optional func interstitialDidReceiveAd(_ interstitial:XADInterstitial)
    @objc optional func interstitialWillPresentScreen(_ interstitial:XADInterstitial)
    @objc optional func interstitialDidFailToPresentScreen(_ interstitial:XADInterstitial)
    @objc optional func interstitialWillDismissScreen(_ interstitial:XADInterstitial)
    @objc optional func interstitialDidDismissScreen(_ interstitial:XADInterstitial)
    @objc optional func interstitialWillLeaveApplication(_ interstitial:XADInterstitial)
}
