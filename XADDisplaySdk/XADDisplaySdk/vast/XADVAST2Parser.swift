//
//  XADVAST2Parser.swift
//  XADVAST
//
//  Created by Phillip Corrigan on 8/5/16.
//  Copyright © 2016 xAd, Inc. All rights reserved.
//

import UIKit
import Foundation
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}

class XADVAST2Parser: NSObject {
    func parseWithUrl(_ url: URL, completion block: @escaping (XADVASTModel?, XADVASTError) -> Void) {
        DispatchQueue.global().async{
            do {
                let vastData = try Data(contentsOf: url, options: .uncached)
                let vastError = self.parseRecursivelyWithData(vastData, depth: 0)
                DispatchQueue.main.async{
                    block(self.vastModel, vastError)
                }
            } catch {
                XADLogger.error(message: "Error when init Data")
            }
        }
    }
    
    func parseWithData(_ vastData: Data, completion block: @escaping (XADVASTModel?, XADVASTError) -> Void) {
        DispatchQueue.global().async {
            let vastError = self.parseRecursivelyWithData(vastData, depth: 0)
            DispatchQueue.main.async {
                block(self.vastModel, vastError)
            }
        }
    }
    
    
    override init() {
        vastModel = XADVASTModel()
        super.init()
    }
    
    
    // MARK: - "private" method
    fileprivate func parseRecursivelyWithData(_ vastData: Data, depth: Int) -> XADVASTError {
        if depth >= XADVASTSettings.kMaxRecursiveDepth {
            vastModel = nil
            return .tooManyWrappers
        }
        // sanity check
        let content = String(data: vastData, encoding: String.Encoding.utf8)
        XADLogger.debug(message: "VAST file\n\(String(describing: content))")
        // Validate the basic XML syntax of the VAST document.
        var isValid: Bool
        isValid = XADVASTXMLUtil.validateXMLDocSyntax(vastData)
        if !isValid {
            vastModel = nil
            return .xmlParse
        }
        
        //Currently don't use vast schema to validate
        if XADVASTSettings.kValidateWithSchema {
            XADLogger.debug(message: "Validating against schema")
            if let vastSchemaData = self.dataFromContenOfFile("vast_schema", withType: "xsd") {
                isValid = XADVASTXMLUtil.validateXMLDocAgainstSchema(vastData, schema: vastSchemaData as Data!)
                if !isValid {
                    vastModel = nil
                    return .schemaValidation
                }
            }
        }
        
        guard let vastModel = self.vastModel else {
            return .xmlParse //No way to come here, just in case
        }
        vastModel.addVASTDocument(vastDocument: vastData)
        // Check to see whether this is a wrapper ad. If so, process it.
        let query = "//VASTAdTagURI"
        guard let results = XADVASTXMLUtil.performXMLXPathQuery(vastData, query: query) as? [[AnyHashable: Any]] else {
            return .xmlParse
        }
        
        if results.count > 0 {
            let node = results[0]
            var urlString: String?
            if let stringContent = node["nodeContent" as NSObject] as? String,
                !stringContent.isEmpty {
                // this is for string data
                urlString = stringContent
            } else {
                // this is for CDATA
                if let childArray = node["nodeChildArray" as NSObject] as? [[AnyHashable: Any]] {
                    if childArray.count > 0 {
                        // we assume that there's only one element in the array
                        urlString = (childArray[0])["nodeContent" as NSObject] as? String
                    }
                }
            }
            
            guard urlString != nil,
                let contentURL = URL(string: urlString!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)) else {
                return .xmlParse
            }
            
            do  {
                let newVastData = try Data(contentsOf: contentURL)
                return self.parseRecursivelyWithData(newVastData, depth: (depth + 1))
            } catch {
                XADLogger.debug(message: "Error happens when parsing")
                return .xmlParse
            }
        }
        return .noneError
    }
    
    fileprivate func content(_ node: [AnyHashable: Any]) -> String? {
        // this is for string data
        if let nodeContents = node["nodeContent" as NSObject] {
            if (nodeContents as AnyObject).length > 0 {
                return nodeContents as? String
            }
        }
        
        // this is for CDATA
        if let childArray = node["nodeChildArray" as NSObject] as? [[AnyHashable: Any]] {
            if childArray.count > 0 {
                return childArray[0]["nodeContent" as NSObject] as? String
            }
        }
        return nil
    }
    
    fileprivate func dataFromContenOfFile(_ fileName:String, withType type:String) -> Data? {
        guard let frameworkBundle = Bundle(identifier: "com.xad.XADDisplaySdk") else {
            XADLogger.error(message: "Can't find desired bundle. please make sure the bundle name is correct")
            return nil
        }
        
        let data:Data?
        if let filepath = frameworkBundle.path(forResource: fileName, ofType: type),
            let contentUrl = URL(string:"file://\(filepath)") {
            do {
                data = try Data(contentsOf: contentUrl, options: .mappedIfSafe)
                return data
            } catch {
                XADLogger.error(message: "failed to load file: " + fileName + " , error message: \(error))")
            }
        } else {
            XADLogger.error(message: "\(fileName) can't found")
        }
        return nil
    }
    var vastModel: XADVASTModel?
}
