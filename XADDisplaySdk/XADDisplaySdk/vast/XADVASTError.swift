//
//  XADVASTError.swift
//  XADVAST
//
//  Created by Phillip Corrigan on 8/5/16.
//  Copyright © 2016 xAd, Inc. All rights reserved.
//

import Foundation


enum XADVASTError: String {
    case noneError = "noneError"
    case xmlParse = "xmlParse"
    case schemaValidation = "schemaValidation"
    case tooManyWrappers = "tooManyWrappers"
    case noCompatibleMediaFile = "noCompatibleMediaFile"
    case noInternetConnection = "noInternetConnection"
    case loadTimeout = "loadTimeout"
    case playerNotReady = "playerNotReady"
    case playbackError = "playbackError"
    case movieTooShort = "movieTooShort"
    case playerHung = "playerHung"
    case playbackAlreadyInProgress = "playbackAlreadyInProgress"
}
