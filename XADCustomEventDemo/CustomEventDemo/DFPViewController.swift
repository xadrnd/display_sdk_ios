//
//  CustomEventDemo
//  Created by Ray Wu on 1/18/17.
//  Copyright © 2017 Xad. All rights reserved.
//

import XADDisplaySdk
import GoogleMobileAds
import XADCustomEventForGoogleMobileAd

class DFPViewController: UIViewController, GADBannerViewDelegate {

    @IBOutlet weak var adView: DFPBannerView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        adView.adUnitID = "/155496285/iOS_300x250_One_Creatives"
        adView.rootViewController = self
        adView.delegate = self
        adView.backgroundColor = UIColor.red
    }
    
    @IBAction func loadAd(_ sender: Any) {
        print("Load Ad DFP")
        let xadRequest = XADRequest()
        xadRequest.setBirthday(month: 01, day: 15, year: 1988)
        let request = DFPRequest()
        request.birthday = xadRequest.birthday
        request.gender = .male
        adView.load(request)
    }
}

