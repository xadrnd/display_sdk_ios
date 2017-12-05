//
//  SecondViewController.swift
//  CustomEventDemo
//
//  Created by Ray Wu on 1/18/17.
//  Copyright © 2017 Xad. All rights reserved.
//

import UIKit
import XADCustomEventForMopub
import XADDisplaySdk

class MopubViewController: UIViewController{
    
    var mopubBanner:MPAdView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        XADLogger.logLevel = .verbose
        
        self.mopubBanner = MPAdView(adUnitId: "76892d58fb7f429294b7597dd94aa4ec", size: MOPUB_BANNER_SIZE)
        self.mopubBanner.frame = CGRect(x: 0, y: 30, width: MOPUB_BANNER_SIZE.width, height: MOPUB_BANNER_SIZE.height)
//        self.mopubBanner = MPAdView(adUnitId: "634ef12ee1fc4c1fa3717ff088cbf3e1", size: MOPUB_MEDIUM_RECT_SIZE)
//        self.mopubBanner.frame = CGRect(x: 0, y: 30, width: MOPUB_MEDIUM_RECT_SIZE.width, height: MOPUB_MEDIUM_RECT_SIZE.height)
        self.mopubBanner.backgroundColor = UIColor.blue
        self.mopubBanner.delegate = self
        self.view.addSubview(self.mopubBanner)
    }
    @IBAction func loadAd(_ sender: UIButton) {
        print("Load Ad MoPub")
        self.mopubBanner.loadAd()
    }
}

extension MopubViewController: MPAdViewDelegate {
    public func viewControllerForPresentingModalView() -> UIViewController! {
        return self
    }
    
    public func adViewDidLoadAd(_ view: MPAdView!) {
        print("Loaded ad from \(view.subviews)")
    }
}

