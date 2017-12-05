//
//  AdmobViewController.swift
//  CustomEventDemo
//
//  Created by Ray Wu on 1/18/17.
//  Copyright © 2017 Xad. All rights reserved.
//

import UIKit
import GoogleMobileAds

class AdmobViewController: UIViewController, GADBannerViewDelegate {
    
    @IBOutlet weak var adMobBanner: GADBannerView!
    
    var adMobInterstitial: GADInterstitial!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.adMobBanner.delegate = self
        self.adMobBanner.backgroundColor = UIColor.red
        self.adMobBanner.adUnitID = "ca-app-pub-5709149378349090/2858123563"
        self.adMobBanner.rootViewController = self
    }

    @IBAction func loadAd(_ sender: UIButton) {
        print("Load Ad AdMob")
        let adRequest = GADRequest()
        self.adMobBanner.load(adRequest)
    }
    
    @IBAction func loadAdInterstitial(_ sender: UIButton) {
        print("Load Ad AdMob Interstitial")
        self.adMobInterstitial = GADInterstitial(adUnitID: "ca-app-pub-5709149378349090/7618433563")
        let adRequest = GADRequest()
        self.adMobInterstitial.load(adRequest)
        
    }
    
    @IBAction func displayAdInterstitial(_ sender: UIButton) {
        var count = 0
        while true {
            if self.adMobInterstitial == nil {
                print("No interstitial initialized")
                break
            }
            if self.adMobInterstitial.isReady {
                print("Interstitial ready")
                self.adMobInterstitial.present(fromRootViewController: self)
                break
            }
            
            print("Interstitial not ready")
            sleep(1)
            count += 1
            
            if count >= 10 {
                break
            }
        }
    }
}

extension AdmobViewController: GADInterstitialDelegate {
    func interstitialDidDismissScreen(_ ad: GADInterstitial) {
        self.adMobInterstitial = nil
    }
}
