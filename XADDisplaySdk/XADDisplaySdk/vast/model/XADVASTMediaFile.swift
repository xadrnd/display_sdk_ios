//
//  XADVASTMediaFile.swift
//  VAST
//
//  Created by Ray Wu on 11/15/16.
//  Copyright (c) 2013 xAd, Inc. All rights reserved.
//
//  VASTMediaFile is a data structure that contains parameters for the VAST video itself.
//  The parameters are available from VASTModel, derived from the VAST XML document using the VAS2Parser.  There may be multiple mediaFiles in each VAST document.
import UIKit
import Foundation
class XADVASTMediaFile: NSObject {
    let id_:String
    // add trailing underscore to id_ to avoid conflict with reserved keyword "id".
    let delivery:String
    let type:String
    let bitrate:Int
    let width:Int
    let height:Int
    let scalable:Bool
    let maintainAspectRatio:Bool
    let apiFramework:String? //only available for VPAID
    let url: URL

    init(id id_: String?, delivery: String, type: String, bitrate: String?, width: String, height: String, scalable: String?, maintainAspectRatio: String?, apiFramework: String?, url: String) {
        self.id_ = id_ ?? ""
        self.delivery = delivery
        self.type = type
        if let bitrate = bitrate,
            !bitrate.isEmpty {
            self.bitrate = Int(bitrate)!
        } else {
            self.bitrate = 0
        }
        self.width = width.isEmpty ? Int(width)! : 0
        self.height = height.isEmpty ? Int(height)! : 0
        
        if let scalable = scalable {
            self.scalable = Bool(scalable) ?? true
        } else{
            self.scalable =  true
        }
        
        if let maintainAspectRatio = maintainAspectRatio {
            self.maintainAspectRatio = Bool(maintainAspectRatio) ?? false
        } else {
            self.maintainAspectRatio = false
        }
        
        self.apiFramework = apiFramework
        
        self.url = URL(string: url)!
        
        super.init()
    
    }
}
