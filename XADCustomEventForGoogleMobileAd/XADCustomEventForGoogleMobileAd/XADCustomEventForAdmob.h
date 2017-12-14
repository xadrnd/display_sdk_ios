//
//  XADCustomEventForAdmob.h
//  XADCustomEventForGoogleMobileAd
//
//  Created by Jacob Zelek on 12/13/17.
//  Copyright © 2017 Xad. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GADCustomEventBanner.h>
#import <GoogleMobileAds/GADCustomEventBannerDelegate.h>
#import <GroundTruthDisplaySDK/XADDisplaySdk.h>

@interface XADCustomEventForAdmob: NSObject, GADCustomEventBanner

@property (readonly) NSString *TAG = @"XADCustomEventBannerForAdmob"

@property delegate: GADCustomEventBannerDelegate?
@property xadBannerView: XADBannerView!
@property (weak) rootViewController: UIViewController?

@end
