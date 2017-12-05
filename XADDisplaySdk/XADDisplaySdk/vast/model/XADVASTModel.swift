//
//  XADVASTModel.swift
//  VAST
//
//  Created by Ray Wu on 11/15/16.
//  Copyright (c) 2013 xAd, Inc. All rights reserved.
//
//  VASTModel provides access to VAST document elements; the VAST2Parser result is stored here.
//
import UIKit
import Foundation

class XADVASTModel: NSObject {
    lazy var vastDocumentArray = [Data]()
    
    // MARK: - "private" method
    // We deliberately do not declare this method in the header file in order to hide it.
    // It should be used only be the VAST2Parser to build the model.
    // It should not be used by anybody else receiving the model object.
    func addVASTDocument(vastDocument: Data) {
        vastDocumentArray.append(vastDocument)
    }
    
    // MARK: - public methods
    // returns the version of the VAST document 
    func vastVersion() -> String? {
        // sanity check
        if vastDocumentArray.count == 0 {
            return nil
        }

        var version:String?
        let query = "/VAST/@version"
        guard let results = XADVASTXMLUtil.performXMLXPathQuery(vastDocumentArray[0], query: query) as? [[NSObject : AnyObject]] else {
            return nil
        }
        
        // there should be only a single result
        if results.count > 0 {
            let attribute = results[0]
            version = attribute["nodeContent" as NSObject] as? String
        }
        return version
    }
    // returns an array of VASTUrlWithId objects (although the id will always be nil)

    func errors() -> [XADVASTUrlWithId]? {
        let query = "//Error"
        return self.resultsForQuery(query: query)
    }
    // returns an array of VASTUrlWithId objects

    func impressions() -> [XADVASTUrlWithId]? {
        let query = "//Impression"
        return self.resultsForQuery(query: query)
    }
    // returns a dictionary whose keys are the names of the event ("start", "midpoint", etc.)
    // and whose values are arrays of NSURL objects

