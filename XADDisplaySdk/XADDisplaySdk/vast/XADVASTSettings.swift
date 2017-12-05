//
//  XADVASTSettings.swift
//  XADVAST
//
//  Created by Phillip Corrigan on 8/5/16.
//  Copyright © 2016 xAd, Inc. All rights reserved.
//

import Foundation


struct XADVASTSettings {
    static let kMaxRecursiveDepth = 5
    static let kPlayTimeCounterInterval: TimeInterval = 0.25
    static let kVideoLoadTimeoutInterval: TimeInterval = 10.0
    static let kFirstShowControlsDelay: TimeInterval = 4.0
    static let kValidateWithSchema = false

    static var vastVideoLoadTimeout: TimeInterval = kVideoLoadTimeoutInterval

    static func setVastVideoLoadTimeout(_ newValue: TimeInterval) {
        if newValue != XADVASTSettings.vastVideoLoadTimeout {
            XADVASTSettings.vastVideoLoadTimeout = newValue >= XADVASTSettings.kVideoLoadTimeoutInterval ? newValue :XADVASTSettings.kVideoLoadTimeoutInterval  // force minimum to default value
        }
    }
}

