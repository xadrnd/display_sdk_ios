//
//  Constants.swift
//  XADDisplaySdk
//
//  Created by Ray Wu on 4/7/17.
//  Copyright © 2017 Xad. All rights reserved.
//
struct Constants{
    static let kCloseEventRegionSize: Double  = 50.0 // For MRAIDView close region
    static let kCloseEventRegionMargin: Double = 0.0 // For both close button top and right margin
    static let kCloseButtonSize: Double = 25.0 // For VASTViewController close button
    
    //Not used since not use controls toolbar for VASTViewController
    static let kControlsToolbarFixedLeftWidth: Float = 16.0
    static let kControlsToolbarFixedPauseWidth: Float = 42.0
    static let kControlsToolbarFixedInfoWidth: Float = 22.0
    static let kControlsToolbarInfoButtonSize: Double = 25.0
    static let kControlTimerInterval: Double = 2.0
    static let kControlsToolbarHeight: Float = 44.0
    
    //Server endpoint
    static let kXadServerEndpoint:String = "https://display.xad.com/rest/banner"
    static let kXadTestServerEndpoint:String = "https://testchannel.xad.com"
    static let kXadServerErrorEndpoint: String = "https://display.xad.com/sdk/errors"
    
    static let kDistantFilter: Double = 3.0
    
    //MRAID support
    static let kSupportedFeatures: [XADMRAIDSupport] = [.sms, .tel, .inlineVideo]
    
    //MOAT keys
    static let kMoatPartnerCodeForBanner = "xaddisplay162341870938"
    static let kMoatPartnerCodeForVideo = "xadvideo613478971360"
    
    static let kDebugOnBackend = false

}
