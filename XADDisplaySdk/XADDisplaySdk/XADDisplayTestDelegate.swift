//
//  XADDisplayTestDelegate.swift
//  XADDisplaySdk
//
//  Created by Ray Wu on 3/27/17.
//  Copyright © 2017 Xad. All rights reserved.
//

public protocol XADDisplayTestDelegate: class {
    // Return true to intercept the url and stop further action
    func intercept(url: URL) -> Bool
    func intercept(urlResponse: URLResponse) -> Bool
}
