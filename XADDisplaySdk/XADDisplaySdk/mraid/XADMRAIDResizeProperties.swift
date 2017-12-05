//
//  XADMRAIDResizeProperties.swift
//  XADMRAID
//
//  Created by Phillip Corrigan on 7/6/16.
//  Copyright © 2016 xAd, Inc. All rights reserved.
//

import Foundation

enum XADMRAIDCustomClosePosition: String {
    case topLeft = "top-left"
    case topCenter = "top-center"
    case topRight = "top-right"
    case center = "center"
    case bottomLeft = "bottom-left"
    case bottomCenter = "bottom-center"
    case bottomRight = "bottom-right"
}


class XADMRAIDResizeProperties {

    var width: Int = 0
    var height: Int = 0
    var offsetX: Int = 0
    var offsetY: Int = 0
    var customClosePosition = XADMRAIDCustomClosePosition.topRight
    var allowOffscreen = true

    class func MRAIDCustomClosePositionFromString(_ string: String?) -> XADMRAIDCustomClosePosition {
        if let string = string,
            let result = XADMRAIDCustomClosePosition(rawValue: string){
            return result
        }
        return .topRight
    }

}
