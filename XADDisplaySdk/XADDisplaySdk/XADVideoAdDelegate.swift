//
//  XADVideoAdDelegate.swift
//  XADDisplaySdk
//
//  Created by Ray Wu on 1/18/17.
//  Copyright © 2017 Xad. All rights reserved.
//

import Foundation

@objc public protocol XADVideoAdDelegate: NSObjectProtocol {
    @objc optional func videoAdDidReceived(_ videoAd: XADVideoAd)
    @objc optional func videoAdFailedToReceive(withErrorCode errocCode: XADErrorCode)
    @objc optional func videoAdDidOpen(_ videoAd: XADVideoAd)
    @objc optional func videoAdDidStartPlaying(_ videoAd: XADVideoAd)
    @objc optional func videoAdDidClose(_ videoAd: XADVideoAd)
    @objc optional func videoAdWillLeaveApplication(_ videoAd: XADVideoAd)
}
