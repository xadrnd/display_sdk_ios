//
//  XADErrorPosting.swift
//  XADDisplaySdk
//
//  Created by Stephen Anderson on 4/7/17.
//  Copyright © 2017 Xad. All rights reserved.
//

import Foundation

enum PostedError: Int{
    case contentError
    case contentCannotLoadError
    case contentExpandUrlError
    case contentResizePropertiesError
    case contentInjectJavascriptError
    case contentParseCommandError
    case contentDecodingError
    case contentNoMediaFileError
    case contentVideoPlayBackError
    case contentVideoDurationError
    case internalError
    case serverError
}

func sendError(errorCode: PostedError, payload: String, adGroupId: String) {

    let json: [String: Any] = [
        "app": XADUtils.appname() ?? "unknown",
        "appv": XADUtils.appver() ?? "unknown",
        "sdkv": String(XADDisplaySdkVersionNumber),
        "os": "ios",
        "err": errorCode.rawValue,
        "pay": payload,
        "adgroup": adGroupId
    ]
    
    let jsonData = try? JSONSerialization.data(withJSONObject: json)
    
    // create post request
    let url = URL(string: Constants.kXadServerErrorEndpoint)!

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.httpBody = jsonData
    request.timeoutInterval = 30.0
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in

    }
    
    task.resume()
}

func sendError(errorCode: PostedError, payload: String) {
    sendError(errorCode: errorCode, payload: payload, adGroupId: "0")
}

func sendError(errorCode: PostedError) {
    sendError(errorCode: errorCode, payload: "", adGroupId: "0")
}



