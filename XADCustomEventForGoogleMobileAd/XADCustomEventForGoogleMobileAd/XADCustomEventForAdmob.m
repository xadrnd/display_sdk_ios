//
//  XADCustomEventForAdmob.m
//  XADCustomEventForGoogleMobileAd
//
//  Created by Jacob Zelek on 12/13/17.
//  Copyright © 2017 Xad. All rights reserved.
//

#import "XADCustomEventForAdmob.h"

@implementation XADCustomEventForAdmob

- (void)requestBannerAd:(GADAdSize)adSize
parameter:(NSString *)serverParameter
label:(NSString *)serverLabel
request:(GADCustomEventRequest *)request {
    
    XADBannerView bannerSize;
    
    [[SampleBanner alloc] initWithFrame:CGRectMake(0,
                                                   0,
                                                   adSize.size.width,
                                                   adSize.size.height)];
    
    xadBannerView.delegate = self;
    self.bannerAd.adUnit = serverParameter;
    SampleAdRequest *adRequest = [[SampleAdRequest alloc] init];
    adRequest.testMode = request.isTesting;
    adRequest.keywords = request.userKeywords;
    [self.bannerAd fetchAd:adRequest];
}

@end
