//
//  XADMRAIDParser.swift
//  XADMRAID
//
//  Created by Phillip Corrigan on 7/6/16.
//  Copyright © 2016 xAd, Inc. All rights reserved.
//

import Foundation

enum MRAIDCommand: String {
    // MRAID v1.0
    case addEventListener = "addEventListener"
    case close = "close"
    case expand = "expand"
    case getExpandProperties = "getExpandProperties"
    case getPlacementType = "getPlacementType"
    case getState = "getState"
    case getVersion = "getVersion"
    case isViewable = "isViewable"
    case open = "open"
    case removeEventListener = "removeEventListener"
    case resize = "resize"
    case setExpandProperties = "setExpandProperties"
    case useCustomClose = "useCustomClose"
    // MRAID v2.0
    case createCalendarEvent = "createCalendarEvent"
    case getCurrentPosition = "getCurrentPosition"
    case getDefaultPosition = "getDefaultPosition"
    case getMaxSize = "getMaxSize"
    case getResizeProperties = "getResizeProperties"
    case getScreenSize = "getScreenSize"
    case playVideo = "playVideo"
    case setResizeProperties = "setResizeProperties"
    case storePicture = "storePicture"
    case supports = "supports"

    case setOrientationProperties = "setOrientationProperties"
}

enum MRAIDError: Error {
    case malformedCommand
    case unsupportedCommand
    case missingParameter
}

struct XADMRAIDCommand {
    var command: MRAIDCommand
    let params: [String: String]?
    
    init(command: String, params: [String: String]) throws {
        
//        let cmd = try validate(command, params: params)
        
        // Validate command
        let supportedCommands: [MRAIDCommand] = [
            .createCalendarEvent,
            .close,
            .expand,
            .open,
            .playVideo,
            .resize,
            .setOrientationProperties,
            .setResizeProperties,
            .storePicture,
            .useCustomClose
        ]
        
        guard let cmd = MRAIDCommand(rawValue: command) else {
            throw MRAIDError.unsupportedCommand
        }
        guard supportedCommands.contains(cmd) else {
            throw MRAIDError.unsupportedCommand
        }
        
        // Validate params
        var paramsIsValid = false
        switch cmd {
        case .createCalendarEvent:
            paramsIsValid = (params["eventJSON"] != nil)
        case .open, .playVideo, .storePicture:
            paramsIsValid = (params["url"] != nil)
        case .setOrientationProperties:
            paramsIsValid = (
                params["allowOrientationChange"] != nil &&
                    params["forceOrientation"] != nil
            )
        case .setResizeProperties:
            paramsIsValid = (
                params["width"] != nil &&
                    params["height"] != nil &&
                    params["offsetX"] != nil &&
                    params["offsetY"] != nil &&
                    params["customClosePosition"] != nil &&
                    params["allowOffscreen"] != nil
            )
        case .useCustomClose:
            paramsIsValid = (params["useCustomClose"] != nil)
        default:
            paramsIsValid = true
        }
        
        guard paramsIsValid == true else {
            throw MRAIDError.missingParameter
        }
        
        self.command = cmd
        self.params = params
    }
}


// A parser class which validates MRAID commands passed from the creative to the native methods.
// This takes a commandUrl of type "mraid://command?param1=val1&param2=val2&..." and return a
// dictionary of key/value pairs which include command name and all the parameters. It checks
// if the command itself is a valid MRAID command and also a simpler parameters validation.
class XADMRAIDParser {

    class func parseCommandUrl(_ commandUrl: String) throws -> XADMRAIDCommand {
    
        /*
         The command is a URL string that looks like this:
         
         mraid://command?param1=val1&param2=val2&...
         
         We need to parse out the command, create a dictionary of the paramters and their associated values,
         and then send an appropriate message back to the MRAIDView to run the command.
         */
        
        XADLogger.debug(message: "\(#function) \(commandUrl)")
        
        guard let s1 = commandUrl.removingPercentEncoding, s1.characters.count > 8 else {
            throw MRAIDError.malformedCommand
        }
        // Remove mraid:// prefix.
        let s2 = (s1 as NSString).substring(from: 8)
        
        var command = ""
        var paramStr = ""
        var params: [String: String] = [:]
        
        // Check for parameters, and parse if found
        if let range = s2.range(of: "?") {
            command = s2.substring(to: range.lowerBound)
            paramStr = s2.substring(from: s2.index(range.lowerBound, offsetBy: 1))
            let paramArray = paramStr.components(separatedBy: "&")
            for param in paramArray {
                if let subRange = param.range(of: "=") {
                    let key = param.substring(to: subRange.lowerBound)
                    let val = param.substring(from: param.index(subRange.lowerBound, offsetBy: 1))
                    params[key] = val
                }
            }
        } else {
            // Command
            command = s2
        }
        
        return try XADMRAIDCommand(command: command, params: params)
    }
}
