//
//  XADNetworkManager.swift
//  XADDisplaySdk
//
//  Created by Ray Wu on 1/3/17.
//  Copyright © 2017 Xad. All rights reserved.
//

import Foundation

let kNetworkIssue = 0
let kRequestIssue = 1
let kDecodeIssue = 2
let kNoDataIssue = 3

protocol NetworkManager {
    @available(*, deprecated:9.0)
    func doFetchWithURLSession(_ url:URL, completionHandler:@escaping (String, String) -> Void?, httpErrorHandler: @escaping (Int) -> Void?)
    func doFetchWithURLSession(_ url:URL, completionHandler:@escaping (String, [String: String]?) -> Void?, httpErrorHandler: @escaping (Int) -> Void?)
    func doFetchInBackgroundQueue(_ task: @escaping () throws -> [String]?, completionHandler:@escaping ([String]?) -> Void?, httpErrorHandler: @escaping () -> Void?)
}

struct XADNetworkManager: NetworkManager {
    let sessionQueue:OperationQueue = OperationQueue()
    
    func doFetchWithURLSession(_ url:URL, completionHandler:@escaping (String, [String: String]?) -> Void?, httpErrorHandler: @escaping (Int) -> Void?) {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: self.sessionQueue)
        var request = URLRequest(url: url)
        
        if Constants.kDebugOnBackend {
            request.addValue("true", forHTTPHeaderField: "x-xad-diag-dump-all")
        }
        
        let task = session.dataTask(with: request, completionHandler: { (data, response, error) in
            
            if let error = error as NSError? {
                XADLogger.error(message: "Error when fetching: \(error.domain)")
                httpErrorHandler(kNetworkIssue)
                return
            }
            
            guard let response = response as? HTTPURLResponse else {
                XADLogger.error(message: "No response")
                httpErrorHandler(kNoDataIssue)
                return
            }
            
            let statusCode = response.statusCode
            let header = response.allHeaderFields
            XADLogger.debug(message: "Response statusCode: \(statusCode)")
            if !(statusCode >= 200 && statusCode < 300) {
                httpErrorHandler(kRequestIssue)
                sendError(errorCode: .serverError, payload: "Status code: \(statusCode)")
                return
            }
            
            guard let data = data else {
                XADLogger.error(message: "No data")
                httpErrorHandler(kNoDataIssue)
                return
            }
            
            //Atlantic may misbehave by sending invalid data which has content-length
            guard data.count > 20 || data.count == 0 else {
                sendError(errorCode: .serverError, payload: "Atlantic is misbehaving, data lengtg is: \(data.count)")
                return
            }
            
            if data.count == 0 {
                XADLogger.debug(message: "Empty response (Data length is 0) returned")
                httpErrorHandler(kNoDataIssue)
                return
            }
            
            if Constants.kDebugOnBackend {
                do {
                    guard let bodyJSON = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                        let demandPartnerJSON = bodyJSON["demand-partner"] as? [String: Any],
                        let neptuneJSON = demandPartnerJSON["neptunenormandy"] as? [String: Any] else {
                        XADLogger.error(message: "No diagnose response found for neptune")
                        return
                    }
                    
                    if let neptuneDemandRequestJSON = neptuneJSON["demand-request"] as? [String: Any] {
                        let uriForNeptune = neptuneDemandRequestJSON["uri"] as? String
                        XADLogger.debug(message: "URI for Neptune: \(uriForNeptune ?? "No uri found")")
                    }
                    
                    
                    if let demandResponseJSON = neptuneJSON["demand-response"] as? [String: Any],
                        let demandResponseData : Data = (demandResponseJSON["data"] as? String)?.data(using: .utf8, allowLossyConversion: true),
                        let demandResponseDataJSON = try JSONSerialization.jsonObject(with: demandResponseData) as? [String: Any],
                        let demandResponseResultJSON = demandResponseDataJSON["results"] as? [String: Any],
                        let paidListingsJSON = demandResponseResultJSON["paid_listings"] as? [String: Any],
                        let paidJSONList = paidListingsJSON["listing"] as? [[String: Any]] {
                        if paidJSONList.count > 0 {
                            //forEach can't deal with array size with 0 ????
                            paidJSONList.forEach{ paidJSON in
                                XADLogger.debug(message: paidJSON.description)
                            }
                        } else {
                            XADLogger.debug(message: "No paid lists found from Neptune")
                        }
                    } else {
                        XADLogger.debug(message: "No demand responses found")
                    }
                    
                } catch {
                    XADLogger.debug(message: "Parse atlantic diagnose response error: " + error.localizedDescription)
                }
                
                XADLogger.debug(message: "Abort the response for debug mode")
                return
            }
            
            if let responseStr = String(data:data, encoding:String.Encoding.utf8) {
                completionHandler(responseStr, header as? [String: String])
            } else {
                XADLogger.error(message: "Error when decoding data")
                httpErrorHandler(kDecodeIssue)
                sendError(errorCode: .contentDecodingError, payload: "")
            }
            
        })
        task.resume()

    }
    
    @available(*, deprecated:9.0)
    func doFetchWithURLSession(_ url: URL, completionHandler: @escaping (String, String) -> Void?, httpErrorHandler: @escaping (Int) -> Void?) {
        let completionHandlerWithHeader = {(body: String, header: [String: String]?) in
            if let adGroupId = header?["X-XAD-AD-REF"] {
                completionHandler(body, adGroupId)
                XADLogger.debug(message: "AdGroupId: \(adGroupId)")
            } else {
                XADLogger.warning(message: "No header found for key: \"X-XAD-AD-REF\"")
            }
        }
        
        self.doFetchWithURLSession(url, completionHandler: completionHandlerWithHeader, httpErrorHandler: httpErrorHandler)
    }
    
    let backgroundQueue:DispatchQueue = DispatchQueue(label: "com.xad.NETWORK_BACKGROUND_QUEUE")
    
    func doFetchInBackgroundQueue(_ task: @escaping () throws -> [String]?, completionHandler:@escaping ([String]?) -> Void?, httpErrorHandler: @escaping () -> Void?) {
        self.backgroundQueue.async {
            do {
                let result = try task()
                completionHandler(result)
            } catch {
                httpErrorHandler()
            }
        }
    }
}
