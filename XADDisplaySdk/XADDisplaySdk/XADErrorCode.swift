//
//  XADErrorCode.swift
//  XADDisplaySdk
//
//  Created by Ray Wu on 9/6/16.
//  Copyright © 2016 Xad. All rights reserved.
//

import UIKit

@objc public enum XADErrorCode:Int {
    case unknown
    case badRequest
    case networkError
    case noInventory
    
    public func toError() -> Error{
        switch self {
        case .unknown:
            return NSError(domain: "unknown", code: 0, userInfo: nil)
        case .badRequest:
            return NSError(domain: "bad request", code: 1, userInfo: nil)
        case .networkError:
            return NSError(domain: "network error", code: 2, userInfo: nil)
        case .noInventory:
            return NSError(domain: "no inventory", code: 3, userInfo: nil)
        }
    }
}
