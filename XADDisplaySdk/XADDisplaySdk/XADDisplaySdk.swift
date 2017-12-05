//
//  XADDisplaySdk.swift
//  XADDisplaySdk
//
//  Created by Ray Wu on 8/23/16.
//  Copyright © 2016 Xad. All rights reserved.

import UIKit
import CoreLocation

class XADDisplaySdk{
    
    func fetchAdCreative(_ accessKey: String, trafficSource: String, adRequest: XADRequest, adSize: XADBannerSize?, adType: AdType, creativeStringHandler: @escaping (String, String) -> Void?, httpErrorHandler: @escaping (Int) -> Void?) {
        let adRequestURL:URL?
        let keyForAdGroupId:String!
        
        if adRequest.isTesting {
            keyForAdGroupId = "X-CHANNEL-ID"
            let urlGenerator = XADAdRequestTestURLGenerator(endPoint: Constants.kXadTestServerEndpoint)
            urlGenerator.appendPath(adRequest.testType.rawValue, id: adRequest.testChannelId)
            if adRequest.testType != .channel {
                urlGenerator.setFormat(adType, withSize: adSize)
            }
            urlGenerator.setAccessKey(accessKey)
            adRequestURL = urlGenerator.generateURL()
        } else {
            keyForAdGroupId = "X-XAD-AD-REF"
            let urlGenerator = XADAdRequestURLGenerator(endPoint: Constants.kXadServerEndpoint)
            urlGenerator.setFormat(adType)
            urlGenerator.setAdSize(adSize)
            urlGenerator.setAccessKey(accessKey)
            urlGenerator.setTrafficSource(trafficSource)
            urlGenerator.setLocation(self.locationManager?.getCurrentLocation())
            urlGenerator.setAdRequest(adRequest)
            adRequestURL = urlGenerator.generateURL()
        }
        
        if let url = adRequestURL {
            XADLogger.debug(message: "Ad Request URL: \(url.absoluteString)")
            
            let creativeFetchedHandler = { (body:String, header: [String: String]?) in
                if let adGroupIdInfo = header?[keyForAdGroupId] {
                    XADLogger.debug(message: "AdGroupId: \(adGroupIdInfo)")
                    creativeStringHandler(body, adGroupIdInfo)
                } else {
                    XADLogger.debug(message: "No adGroupId found in header")
                }
            }
            
            self.networkManager?.doFetchWithURLSession(url, completionHandler: creativeFetchedHandler, httpErrorHandler: httpErrorHandler)
            return
        }
    }

    @available(*, deprecated)
    func fetchAdCreative(_ accessKey: String, adRequest: XADRequest, adSize: XADBannerSize?, adType: AdType, creativeStringHandler: @escaping (String, String) -> Void?, httpErrorHandler: @escaping (Int) -> Void?) {
        fetchAdCreative(accessKey, trafficSource: "", adRequest: adRequest, adSize: adSize, adType: adType, creativeStringHandler: creativeStringHandler, httpErrorHandler: httpErrorHandler)
    }
    
    func fetchAdCreative(docData: URL, creativeStringHandler: @escaping (String, String) -> Void?, httpErrorHandler: @escaping (Int) -> Void?) {
        XADLogger.debug(message: "docData URL: \(docData.absoluteString)")
        let creativeFetchedHandler = { (body:String, header: [String: String]?) in
            //-1 adgroup means creative from docdata
            creativeStringHandler(body, "-1")
        }
        
        self.networkManager?.doFetchWithURLSession(docData, completionHandler: creativeFetchedHandler, httpErrorHandler: httpErrorHandler)
        return
    }
    
    
    static let shared = XADDisplaySdk()

    let locationManager:LocationManager?
    let networkManager:NetworkManager?
    
    //private
    //Designated initializer
    fileprivate init(){
        self.locationManager = XADLocationManager()
        self.networkManager = XADNetworkManager()
        //Get user agent in UI thread for later usage
        XADUtils.userAgent()
    }
}
