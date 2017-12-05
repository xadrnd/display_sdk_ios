//
//  XADLogger.swift
//  XADMRAID
//
//  Created by Phillip Corrigan on 7/6/16.
//  Copyright © 2016 xAd, Inc. All rights reserved.
//

import Foundation

@objc public enum LogLevel: Int {
    case none
    case error
    case warning
    case info
    case debug
    case verbose
    
    func toTag() -> String {
        switch self {
        case .verbose:
            return "(V)"
        case .debug:
            return "(D)"
        case .info:
            return "(I)"
        case .warning:
            return "(W)"
        case .error:
            return "(E)"
        case .none:
            return "(N)"
        }
    }
    
    public func toString() -> String {
        switch self {
        case .none: return "none"
        case .error: return "error"
        case .warning: return "warning"
        case .info: return "info"
        case .debug: return "debug"
        case .verbose: return "verbose"
        }
    }
}

open class XADLogger: NSObject {
    open static var logLevel = LogLevel.warning
    open static var postLogEnabled = false
    open static let EVENT_LOG = "com.xad.EVENT_LOG"
    
    open class func error(_ tag: String, message: String) {
        DispatchQueue.main.async {
            if XADLogger.logLevel.rawValue >= LogLevel.error.rawValue {
                print(tag: tag, level: .error, message: message)
            }
        }
    }
    
    open class func error(withInFile file: String=#file, atLineNumber line:Int=#line, message: String) {
        DispatchQueue.main.async {
            if XADLogger.logLevel.rawValue >= LogLevel.error.rawValue {
                print(withFile: file, atLine: line, level: .error, message: message)
            }
        }
    }
    
    open class func warning(_ tag: String, message: String) {
        DispatchQueue.main.async {
            if XADLogger.logLevel.rawValue >= LogLevel.warning.rawValue {
                print(tag: tag, level: .warning, message: message)
            }
        }
    }
    
    open class func warning(withInFile file: String=#file, atLineNumber line:Int=#line, message: String) {
        DispatchQueue.main.async {
            if XADLogger.logLevel.rawValue >= LogLevel.warning.rawValue {
                print(withFile: file, atLine: line, level: .warning, message: message)
            }
        }
    }
    
    open class func info(_ tag: String, message: String) {
        DispatchQueue.main.async {
            if XADLogger.logLevel.rawValue >= LogLevel.info.rawValue {
                print(tag: tag, level: .info, message: message)
            }
        }
    }
    
    open class func info(withInFile file: String=#file, atLineNumber line:Int=#line, message: String) {
        DispatchQueue.main.async {
            if XADLogger.logLevel.rawValue >= LogLevel.info.rawValue {
                print(withFile: file, atLine: line, level: .info, message: message)
            }
        }
    }
    
    open class func debug(_ tag: String, message: String) {
        DispatchQueue.main.async {
            if XADLogger.logLevel.rawValue >= LogLevel.debug.rawValue {
                print(tag: tag, level: .debug, message: message)
            }
        }
    }
    
    open class func debug(withInFile file: String=#file, atLineNumber line:Int=#line, message: String) {
        DispatchQueue.main.async {
            if XADLogger.logLevel.rawValue >= LogLevel.debug.rawValue {
                print(withFile: file, atLine: line, level: .debug, message: message)
            }
        }
    }
    
    open class func verbose(_ tag: String, message: String) {
        DispatchQueue.main.async {
            if XADLogger.logLevel.rawValue >= LogLevel.verbose.rawValue {
                print(tag: tag, level: .verbose, message: message)
            }
        }
    }
    
    open class func verbose(withInFile file: String=#file, atLineNumber line:Int=#line, message: String) {
        DispatchQueue.main.async {
            if XADLogger.logLevel.rawValue >= LogLevel.verbose.rawValue {
                print(withFile: file, atLine: line, level: .verbose, message: message)
            }
        }
    }
    
    open class func print(tag: String, level: LogLevel, message: String) {
        let linesOfMessage = message.components(separatedBy: "\n")
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        for lineMsg in linesOfMessage {
            NSLog("%@: %@ %@", tag, level.toTag(), lineMsg)
            if postLogEnabled {
                let logStrForPost = "\(formatter.string(from: Date())) \(tag): \(level.toTag()) \(lineMsg)"
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: EVENT_LOG) , object: self, userInfo: ["log": logStrForPost])
                }
            }
        }
    }
    
    open class func print(withFile file: String=#file, atLine line:Int=#line, level: LogLevel, message: String) {
        let paths = file.components(separatedBy: CharacterSet(charactersIn: "/."))
        if paths.count >= 2 {
            let tag = paths[paths.count-2] + "-#" + String(line)
            print(tag: tag, level: level, message: message)
        } else {
            error("Logger", message: "Someting wrong with getting file name")
        }
    }
    
    // Utility to print types
    open class func typeName(_ some: Any) -> String {
        return (some is Any.Type) ? "\(some)" : "\(type(of: (some) as AnyObject))"
    }
}

