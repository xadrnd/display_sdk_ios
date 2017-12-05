//
//  XADSize.swift
//  XADDisplaySdk
//
//  Created by Ray Wu on 9/6/16.
//  Copyright © 2016 Xad. All rights reserved.
//

import UIKit

public func createAdSizeFromCGSize(size:CGSize) throws -> XADBannerSize {
    if size.width < 300.0 {
        throw BannerSizeError.tooSmall(reason: "width too small")
    }
    if size.width < 320.0 {
        if size.height < 50.0 {
            throw BannerSizeError.tooSmall(reason: "Height too small")
        }
        if size.height < 250.0 {
            return .narrowBanner
        }
        return .mediumRectangle
    }
    if size.width < 728.0 {
        if size.height < 50.0 {
            throw BannerSizeError.tooSmall(reason: "Height too small")
        }
        return .banner
    }
    
    if size.height < 90.0 {
        throw BannerSizeError.tooSmall(reason: "Height too small")
    }
    return .leaderBoard
}

public func getInterstitialSize() -> XADBannerSize {
    let screenRect = UIScreen.main.bounds
    let screenWidth = screenRect.width
    let screenHeight = screenRect.height
    if screenWidth < screenHeight {
        return screenWidth < 768 ? .small_interstitial_portrait : .large_interstitial_portrait
    } else {
        return screenHeight < 768 ? .small_interstitial_landscape : .large_interstitial_landscape
    }
}

public enum BannerSizeError: Error {
    case tooSmall(reason: String)
    case tooBig(reason: String)
}

@objc public enum XADBannerSize:Int{
    case banner  // 320x50
    case narrowBanner // 300x50
    case mediumRectangle // 300x250
    case leaderBoard // 728x90
    
    case small_interstitial_portrait //320x480
    case small_interstitial_landscape //480x320
    case large_interstitial_portrait //768x1024
    case large_interstitial_landscape //1024x768
    
    func size() -> CGSize {
        return CGSize(width: CGFloat(width()), height: CGFloat(height()))
    }
    
    func height() -> Int {
        switch self {
        case .banner, .narrowBanner:
            return 50
        case .mediumRectangle:
            return 250
        case .leaderBoard:
            return 90
        case .small_interstitial_portrait:
            return 480
        case .small_interstitial_landscape:
            return 320
        case .large_interstitial_portrait:
            return 1024
        case .large_interstitial_landscape:
            return 768
        }
    }
    
    func width() -> Int {
        switch self {
        case .banner:
            return 320
        case .mediumRectangle, .narrowBanner:
            return 300
        case .leaderBoard:
            return 728
        case .small_interstitial_portrait:
            return 320
        case .small_interstitial_landscape:
            return 480
        case .large_interstitial_portrait:
            return 768
        case .large_interstitial_landscape:
            return 1024
        }
    }
    
    func sizeDescription() -> String {
        return "\(self.width())x\(self.height())"
    }
    
    func fullDescription() -> String {
        return "Ad Size: \(self.sizeDescription())"
    }
}
