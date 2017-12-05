//
//  XADMRAIDOrientationProperties.swift
//  XADMRAID
//
//  Created by Phillip Corrigan on 7/6/16.
//  Copyright © 2016 xAd, Inc. All rights reserved.
//

import Foundation

enum XADMRAIDForceOrientation: String {
    case portrait = "portrait"
    case landscape = "landscape"
    case none = "none"
}

struct XADMRAIDOrientationProperties {

    let allowOrientationChange: Bool
    let forceOrientation: XADMRAIDForceOrientation
    
    init(allowOrientationChange: Bool = true, forceOrientation: XADMRAIDForceOrientation = .none) {
        self.allowOrientationChange = allowOrientationChange;
        self.forceOrientation = forceOrientation
    }
    
    init(allowOrientationChange: String, forceOrientation: String) {
        self.allowOrientationChange = Bool(allowOrientationChange) ?? true ;
        self.forceOrientation = XADMRAIDOrientationProperties.MRAIDForceOrientationFromString(forceOrientation)
    }

    static func MRAIDForceOrientationFromString(_ string: String) -> XADMRAIDForceOrientation {
        if let result = XADMRAIDForceOrientation(rawValue: string) {
            return result
        }
        return .none
    }

}
