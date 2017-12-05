//
//  XADURLGenerator.swift
//  XADDisplaySdk
//
//  Created by Ray Wu on 1/3/17.
//  Copyright © 2017 Xad. All rights reserved.
//

import Foundation
import CoreLocation
import CoreTelephony
import AdSupport

fileprivate let kXadMilesPerHourPerMeterPerSecond = 2.23694


class XADURLGenerator {
    var components: URLComponents?
    var queryItems: [URLQueryItem]
    
    init(endPoint url: String) {
        self.components = URLComponents(string: url)
        self.queryItems = [URLQueryItem]()
    }
    
    func addParam(_ key: String, value: String) {
        self.queryItems.append(URLQueryItem(name: key, value: value))
    }
    
    func removeParam(key: String) {
        self.queryItems = self.queryItems.filter({$0.name != key})
    }
    
    func generateURL() -> URL? {
        components?.queryItems = self.queryItems
        return components?.url
    }
}

class XADAdRequestTestURLGenerator: XADURLGenerator {
    
    override init(endPoint url: String) {
        super.init(endPoint: url)
        self.addParam("no_redirect", value: "1")
    }
    
    func setFormat(_ adType:AdType, withSize adSize: XADBannerSize?) {
        self.addParam("type", value: adType.rawValue)
        if let adSize = adSize {
            self.addParam("size", value: adSize.sizeDescription())
        }
    }
    
    func setAccessKey(_ accessKey: String) {
        self.addParam("access_key", value: accessKey)
    }
    
    func appendPath(_ path: String, id: String? = nil) {
        if self.components != nil {
            self.components!.path = self.components!.path.appending("/\(path)")
            
            if let id = id,
                path == TestType.channel.rawValue {
                self.components!.path = self.components!.path.appending("/\(id)")
            }
        }
    }
}


class XADAdRequestURLGenerator: XADURLGenerator {
    
    override init(endPoint url: String) {
        super.init(endPoint: url)
        self.addBaseData()
    }
    
    func setAdRequest(_ adRequest:XADRequest) {
        //Only apply to adRequest for video
        
        if let vmin = adRequest.vmin,
            let vmax = adRequest.vmax {
            self.addParam("vmin", value: String(vmin))
            self.addParam("vmax", value: String(vmax))
        }
        
        
        if let birthday = adRequest.birthday {
            let now = Date()
            let ageComponents = Calendar(identifier: .gregorian).dateComponents([.year], from: birthday, to: now)
            if let age = ageComponents.year {
                self.addParam("age", value: "\(age)")
            }
        }
        
        self.addParam("gender", value: adRequest.gender.description())
        
        if let zipcode = adRequest.zipCode {
            self.addParam("zip", value: zipcode)
        }
        
        if let city = adRequest.city {
            self.addParam("city", value: city)
        }
        
        if let state = adRequest.state {
            self.addParam("region", value: state)
        }
        
        if let extras = adRequest.extras {
            for (key, anyValue) in extras {
                if anyValue is String {
                    self.addParam(key, value: anyValue as! String)
                }
                if anyValue is [String] {
                    for value in anyValue as! [String] {
                        self.addParam(key, value: value)
                    }
                }
            }
        }
    }
    
    func setFormat(_ adType:AdType) {
        
        switch adType {
        case .banner:
            self.addParam("o_fmt", value: "html5,exp")
            self.addParam("api", value: "3")
            self.addParam("api", value: "5")
            self.addParam("instl", value: "0")
        case .interstitial:
            self.addParam("o_fmt", value: "html5,exp")
            self.addParam("api", value: "3")
            self.addParam("api", value: "5")
            self.addParam("instl", value: "1")
        case .video:
            self.addParam("o_fmt", value: "video")
            self.addParam("vmime", value: "video/mp4")
            self.addParam("vmime", value: "video/3gpp")
            self.addParam("vmime", value: "video/quicktime")
            self.addParam("vmime", value: "video/webm")
            self.addParam("vlinearity", value: "1")
            self.addParam("vprotocol", value: "1")
            self.addParam("vprotocol", value: "2")
            self.addParam("vprotocol", value: "4")
            self.addParam("vprotocol", value: "5")
        }
    }
    
    func setAdSize(_ adSize:XADBannerSize?) {
        if let sizeDescription = adSize?.sizeDescription() {
            self.addParam("size", value: sizeDescription)
        }
    }
    
    func setAccessKey(_ accessKey: String) {
        self.addParam("k", value: accessKey)
    }
    
    func setTrafficSource(_ trafficSource: String) {
        self.addParam("traffic_src", value: trafficSource)
    }
    
    func setLocation(_ location:CLLocation?) {
        guard let location = location else {
            return
        }
        //Param jssdk is not necessary any more since locatio is provided
        self.removeParam(key: "sdk_conf")

        self.addParam("lat", value: "\(location.coordinate.latitude)")
        self.addParam("long", value: "\(location.coordinate.longitude)")
        self.addParam("ha", value: "\(location.horizontalAccuracy)")
        self.addParam("va", value: "\(location.verticalAccuracy)")
        self.addParam("alt", value: "\(location.altitude)")
        if location.floor != nil {
            self.addParam("floor", value: "\(location.floor!)")
        }
        self.addParam("timestamp", value: "\(location.timestamp.timeIntervalSince1970)")
        self.addParam("course", value: "\(location.course)")

    }
    
    fileprivate func addBaseData(){
        self.addParam("sdk", value: "xad_display_sdk_ios")
        if let sdkVersion = XADUtils.sdkVersion() {
            self.addParam("sdkv", value: sdkVersion)
        }
        self.addParam("pt", value: "app")
        self.addParam("os", value: "iOS")
        self.addParam("v", value: "1.2")
        self.addParam("sdk_conf", value: "jssdk")
        self.addParam("secure", value: "1")
        
        if XADUtils.isSimulator() {
            self.addParam("dnt", value: "1")
            self.addParam("uid", value: "SIMULATOR")
            self.addParam("uid_type", value: "UUID|RAW")
        }
        else {
            
            if XADUtils.doNotTrack() {
                self.addParam("dnt", value: "1")
                self.addParam("uid_type", value: "VENDOR|RAW")
                self.addParam("uid", value: UIDevice.current.identifierForVendor!.uuidString)
                
            } else {
                self.addParam("dnt", value: "0")
                self.addParam("uid_type", value: "IDFA|RAW")
                self.addParam("uid", value: ASIdentifierManager.shared().advertisingIdentifier!.uuidString)
            }
        }
        
        if let value = XADUtils.appname() {
            self.addParam("appname", value: value)
        }
        
        if let value = XADUtils.appver() {
            self.addParam("appver", value: value)
        }
        
        if let value = XADUtils.bundleName() {
            self.addParam("bundle", value: value)
        }
        
        if let value = XADUtils.carrierName() {
            self.addParam("carrier", value: value)
        }

        if Locale.preferredLanguages.count > 0 {
            for language in Locale.preferredLanguages {
                self.addParam("lang", value: language)
            }
        }

        if XADUtils.kUserAgent.isEmpty {
            XADUtils.userAgent()
        } else {
            self.addParam("devid", value: XADUtils.kUserAgent)
        }
        
        if let value = XADUtils.deviceType() {
            self.addParam("dev_type", value: value)
        }
    }

}
