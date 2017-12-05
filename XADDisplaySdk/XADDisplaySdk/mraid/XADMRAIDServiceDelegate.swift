//
//  XADMRAIDServiceDelegate.swift
//  XADMRAID
//
//  Created by Phillip Corrigan on 7/6/16.
//  Copyright © 2016 xAd, Inc. All rights reserved.
//

import Foundation


enum XADMRAIDSupport: String {
    case sms = "sms"
    case tel = "tel"
    case calendar = "calendar"
    case storePicture = "storePicture"
    case inlineVideo = "inlineVideo"
}


// A delegate for MRAIDView/MRAIDInterstitial to listen for notifications when the following events
// are triggered from a creative: SMS, Telephone call, Calendar entry, Play Video (external) and
// saving pictures. If you don't implement this protocol, the default for
// supporting these features for creative will be FALSE.
protocol XADMRAIDServiceDelegate: class{

    // These callbacks are to request other services.
    func mraidServiceCreateCalendarEventWithEventJSON(_ eventJSON: String?)
    func mraidServicePlayVideoWithUrlString(_ urlString: String?, presentViewController: UIViewController?)
    func mraidServiceStorePictureWithUrlString(_ urlString: String?)
    func mraidServiceCallTel(_ urlString: String?, presentViewController: UIViewController?)
    func mraidServiceSendSMS(_ urlString: String?, presentViewController: UIViewController?)
    func mraidServiceOpenBrowser(_ urlString: String?, presentViewController: UIViewController?)
    
}
