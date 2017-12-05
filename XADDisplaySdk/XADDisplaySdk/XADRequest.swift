//
//  XADRequest.swift
//  XADDisplaySdk
//
//  Created by Ray Wu on 8/23/16.
//  Copyright © 2016 Xad. All rights reserved.
//

import UIKit
@objc public enum Gender:Int {
    case unknown
    case male
    case female
    
    func description() -> String {
        switch self {
        case .male:
            return "M"
        case .female:
            return "F"
        default:
            return "U"
        }
    }
}

public enum TestType: String {
    case sandbox = "sandbox" //Internal Test Mode
    case production = "production" // Production Test Mode
    case channel = "channel" //Internal Test Mode
}

//Not expose to outside world.
enum AdType: String {
    case banner = "banner"
    case interstitial = "interstitial"
    case video = "video"
}

open class XADRequest: NSObject {
    open var gender: Gender = .unknown
    open var birthday: Date?
    open var zipCode: String?
    open var city: String?
    open var state: String?
    open var isTesting: Bool = false
    open var extras: [String: Any]?
    
    open var testType: TestType = .production
    open var testChannelId: String?
    
    internal var vmax: Int? //only apply to video request
    internal var vmin: Int? //only apply to video request
    
    required public init(gender: Gender,
                         birthday: Date?,
                         zipCode: String?,
                         city: String?,
                         state: String?,
                         extras: [String: String]?) {
        self.gender = gender
        self.birthday = birthday
        self.zipCode = zipCode
        self.city = city
        self.state = state
        self.extras = extras
    }
    
    public convenience override init() {
        self.init(gender: .unknown, birthday: nil)
    }
    
    public convenience init(gender:Gender, birthday:Date?) {
        self.init(gender: gender,
                  birthday: birthday,
                  zipCode: nil,
                  city: nil,
                  state: nil,
                  extras: nil)
    }
    
    public func setBirthday(month: Int, day: Int, year: Int) {
        let birthday = Calendar.current
        var dateComponents = birthday.dateComponents([.year, .month, .day], from: Date())
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
        self.birthday = birthday.date(from: dateComponents)
    }
}