    func trackingEvents() -> [String : [URL]]? {
        var eventDict:[String : [URL]]?
        let query = "//Linear//Tracking"
        for document: Data in vastDocumentArray {
            guard let results = XADVASTXMLUtil.performXMLXPathQuery(document, query: query) as? [[NSObject : AnyObject]] else {
                return eventDict
            }
            for result in results {
                if let urlString = self.content(node: result) {
                    if let attributes = result["nodeAttributeArray" as NSObject]  as? [[NSObject : AnyObject]] {
                        for attribute in attributes {
                            if let name = attribute["attributeName" as NSObject] as? String,
                                name.isEqual("event") {
                                if let event = attribute["nodeContent" as NSObject] as? String {
                                    if eventDict == nil {
                                        eventDict = [String : [URL]]()
                                    }
                                    
                                    if let eventURL = self.urlWithCleanString(string: urlString) {
                                        if eventDict![event.lowercased()] == nil {
                                            eventDict![event.lowercased()] = [eventURL]
                                        } else {
                                            eventDict![event.lowercased()]!.append(eventURL)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        XADLogger.debug("VAST - Model", message: "returning event dictionary with \(eventDict?.count ?? 0) event(s)")
        
        for (eventKey, array) in (eventDict ?? [String : [URL]]()) {
            XADLogger.debug("VAST - Model", message: "\(eventKey) has \(array.count) URL(s)")
        }
        return eventDict
    }
    // returns the ClickThrough URL
    func clickThrough() -> XADVASTUrlWithId? {
        let query = "//ClickThrough"
        if let array = self.resultsForQuery(query: query),
            array.count > 0 {
            // There should be at most only one array element.
            return array[0]
        }
        return nil
    }
    // returns an array of VASTUrlWithId objects

    func clickTracking() -> [XADVASTUrlWithId]? {
        let query = "//ClickTracking"
        return self.resultsForQuery(query: query)
    }
    // returns an array of VASTMediaFile objects

    func mediaFiles() -> [XADVASTMediaFile]? {
        var mediaFileArray:[XADVASTMediaFile]?
        let query = "//MediaFile"
        for document: Data in vastDocumentArray {
            guard let results = XADVASTXMLUtil.performXMLXPathQuery(document, query: query) as? [[NSObject : AnyObject]] else {
                return mediaFileArray
            }
            for result in results {
                var id_:String?
                var delievery:String?
                var type:String?
                var bitrate:String?
                var width:String?
                var height:String?
                var scalable:String?
                var maintainAspectRatio:String?
                var apiFramework:String?
                
                if let attributes = result["nodeAttributeArray" as NSObject] as? [[NSObject : AnyObject]] {
                    for attribute in attributes {
                        if let name = attribute["attributeName" as NSObject] as? String {
                            let content = attribute["nodeContent" as NSObject] as? String
                            switch name {
                            case "id":
                                id_ = content
                            case "delivery":
                                delievery = content
                            case "type":
                                type = content
                            case "bitrate":
                                bitrate = content
                            case "width":
                                width = content
                            case "height":
                                height = content
                            case "scalable":
                                scalable = content
                            case "maintainAspectRatio":
                                maintainAspectRatio = content
                            case "apiFramework":
                                apiFramework = content
                            default: break
                            }
                        }
                    }
                }
                if var urlString = self.content(node: result) {
                    urlString = (self.urlWithCleanString(string: urlString)?.absoluteString)!
                    guard let delievery = delievery,
                        let type = type,
                        let width = width,
                        let height = height else {
                            continue
                    }
                    let mediaFile = XADVASTMediaFile(id: id_,
                                                    delivery: delievery,
                                                    type: type,
                                                    bitrate: bitrate,
                                                    width: width,
                                                    height: height,
                                                    scalable: scalable,
                                                    maintainAspectRatio: maintainAspectRatio,
                                                    apiFramework: apiFramework,
                                                    url: urlString)
                    if mediaFileArray == nil {
                        mediaFileArray = [XADVASTMediaFile]()
                    }
                    mediaFileArray!.append(mediaFile)
                }
            }
        }
        return mediaFileArray
    }

// MARK: - helper methods
    // returns an array of VASTUrlWithId objects
    private func resultsForQuery(query: String) -> [XADVASTUrlWithId]? {
        var array:[XADVASTUrlWithId]?
        let elementName = query.replacingOccurrences(of: "/", with: " ")
        for document: Data in vastDocumentArray {
            guard let results = XADVASTXMLUtil.performXMLXPathQuery(document, query: query) as? [[NSObject : AnyObject]] else {
                return array
            }
            for result in results {
                if let urlString = self.content(node: result),
                let impressionUrl = self.urlWithCleanString(string: urlString){
                    var id_: String?
                    // add underscore to avoid confusion with kewyord id
                    if let attributes = result["nodeAttributeArray" as NSObject] as? [[NSObject : AnyObject]] {
                        for attribute in attributes {
                            if let name = attribute["attributeName" as NSObject] as? String,
                                name.isEqual("id") {
                                id_ = attribute["nodeContent" as NSObject] as? String
                                break
                            }
                        }
                    }
                    
                    let impression = XADVASTUrlWithId(ID: (id_ ?? ""), url: impressionUrl)
                    if array == nil {
                        array = [XADVASTUrlWithId]()
                    }
                    array!.append(impression)
                }
            }
        }
        XADLogger.debug("VAST - Model", message: "returning \(elementName) array with \(array?.count ?? 0) element(s)")
        return array
    }

    // returns the text content of both simple text and CDATA sections
    private func content(node: [NSObject : AnyObject]) -> String? {
        // this is for string data
        if let nodes = node["nodeContent" as NSObject] {
            if nodes.length > 0 {
                return node["nodeContent" as NSObject] as? String
            }
        }
        // this is for CDATA
        if let childArray = node["nodeChildArray" as NSObject] as? [[NSObject : AnyObject]]{
            if childArray.count > 0 {
                // return the first array element that is not a comment
                for childNode in childArray {
                    if let childNodeName = childNode["nodeName" as NSObject] as? String,
                        childNodeName.isEqual("comment") {
                        continue
                    }
                    return childNode["nodeContent" as NSObject] as? String
                }
            }
        }
        return nil
    }

    private func urlWithCleanString(string: String) -> URL? {
        var cleanUrlString = string.trimmingCharacters(in: .whitespacesAndNewlines)
        // remove leading, trailing \n or space
        cleanUrlString = cleanUrlString.replacingOccurrences(of: "|", with: "%7c")
        return URL(string: cleanUrlString)
        // return the resulting URL
    }
}
