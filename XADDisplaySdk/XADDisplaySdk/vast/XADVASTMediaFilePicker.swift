//
//  XADVASTMediaFilePicker.swift
//  XADVAST
//
//  Created by Phillip Corrigan on 8/5/16.
//  Copyright © 2016 xAd, Inc. All rights reserved.
//

import Foundation
import UIKit
// An implementation of how to pick media file from one or more in a VAST Document. VASTMediaFilePicker looks for internet first and eliminate entries with mime type which we can't play in the phone. After that, the list is sorted by bit rate (if exists) along with hi or low speed connection + progressive/streaming attribute. Once we have the final list, we end up picking the first from the list. If you have no valid media file to pick, you will get a nil and that will generate an error to the caller.

// This enum will be of more use if we ever decide to include the media files'
// delivery type and/or bitrate into the picking algorithm.
enum NetworkType: Int {
    case cellular
    case none
    case wiFi
}

class XADVASTMediaFilePicker: NSObject {
    class func pick(_ mediaFiles: [XADVASTMediaFile]?) -> XADVASTMediaFile? {
        // Check whether we even have a network connection.
        // If not, return a nil.
        let networkType = self.networkType()
        XADLogger.debug("VAST - Mediafile Picker", message: "NetworkType: \(networkType)")
        if networkType == NetworkType.none {
            return nil
        }
        // Go through the provided media files and only those that have a compatible MIME type.
        var compatibleMediaFiles:[XADVASTMediaFile]?
        guard let mediaFiles = mediaFiles else {
            XADLogger.debug("VAST - Mediafile Picker", message: "Empty or nil array of media files has been put")
            return nil
        }
        for vastMediaFile in mediaFiles {
            // Make sure that you have type specified for mediafile and ignore accordingly
            if self.isMIMETypeCompatible(vastMediaFile) {
                if compatibleMediaFiles == nil {
                    compatibleMediaFiles = [XADVASTMediaFile]()
                }
                compatibleMediaFiles!.append(vastMediaFile)
            }
        }
        
        guard compatibleMediaFiles != nil && compatibleMediaFiles!.count > 0 else {
            XADLogger.debug("VAST - Mediafile Picker", message: "No compatible media file found")
            return nil
        }
        
        // Sort the media files based on their video size (in square pixels).
        var sortedMediaFiles = (compatibleMediaFiles! as NSArray).sortedArray(comparator: {(a: Any, b: Any) -> ComparisonResult in
            let mf1 = (a as! XADVASTMediaFile)
            let mf2 = (b as! XADVASTMediaFile)
            let area1 = mf1.width * mf1.height
            let area2 = mf2.width * mf2.height
            if area1 < area2 {
                return .orderedAscending
            }
            else if area1 > area2 {
                return .orderedDescending
            }
            else {
                return .orderedSame
            }
            
        })
        // Pick the media file with the video size closes to the device's screen size.
        let screenSize = UIScreen.main.bounds.size
        let screenArea = screenSize.width * screenSize.height
        var bestMatch = 0
        var bestMatchDiff = Int.max
        let len = Int(sortedMediaFiles.count)
        for i in 0..<len {
            let videoArea = (sortedMediaFiles[i] as! XADVASTMediaFile).width * (sortedMediaFiles[i] as! XADVASTMediaFile).height
            let diff = abs(Int(screenArea) - videoArea)
            if diff >= bestMatchDiff {
                break
            }
            bestMatch = i
            bestMatchDiff = diff
        }
        let toReturn = (sortedMediaFiles[bestMatch] as! XADVASTMediaFile)
        XADLogger.debug("VAST - Mediafile Picker", message: "Selected Media File: \(toReturn.url)")
        return toReturn
    }
    
    
    class func networkType() -> NetworkType {
        if let reach = Reachability(hostname: "www.google.com") {
            var reachableState = NetworkType.none
            if reach.isReachable {
                if reach.isReachableViaWiFi {
                    reachableState = NetworkType.wiFi
                }
                else if reach.isReachableViaWWAN {
                    reachableState = NetworkType.cellular
                }
            }
            return reachableState
        }
        return .none
    }
    
    class func isMIMETypeCompatible(_ vastMediaFile: XADVASTMediaFile) -> Bool {
        let pattern = "(mp4|m4v|quicktime|3gpp)"
        //TODO: - how to verify file name is match type. use extension?
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let matches = regex.matches(in: vastMediaFile.type, options: [], range: NSMakeRange(0, vastMediaFile.type.characters.count))
            return (matches.count > 0)
        } catch {
            return false
        }
    }
}

