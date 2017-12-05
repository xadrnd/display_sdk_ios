//
//  XADVASTUrlWithId.swift
//  VAST
//
//  Created by Ray Wu on 11/15/16.
//  Copyright (c) 2013 xAd, Inc. All rights reserved.
//
//  VASTUrlWithId is a simple data structure to handle VAST URL elements which may be impresssions or clickthroughs.
//
import UIKit
import Foundation
class XADVASTUrlWithId: NSObject {
    private(set) var id_:String!
    // add trailing underscore to id_ to avoid conflict with reserved keyword "id".
    private(set) var url: URL!

    init(ID id_: String, url: URL) {
        self.id_ = id_
        self.url = url
        super.init()
    }
}
