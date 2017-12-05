//
//  ViewController.swift
//  XADDisplayDemo
//
//  Created by Ray Wu on 8/23/16.
//  Copyright © 2016 Xad. All rights reserved.
//

import UIKit
import WebKit
import XADDisplaySdk

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIPopoverPresentationControllerDelegate {
    @IBOutlet weak var channelIdTextField: UITextField!

    @IBOutlet weak var bannerHolderViewHeight: NSLayoutConstraint!
    @IBOutlet weak var buttonHolderTopSpaceConstraint: NSLayoutConstraint!
    @IBOutlet weak var buttonHolderSubView: UIView!
    @IBOutlet weak var bannerHolderView: UIView!
    @IBOutlet weak var bannerButton: UIButton!
    @IBOutlet weak var showHideButton: UIButton!
    @IBOutlet weak var allNoErrorButton: UIButton!
    
    var bannerView: XADBannerView!
    var interstitial: XADInterstitial!
    var videoAd: XADVideoAd!
    var selectedBannerSize: Int = 0
    let testing = false
    var adRequest: XADRequest!
    let sizeList = UIImageView(image: UIImage(named: "list"))
    
    var showErrors: Bool = true
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        XADLogger.logLevel = .debug
        adRequest = XADRequest()
        adRequest.gender = .male
        adRequest.setBirthday(month: 01, day: 03, year: 1988)
        adRequest.isTesting = self.testing
        self.buttonHolderTopSpaceConstraint.constant = 0
        self.channelIdTextField.delegate = self
        createSizeList()
    }
    
    fileprivate func setChannelId() {
        if let channelId = self.channelIdTextField.text,
            !channelId.isEmpty {
            adRequest.testType = .channel
            adRequest.testChannelId = channelId.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        } else {
            adRequest.testType = .sandbox
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.tableView.reloadData()
    }
    
    

  // MARK: Banner Size DropDown
    struct properties {
        static let bannerSizes = [
            ["title" : "320x50"],
            ["title" : "300x50"],
            ["title" : "300x250"],
            ["title" : "728x90"],
        ]
    }
    
    func createSizeList()
    {
        sizeList.frame = CGRect(x: self.bannerButton.frame.origin.x, y: self.buttonHolderSubView.frame.origin.y+self.bannerButton.frame.origin.y+self.bannerButton.frame.size.height, width: 100, height: 280)
        sizeList.alpha = 0
        sizeList.isHidden = true
        sizeList.isUserInteractionEnabled = true
        
        var offset = 25
        
        for (index, sizes) in properties.bannerSizes.enumerated()
        {
            let button = UIButton()
            button.frame = CGRect(x: 10, y: offset, width: 80, height: 50)
            button.setTitleColor(.blue, for: UIControlState())
            button.setTitle(sizes["title"], for: UIControlState())
            button.tag = index
            button.addTarget(self, action: #selector(self.sizeButtonSelected), for: .touchUpInside)
            sizeList.addSubview(button)
            
            offset += 60
        }
        
        view.addSubview(sizeList)
    }
    
    func sizeButtonSelected(sender:UIButton!) {
        
        let btnselected:UIButton = sender
        if btnselected.tag == 0 {
            
            print("Selected Banner Size is 320x50")
            self.selectedBannerSize = XADBannerSize.banner.rawValue
            
        }else if btnselected.tag == 1
        {
            print("Selected Banner Size is 300x50")
             self.selectedBannerSize = XADBannerSize.narrowBanner.rawValue
            
        }else if btnselected.tag == 2
        {
            print("Selected Banner Size is 300x250")
            self.selectedBannerSize = XADBannerSize.mediumRectangle.rawValue
            
        }else if btnselected.tag == 3
        {
            print("Selected Banner Size is 728x90")
            self.selectedBannerSize = XADBannerSize.leaderBoard.rawValue
        }
        
        closeSizeList()
        requestBannerAd()
        self.channelIdTextField.text = ""
    }
    
    func openSizeList()
    {
        self.sizeList.isHidden = false
        
        UIView.animate(withDuration: 0.3,
                       animations: {
                        self.sizeList.frame = CGRect(x: self.bannerButton.frame.origin.x, y: self.buttonHolderSubView.frame.origin.y+self.bannerButton.frame.origin.y+self.bannerButton.frame.size.height, width: 100, height: 260)
                        self.sizeList.alpha = 1
        })
    }
    
    func closeSizeList()
    {
        UIView.animate(withDuration: 0.3,
                       animations: {
                        self.sizeList.frame = CGRect(x: self.bannerButton.frame.origin.x, y: self.buttonHolderSubView.frame.origin.y+self.bannerButton.frame.origin.y+self.bannerButton.frame.size.height, width: 100, height: 260)
                        self.sizeList.alpha = 0
        },
                       completion: { finished in
                        self.sizeList.isHidden = true
        }
        )
    }

    @IBAction func showHideBannerView(_ sender: Any) {
        self.bannerHolderView.isHidden = !self.bannerHolderView.isHidden
        self.bannerHolderView.subviews.forEach {
            $0.isHidden = !$0.isHidden
        }
        if(self.bannerHolderView.isHidden)
        {
            self.showHideButton.setTitle("Show",for: .normal)
        }else{
             self.showHideButton.setTitle("Hide",for: .normal)
        }
    }
    
    @IBAction func showHideErrors(_ sender: Any) {
        self.showErrors = !self.showErrors
        
        if(self.showErrors)
        {
            self.allNoErrorButton.setTitle("All Errors", for: .normal)
        }else{
            self.allNoErrorButton.setTitle("No Errors", for: .normal)
        }
    }
    
    @IBAction func loadBanner(_ sender: AnyObject) {
       sizeList.isHidden ? openSizeList() : closeSizeList()
        
    }
    
    func requestBannerAd()
    {
        
        ViewController.urlsCalled.removeAll()
        
        if bannerView != nil {
            bannerView.removeFromSuperview()
        }
        
        bannerView = XADBannerView(adSize: XADBannerSize(rawValue: self.selectedBannerSize)!, origin: CGPoint(x: 0, y: 0))
        
        
        bannerView.rootViewController = self
        bannerView.delegate = self
        bannerView.testDelegate = self
        bannerView.accessKey = "upT9vzr2jgqyw_g7pi5tv6HjLcP0-U68DPdTMcMwvw0."
        bannerView.trafficSource = "banner_ad_unit"
        bannerView.autoRefreshIntervalSeconds = 0
        self.setChannelId()
        bannerView.adRequest = adRequest
        bannerView.loadAd()
        self.bannerHolderView.frame = bannerView.frame
        self.bannerHolderView.addSubview(bannerView)
    
    }
    
    override func viewDidLayoutSubviews() {
        if self.bannerView != nil {
           // print( "bannerview height2:::\(bannerView.frame.height)")
             self.bannerView.center = self.bannerHolderView.center
            self.bannerHolderViewHeight.constant = bannerView.frame.size.height+50
           
        
        }
        
    }
    
  // MARK: Interestitial

    @IBAction func loadInterstitial(_ sender: AnyObject) {
        ViewController.urlsCalled.removeAll()
        
        interstitial = XADInterstitial()
        
        interstitial!.rootViewController = self
        interstitial!.accessKey = "upT9vzr2jgqyw_g7pi5tv6HjLcP0-U68DPdTMcMwvw0."
        interstitial!.trafficSource = "interstitial_ad_unit"
        interstitial!.delegate = self
        interstitial!.testDelegate = self
        self.setChannelId()
        interstitial!.adRequest = self.adRequest
        interstitial!.loadAd()
        self.channelIdTextField.text = ""
    }

    @IBAction func loadVideo(_ sender: AnyObject) {
        ViewController.urlsCalled.removeAll()
        
        videoAd = XADVideoAd(vmin: 11, vmax: 60)
        
        videoAd!.rootViewController = self
        videoAd!.accessKey = "upT9vzr2jgqyw_g7pi5tv6HjLcP0-U68DPdTMcMwvw0."
        videoAd!.trafficSource = "video_ad_unit"
        videoAd!.delegate = self
        videoAd!.testDelegate = self
        self.setChannelId()
        videoAd!.adRequest = self.adRequest
        videoAd!.loadAd()
        self.channelIdTextField.text = ""
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    static var urlsCalled: [String] = []
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ViewController.urlsCalled.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LogCell", for: indexPath)
        
        if ViewController.urlsCalled.count > 0 {
            cell.textLabel?.text = ViewController.urlsCalled[indexPath.row]
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let row = indexPath.row
        
        let alertController = UIAlertController(title: "Logger", message:
            ViewController.urlsCalled[row], preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default,handler: nil))
        
        self.present(alertController, animated: true, completion: nil)
    }
}

extension ViewController: XADDisplayTestDelegate {
    public func intercept(urlResponse: URLResponse) -> Bool {
        if let urlString = urlResponse.url?.absoluteString,
            let statusCode = (urlResponse as? HTTPURLResponse)?.statusCode{
            if let corLogIndex = ViewController.urlsCalled.index(of: urlString) {
                ViewController.urlsCalled[corLogIndex] = "Response: \(statusCode) -- \(urlString)"
            }
        }
        self.tableView.reloadData()
        return false
    }

    public func intercept(url: URL) -> Bool {
        print(url.absoluteString)
        ViewController.urlsCalled.append(url.absoluteString)
        self.tableView.reloadData()
        return false
    }
}

extension ViewController: XADBannerDelegate {
    func bannerViewWillLeaveApplication(withAd ad:XADBannerView) {
        XADLogger.debug(message: "Test leave application delegate")
    }
    
    func bannerViewDidFailToReceive(withAd ad: XADBannerView, withError errorCode: XADErrorCode) {
        XADLogger.error(message: "Failed to get banner view: \(errorCode.toError())")
    }
    
    func bannerViewDidReceived(withAd ad: XADBannerView) {
        XADLogger.debug(message: "Banner has been loaded")
    }
}

extension ViewController: XADInterstitialDelegate {
    func interstitialDidReceiveAd(_ interstitial: XADInterstitial) {
        XADLogger.debug(message: "INTERSITIAL DELEGATE CALLED")
        self.interstitial.showInterstitial()
    }
}

extension ViewController: XADVideoAdDelegate {
    public func videoAdDidReceived(_ videoAd: XADVideoAd) {
        self.videoAd.playVideo()
    }
    
    public func videoAdFailedToReceive(withErrorCode errocCode: XADErrorCode) {
        if self.showErrors {
            let alertController = UIAlertController(title: "Video Error", message: "Can't open video ad due to error: \(errocCode.toError())", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default,handler: nil))
        
            self.present(alertController, animated: true, completion: nil)
        }
    }
}



