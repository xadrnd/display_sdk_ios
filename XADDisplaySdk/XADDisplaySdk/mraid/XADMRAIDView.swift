//
//  XADMRAIDView.swift
//  XADMRAID
//
//  Created by Phillip Corrigan on 7/6/16.
//  Copyright © 2016 xAd, Inc. All rights reserved.
//

import UIKit
import WebKit

enum MRAIDState: String {
    case loading = "loading"
    case normal = "default"
    case expanded = "expanded"
    case resized = "resized"
    case hidden = "hidden"
}

// A delegate for MRAIDView to listen for notification on ad ready or expand related events
protocol XADMRAIDViewDelegate: class {

    // These callbacks are for basic banner ad functionality
    func mraidViewReady(_ mraidView: XADMRAIDView)
    func mraidViewFailed(_ mraidView: XADMRAIDView)
    func mraidViewWillExpand(_ mraidView: XADMRAIDView)
    func mraidViewWillClose(_ mraidView: XADMRAIDView)
    func mraidViewDidClose(_ mraidView: XADMRAIDView)
    func mraidViewWillResize(_ mraidView: XADMRAIDView, absolutePosition: CGRect, allowOffscreen: Bool)
}

class XADMRAIDView: UIView {
    weak var testDelegate: XADDisplayTestDelegate?
    weak var delegate: XADMRAIDViewDelegate?
    weak var serviceDelegate: XADMRAIDServiceDelegate?
    weak var rootViewController: UIViewController?
    weak var presentingViewController: UIViewController? {
        get {
            if self.modalVC != nil &&  (self.isInterstitial || self.state == .expanded) {
                return self.modalVC
            }
            return self.rootViewController
        }
    }
    
    var isViewable: Bool = false {
        didSet {
            if oldValue != self.isViewable {
                fireViewableChangeEvent()
                XADLogger.debug(message: "isViewable: \(isViewable ? "YES" : "NO")")
            }
        }
    }
    
    override open var backgroundColor: UIColor? {
        didSet {
            currentWebView?.backgroundColor = backgroundColor
        }
    }
    
    // MARK: - PRIVATE
    var state: MRAIDState {
        //self.state can be set duplicate because view can be resized even already in resize state
        //assert(newValue != state, "Duplicated setting state")
        
        didSet {
            guard let currentWebView = currentWebView else {
                return
            }
            switch state {
            case .loading, .normal, .hidden:
                currentWebView.scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
                currentWebView.scrollView.isScrollEnabled = false
            case .expanded, .resized:
                currentWebView.scrollView.isScrollEnabled = true
            }
            if oldValue != state {
                self.fireStateChangeEvent()
            }
        }
    }
    
    // This corresponds to the MRAID placement type
    var isInterstitial = false
    
    // The only property of the MRAID expandProperties we need to keep track of
    // on the native side is the useCustomClose property.
    // The width, height, and isModal properties are not used in MRAID v2.0.
    var useCustomClose = false
    var orientationProperties = XADMRAIDOrientationProperties()
    var resizeProperties = XADMRAIDResizeProperties()
    var defaultAbsoluteFrame:CGRect?
    var closeEventRegion: UIButton?
    var resizeView: UIView?
    var resizeCloseRegion: UIButton?
    var previousMaxSize = CGSize.zero
    var previousScreenSize = CGSize.zero
    
    
    var modalVC: XADMRAIDModalViewController?
    var mraidjs: String?
    var baseURL: URL?
    
    fileprivate var htmlForReport: String
    fileprivate var adGroupId: String
    
    fileprivate var webView: WKWebView?
    fileprivate var webViewPart2: WKWebView?
    fileprivate var currentWebView: WKWebView?
    fileprivate var sharedProcessPool: WKProcessPool?
    
    var tapGestureRecognizer: UITapGestureRecognizer?
    var bonafideTapObserved = false
    
    override open var frame: CGRect {
        didSet {
            XADLogger.debug(message: "frame has changed: \(oldValue) -> \(frame)")
            frameDidChange()
        }
    }
    
    convenience init() {
        assertionFailure("init is not a valid initializer for the class XADMRAIDView")
        self.init()
    }
    
    override convenience init(frame: CGRect) {
        assertionFailure("initWithFrame is not a valid initializer for the class XADMRAIDView")
        self.init(frame: frame)
    }
    
    convenience required init?(coder aDecoder: NSCoder) {
        assertionFailure("initWithCoder is not a valid initializer for the class XADMRAIDView")
        self.init(coder: aDecoder)
    }
    
    //Init for bannerView
    convenience init(frame: CGRect, htmlData: String, adGroupId: String, baseURL: URL?, rootViewController: UIViewController) {
        self.init(frame: frame, htmlData: htmlData, adGroupId: adGroupId, baseURL: baseURL, asInterstitial: false,rootViewController: rootViewController)
    }

    //Init for interstitial
    init(frame: CGRect, htmlData: String, adGroupId: String, baseURL: URL?, asInterstitial: Bool, rootViewController: UIViewController) {
        
        XADLogger.info(message: "\(#function)")
        
        self.isInterstitial = asInterstitial
        self.rootViewController = rootViewController
        self.state = .loading
        self.htmlForReport = htmlData
        self.adGroupId = adGroupId

        super.init(frame: frame)
        
        // Get mraid.js
        do {
            self.mraidjs = try loadResourceMraidJs()
        } catch let error as MRAIDError {
            //If mraid.js not found, crash the app, something fatal error happen
            assertionFailure("No mraid found, caused by error: \(error)")
        } catch {
            //do nothing
        }
        
        self.setUpTapGestureRecognizer()
        self.isViewable = false
        self.useCustomClose = false
        
        self.webView = initWebView(bounds)
        self.currentWebView = webView
        
        guard let currentWebView = currentWebView else {
            XADLogger.error(message: "Webview hasn't be initiated")
            self.delegate?.mraidViewFailed(self)
            return
        }
        addSubview(currentWebView)
    
        self.previousMaxSize = CGSize.zero
        self.previousScreenSize = CGSize.zero

        //BaseURL always nil
        self.baseURL = baseURL
    
        // Inject mraid.js
        self.injectJavaScript(self.mraidjs!)
        if XAD_ENABLE_JS_LOG {
            self.injectJavaScript(webView: currentWebView, js: "var enableLog = true")
        }
    
        if let processedHtml = XADMRAIDUtil.processRawHtml(htmlData) {
            XADLogger.verbose(message: "HTML: \(processedHtml)")
            //Creative should never include any relative URLs, baseURL is safe to be nil
            currentWebView.loadHTMLString(processedHtml, baseURL: nil)
        } else {
            XADLogger.error(message: "Ad HTML is invalid, cannot load")
            self.delegate?.mraidViewFailed(self)
            sendError(errorCode: .contentCannotLoadError, payload: self.htmlForReport, adGroupId: adGroupId)
        }
        
        if isInterstitial {
            self.bonafideTapObserved = true  // no autoRedirect suppression for Interstitials
        }
    }
    
    
    deinit {
        XADLogger.debug(message: "\(XADLogger.typeName(self)) \(#function)")
        NotificationCenter.default.removeObserver(self)
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }
    
    // MARK: - MRAID loading
    
    enum MraidLoaderError: Error {
        case missingBundle(reason: String)
        case missingFileFromBundle(reason: String)
        case missingFileOrNotReadable(reason: String)
        case missingContent(reason: String)
    }
    
    func loadResourceMraidJs() throws -> String {
        
        guard let frameworkBundle = Bundle(identifier: "com.xad.XADDisplaySdk") else {
            throw MraidLoaderError.missingBundle(reason: "bundle id is not correct")
        }
        
        guard let filepath = frameworkBundle.path(forResource: "mraid", ofType: "js") else {
            throw MraidLoaderError.missingFileFromBundle(reason: "no such file in the bundle")
        }
        
        if !FileManager.default.isReadableFile(atPath: filepath) {
            throw MraidLoaderError.missingFileOrNotReadable(reason: "missing file or not readable")
        }
        
        let javascript = try String(contentsOfFile: filepath, encoding: .utf8)
        
        if javascript.characters.count == 0 || javascript.isEmpty {
            throw MraidLoaderError.missingContent(reason: "file is not correct providered")
        }
        
        return javascript
    }

    
    // MARK: -
    

    func isValidFeatureSet(_ features: [XADMRAIDSupport]) -> Bool
    {
        let allFeatures: [XADMRAIDSupport] = [
            .sms,
            .tel,
            .calendar,
            .storePicture,
            .inlineVideo,
            ]
    
        // Validate the features set by the user
        for feature in features {
            if !(allFeatures.contains(feature)) {
                XADLogger.warning(message: "unknownfeature")
                return false
            }
        }
        return true
    }
    
    func deviceOrientationDidChange(_ notification: Notification)
    {
        XADLogger.debug(message: "\(XADLogger.typeName(self)) \(#function)")
        DispatchQueue.main.async { [weak self] in
            self?.setScreenSize()
            self?.setMaxSize()
            self?.setDefaultPosition()
        }
    }
    
    func frameDidChange() {
        if self.state == .resized {
            setResizeViewPosition()
        }
        setDefaultPosition()
        setMaxSize()
        fireSizeChangeEvent()
    }
    
    // MARK: - interstitial support
    
    func showAsInterstitial() {
        XADLogger.debug(message: "\(#function)")
        expand(nil)
    }
    
    // MARK: - JavaScript --> native support
    
    // These methods are (indirectly) called by JavaScript code.
    // They provide the means for JavaScript code to talk to native code
    func close() {
        XADLogger.debug(message: "JS callback \(#function)")
    
        if self.state == .loading ||
            (self.state == .normal && !isInterstitial) ||
            self.state == .hidden {
            // do nothing
            return
        }
        
        self.delegate?.mraidViewWillClose(self)
        
        if self.state == .resized {
            closeFromResize()
            return
        }
        //Close from expanded
        if modalVC != nil {
            closeEventRegion?.removeFromSuperview()
            closeEventRegion = nil
            currentWebView?.removeFromSuperview()
            self.orientationProperties = XADMRAIDOrientationProperties()
            modalVC?.dismiss(animated: false, completion: nil)
        }
        
        modalVC = nil
        
        if webViewPart2 != nil {
            // Clean up webViewPart2 if returning from 2-part expansion.
            webViewPart2?.navigationDelegate = nil
            webViewPart2?.uiDelegate = nil
            currentWebView = webView
            webViewPart2 = nil
        } else {
            // Reset frame of webView if returning from 1-part expansion.
            webView?.frame = bounds
        }
        
        if let webView = self.webView {
            addSubview(webView)
        }
        
        if !isInterstitial {
            fireSizeChangeEvent()
        }
        
        isViewable = false
        
        if self.state == .normal && isInterstitial {
            self.state = .hidden
        } else if self.state == .expanded || self.state == .resized {
            self.state = .normal
        }
        
        self.delegate?.mraidViewDidClose(self)
    }
    
    // This is a helper method which is not part of the official MRAID API.
    func closeFromResize() {
        XADLogger.debug(message: "JS callback \(#function)")
        removeResizeCloseRegion()
        self.state = .normal
        
        guard let defaultAbsoluteFrame = self.defaultAbsoluteFrame,
            let webView = webView else {
                XADLogger.error(message: "No default absolute frame info")
                return
        }
        
        self.delegate?.mraidViewWillResize(self, absolutePosition: defaultAbsoluteFrame, allowOffscreen: resizeProperties.allowOffscreen)
        
        webView.removeFromSuperview()
        webView.frame = CGRect(x: 0, y: 0, width: defaultAbsoluteFrame.width, height: defaultAbsoluteFrame.height)
        addSubview(webView)

        resizeView?.removeFromSuperview()
        resizeView = nil
        fireSizeChangeEvent()
        self.delegate?.mraidViewDidClose(self)
    }
    
    func createCalendarEvent(_ eventJSON: String?) {
        XADLogger.debug(message: "JS callback \(#function) \(String(describing: eventJSON))")
        if !bonafideTapObserved && XAD_SUPPRESS_BANNER_AUTO_REDIRECT {
            XADLogger.info(message: "Suppressing an attempt to programmatically call mraid.createCalendarEvent() when no UI touch event exists.")
            return  // ignore programmatic touches (taps)
        }
        
        guard let eventJSON = eventJSON else {
            //Nothing to execute
            return
        }
        
        if Constants.kSupportedFeatures.contains(.calendar){
            serviceDelegate?.mraidServiceCreateCalendarEventWithEventJSON(eventJSON)
        } else {
            XADLogger.warning(message: "No calendar support has been included.")
        }
    }
    
    // Banner ad
    func expand(_ params: [String: String]?) {
        XADLogger.debug(message: "JS callback \(#function) \(String(describing: params?.description))")
        if !bonafideTapObserved && XAD_SUPPRESS_BANNER_AUTO_REDIRECT {
            XADLogger.info(message: "Suppressing an attempt to programmatically call mraid.expand() when no UI touch event exists.")
            return  // ignore programmatic touches (taps)
        }
    
        // The only time it is valid to call expand is when the ad is currently in either default or resized state.
        if self.state != .normal && self.state != .resized {
            // do nothing
            return
        }
        
        self.modalVC = XADMRAIDModalViewController(orientationProperties: orientationProperties)
        guard let modalVC = self.modalVC,
        let rootViewController = self.rootViewController else {
            return
        }
        let frame = UIScreen.main.bounds
        modalVC.view.frame = frame
        modalVC.view.backgroundColor = UIColor.white
        modalVC.delegate = self
        
        if let params = params,
            let urlString = params["url"],
            !urlString.isEmpty,
            URL(string: urlString)?.scheme != nil {
            // 2-part expansion
            self.webViewPart2 = self.initWebView(frame)
            self.currentWebView = self.webViewPart2
            self.bonafideTapObserved = true // by definition for 2 part expand a valid tap has occurred
            
            if self.mraidjs != nil {
                self.injectJavaScript(self.mraidjs!)
            }
            if XAD_ENABLE_JS_LOG {
                if currentWebView != nil {
                    self.injectJavaScript(webView: currentWebView!, js: "var enableLog = true")
                }
            }
            
            do {
                let content = try String(contentsOf: URL(string: urlString)!, encoding: .utf8)
                //Creative should never include any relative URLs, baseURL is safe to be nil
                webViewPart2?.loadHTMLString(content as String, baseURL: nil)
            } catch let error as NSError {
                XADLogger.error(message: "Could not load part 2 expanded content for URL: \(urlString), with error: \(error.description)")
                sendError(errorCode: .contentExpandUrlError, payload: self.htmlForReport, adGroupId: self.adGroupId)
                self.currentWebView = self.webView
                self.webViewPart2?.uiDelegate = nil
                self.webViewPart2?.navigationDelegate = nil
                self.webViewPart2 = nil
                self.modalVC = nil
                return
            }
            
        } else {
            // 1-part expansion or interstitial
            if let webView = self.webView {
                webView.frame = frame
                webView.removeFromSuperview()
                //(self.currentWebView = webView) hasn't been changed
            } else {
                XADLogger.error(message: "Webview is been destroyed")
                self.delegate?.mraidViewFailed(self)
            }
        }
    
        self.delegate?.mraidViewWillExpand(self)
        if let currentWebView = self.currentWebView {
            modalVC.view.addSubview(currentWebView)
        }
        
        // always include the close event region
        addCloseEventRegion()
        
        rootViewController.present(modalVC, animated: false, completion: nil)

        if !isInterstitial {
            self.state = .expanded;
//            fireStateChangeEvent()
        }
        fireSizeChangeEvent()
        isViewable = true
    }
    
    func open(_ urlString: String?) {
        guard let urlString = urlString else {
            //Nothing to open
            return
        }
        
        XADLogger.debug(message: "JS callback \(#function) \(String(describing: urlString))")
        if !bonafideTapObserved && XAD_SUPPRESS_BANNER_AUTO_REDIRECT {
            XADLogger.info(message: "Suppressing an attempt to programmatically call mraid.open() when no UI touch event exists.")
            return  // ignore programmatic touches (taps)
        }
        
        //sms:*...*
        if urlString.hasPrefix("sms:") {
            //resolve sms://*...* case
            let smsString = urlString.replacingOccurrences(of: "//", with: "")
            self.serviceDelegate?.mraidServiceSendSMS(smsString, presentViewController: self.presentingViewController)
            return
        }
        
        //tel:*...*
        if urlString.hasPrefix("tel:") {
            //resolve sms://*...* case
            let telString = urlString.replacingOccurrences(of: "//", with: "")
            self.serviceDelegate?.mraidServiceCallTel(telString, presentViewController: self.presentingViewController)
            return
        }
        
        //http or https
        if urlString.hasPrefix("http://") || urlString.hasPrefix("https://") {
            self.serviceDelegate?.mraidServiceOpenBrowser(urlString, presentViewController: self.presentingViewController)
        }
    }
    
    func playVideo(_ urlString: String?) {
        XADLogger.debug(message: "JS callback \(#function) \(String(describing: urlString))")
        if !bonafideTapObserved && XAD_SUPPRESS_BANNER_AUTO_REDIRECT {
            XADLogger.info(message: "Suppressing an attempt to programmatically call mraid.playVideo() when no UI touch event exists.")
            return  // ignore programmatic touches (taps)
        }
        
        guard let urlString = urlString else {
            //Nothing to play
            return
        }
        
        self.serviceDelegate?.mraidServicePlayVideoWithUrlString(urlString, presentViewController: self.presentingViewController)
    }
    
    func resize() {
        XADLogger.debug(message: "JS callback \(#function)")
        if !bonafideTapObserved && XAD_SUPPRESS_BANNER_AUTO_REDIRECT {
            XADLogger.info(message: "Suppressing an attempt to programmatically call mraid.resize when no UI touch event exists.")
            return  // ignore programmatic touches (taps)
        }
        
        guard let bannerFrameInRootView = rootViewController?.view.convert(self.bounds, from: self.superview) else {
            XADLogger.error(message: "RootViewController error")
            return
        }
        
        if self.defaultAbsoluteFrame == nil {
            self.defaultAbsoluteFrame = bannerFrameInRootView
        }
        
        var resizeFrame = CGRect(x: CGFloat(resizeProperties.offsetX), y: CGFloat(resizeProperties.offsetY), width: CGFloat(resizeProperties.width), height: CGFloat(resizeProperties.height))
        // The offset of the resize frame is relative to the origin of the default banner.
        resizeFrame.origin.x += bannerFrameInRootView.origin.x
        resizeFrame.origin.y += bannerFrameInRootView.origin.y
        
        if !resizeProperties.allowOffscreen {
            if let maxSize = self.rootViewController?.view.bounds {
                if resizeFrame.origin.x + resizeFrame.size.width > maxSize.width {
                    resizeFrame.origin.x = maxSize.width - resizeFrame.size.width
                }
                if resizeFrame.origin.y + resizeFrame.size.height > maxSize.height {
                    resizeFrame.origin.y = maxSize.height - resizeFrame.size.height
                }
            }
        }
        
        if resizeFrame.origin.x < 0 || resizeFrame.origin.y < 0 {
            XADLogger.error(message: "Resize view position or size can't be satisfied")
            return
        }
        
        // resize here
        self.state = .resized
        self.delegate?.mraidViewWillResize(self, absolutePosition: resizeFrame, allowOffscreen: resizeProperties.allowOffscreen)
        
        if resizeView == nil {
            resizeView = UIView(frame: resizeFrame)
            addShadow(resizeView)
            webView?.removeFromSuperview()
            resizeView!.addSubview(webView!)
            rootViewController?.view.addSubview(resizeView!)
        }
        
        resizeView!.frame = resizeFrame
        webView?.frame = resizeView!.bounds
        showResizeCloseRegion()
        fireSizeChangeEvent()
    }
    
    fileprivate func addShadow(_ view:UIView?) {
        guard let view = view else {
            return
        }
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 1
        view.layer.shadowOffset = CGSize.zero
        view.layer.shadowRadius = 2
        view.layer.shadowPath = UIBezierPath(rect: view.bounds).cgPath
    }
    
    func setOrientationProperties(_ properties: [String: String]?) {
        guard let properties = properties else {
            //Nothing to set
            return
        }
        XADLogger.debug(message: "JS callback \(#function)")
        //According to MRAID, default value is true
        let allowOrientationChangeString: String = properties["allowOrientationChange"] ?? self.orientationProperties.allowOrientationChange.description
        let forceOrientationString: String = properties["forceOrientation"] ?? "none"
        XADLogger.debug(message: "JS callback \(#function) \(allowOrientationChangeString) - \(forceOrientationString)")
        self.orientationProperties = XADMRAIDOrientationProperties(allowOrientationChange: allowOrientationChangeString,
                                                                   forceOrientation: forceOrientationString)
        
        
        
        if let modalVC = modalVC {
            if modalVC.forceToOrientation(orientationProperties) {
                XADLogger.debug(message: "Rotate screen to \(self.orientationProperties.forceOrientation.rawValue)")
            }
        }
    }
    
    func setResizeProperties(_ properties: [String: String]?) {
        guard let properties = properties,
            let widthString = properties["width"],
            let width = Int(widthString),
            let heightString = properties["height"],
            let height = Int(heightString),
            let offSetXString = properties["offsetX"],
            let offsetX = Int(offSetXString),
            let offsetString = properties["offsetY"],
            let offsetY = Int(offsetString) else {
                XADLogger.error(message: "Resize properties is not correct")
                sendError(errorCode: .contentResizePropertiesError, payload: self.htmlForReport, adGroupId: self.adGroupId)
                return
        }
        let allowOffscreen: Bool = Bool(properties["allowOffscreen"] ?? "true") ?? true
        let customClosePosition: String = properties["customClosePosition"] ?? "top-right"
        
        XADLogger.debug(message: "JS callback \(#function), \(width), \(height), \(offsetX), \(offsetY), \(String(describing: customClosePosition)), \(allowOffscreen)")
        resizeProperties.width = width
        resizeProperties.height = height
        resizeProperties.offsetX = offsetX
        resizeProperties.offsetY = offsetY
        resizeProperties.customClosePosition = XADMRAIDResizeProperties.MRAIDCustomClosePositionFromString(customClosePosition)
        resizeProperties.allowOffscreen = allowOffscreen
    }
    
    func storePicture(_ urlString: String?) {
        guard let urlString = urlString  else {
            //Nothing to store
            return
        }
        XADLogger.debug(message: "JS callback \(#function) \(urlString)")
        if !bonafideTapObserved && XAD_SUPPRESS_BANNER_AUTO_REDIRECT {
            XADLogger.info(message: "Suppressing an attempt to programmatically call mraid.storePicture when no UI touch event exists.")
            return  // ignore programmatic touches (taps)
        }
        
        if Constants.kSupportedFeatures.contains(.storePicture) {
            serviceDelegate?.mraidServiceStorePictureWithUrlString(urlString)
        } else {
            XADLogger.warning(message: "No MRAIDSupportsStorePicture feature has been included")
        }
    }
    
    func useCustomClose(_ isCustomCloseString: String?) {
//        let isCustomClose = (isCustomCloseString as NSString).boolValue
        let isCustomClose = Bool(isCustomCloseString ?? "false") ?? false
        XADLogger.debug(message: "JS callback \(#function) \(isCustomClose)")
        self.useCustomClose = isCustomClose
    }
    
    
    // MARK: - JavaScript --> native support helpers
    
    // These methods are helper methods for the ones above.
    //For interstitial or expand, not for resize
    func addCloseEventRegion() {
        XADLogger.debug(message: "JS support \(#function)")

        guard !useCustomClose,
            let containerView = self.modalVC?.view else {
            XADLogger.debug(message: "No need to add close button")
            return
        }
        
        //create close region
        let closeEventRegion = UIButton(type: .custom)
        closeEventRegion.backgroundColor = UIColor.clear
        closeEventRegion.addTarget(self, action: #selector(close), for: .touchUpInside)
        
        //Add close button image
        if let frameworkBundle = Bundle(identifier: "com.xad.XADDisplaySdk"),
            let closeButtonImage = UIImage(named: "CloseButton.png", in: frameworkBundle, compatibleWith: nil) {
            let closeButtonImageView = UIImageView(image:closeButtonImage , highlightedImage: closeButtonImage)
            closeEventRegion.add(subView: closeButtonImageView, withSize: (Constants.kCloseButtonSize, Constants.kCloseButtonSize), toPosition: [(.centerX, 0.0), (.centerY, 0.0)])
        } else {
            XADLogger.error(message: "Error when access CloseButton.png")
            sendError(errorCode: .internalError, payload: "Can't find close button image")
        }
        
        //Add close region onto contain view
        containerView.add(subView: closeEventRegion, withSize: (Constants.kCloseEventRegionSize, Constants.kCloseEventRegionSize), toPosition: [(.top, Constants.kCloseEventRegionMargin), (.right, Constants.kCloseEventRegionMargin)])
        
    }
    
    func showResizeCloseRegion() {
        XADLogger.debug(message: "JS support \(#function)")
        guard let resizeView = resizeView else {
            XADLogger.error(message: "Resize View is not initiated")
            return
        }
        
        if (resizeCloseRegion == nil) {
            resizeCloseRegion = UIButton(type: .custom)
        }
        
        guard let resizeCloseRegion = resizeCloseRegion else {
            return
        }
        
        resizeCloseRegion.frame = CGRect(x: 0, y: 0, width: CGFloat(Constants.kCloseEventRegionSize),height: CGFloat(Constants.kCloseEventRegionSize))
        resizeCloseRegion.backgroundColor = UIColor.clear
        resizeCloseRegion.addTarget(self, action: #selector(closeFromResize), for: .touchUpInside)
        resizeView.addSubview(resizeCloseRegion)
        
        //align appropriately
        let x:CGFloat
        let y:CGFloat
        switch resizeProperties.customClosePosition {
        case .topLeft, .bottomLeft:
            x = 0
        case .topCenter, .center, .bottomCenter:
            x = (resizeView.frame.width - resizeCloseRegion.frame.width)/2
            autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin]
        case .topRight, .bottomRight:
            x = resizeView.frame.width - resizeCloseRegion.frame.width
            autoresizingMask = .flexibleLeftMargin
        }
        
        switch resizeProperties.customClosePosition {
        case .topRight, .topCenter, .topLeft:
            y = 0
        case .center:
            y = (resizeView.frame.height - resizeCloseRegion.frame.height)/2
            autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin]
        case .bottomRight, .bottomCenter, .bottomLeft:
            y = resizeView.frame.height - resizeCloseRegion.frame.height
            autoresizingMask = .flexibleTopMargin
        }
        
        
        var resizeCloseRegionFrame = resizeCloseRegion.frame
        resizeCloseRegionFrame.origin = CGPoint(x: x, y: y)
        resizeCloseRegion.frame = resizeCloseRegionFrame
        resizeCloseRegion.autoresizingMask = autoresizingMask
        
    }
    
    func removeResizeCloseRegion() {
        XADLogger.debug(message: "JS support \(#function)")
        if resizeCloseRegion != nil {
            resizeCloseRegion!.removeFromSuperview()
            resizeCloseRegion = nil
        }
    }
    
    func setResizeViewPosition() {
        XADLogger.debug(message: "JS support \(#function)")
        let oldResizeFrame = resizeView!.frame
        var newResizeFrame = CGRect(x: CGFloat(resizeProperties.offsetX), y: CGFloat(resizeProperties.offsetY), width: CGFloat(resizeProperties.width), height: CGFloat(resizeProperties.height))
        // The offset of the resize frame is relative to the origin of the default banner.
        let bannerOriginInRootView = rootViewController?.view.convert(CGPoint.zero, from: self)
        newResizeFrame.origin.x += bannerOriginInRootView!.x
        newResizeFrame.origin.y += bannerOriginInRootView!.y
        if !oldResizeFrame.equalTo(newResizeFrame) {
            resizeView?.frame = newResizeFrame
        }
    }
    
    // MARK: - native -->  JavaScript support
    
    func injectJavaScript(_ js: String) {
        guard let currentWebView = self.currentWebView else {
            XADLogger.error(message: "current web view is nil")
            return
        }
        self.injectJavaScript(webView: currentWebView, js: js)
    }
    
    func injectJavaScript(webView: WKWebView, js: String) {
        webView.evaluateJavaScript(js, completionHandler: {[weak self] (result, error) in
            guard let _self = self else {
                XADLogger.debug(message: "self is deinit, no inject javascript is expected")
                return
            }
            if let error = error {
                XADLogger.error(message: "\(#function) \(js) \(error)")
                sendError(errorCode: .contentInjectJavascriptError, payload: _self.htmlForReport, adGroupId: _self.adGroupId)
                return
            }
            
            if js != _self.mraidjs {
                XADLogger.debug(message: "Injected javascript \(js)")
            } else {
                XADLogger.debug(message: "Injected mraid.js")
            }
        })
    }
    
    // convenience methods
    func fireErrorEventWithAction(_ action: String, message: String) {
        injectJavaScript("mraid.fireErrorEvent('\(message)','\(action)');")
    }
    
    func fireReadyEvent() {
        injectJavaScript("mraid.fireReadyEvent()")
    }
    
    func fireSizeChangeEvent() {
        XADMRAIDUtil.synced(self) {
            let x:Int
            let y:Int
            let width:Int
            let height:Int
            if self.state == .expanded || self.isInterstitial,
                let currentWebView = self.currentWebView{
                
                x = Int(currentWebView.frame.origin.x)
                y = Int(currentWebView.frame.origin.y)
                width = Int(currentWebView.frame.size.width)
                height = Int(currentWebView.frame.size.height)
            } else if self.state == .resized,
                let resizeView = self.resizeView{
                x = Int(resizeView.frame.origin.x)
                y = Int(resizeView.frame.origin.y)
                width = Int(resizeView.frame.size.width)
                height = Int(resizeView.frame.size.height)
            } else {
                guard let originInRootView = self.rootViewController?.view.convert(CGPoint.zero, from: self.superview) else {
                    return
                }
                x = Int(originInRootView.x)
                y = Int(originInRootView.y)
                width = Int(self.frame.size.width)
                height = Int(self.frame.size.height)
            }
            
            let interfaceOrientation = UIApplication.shared.statusBarOrientation
            let isLandscape = UIInterfaceOrientationIsLandscape(interfaceOrientation)
            if self.isInterstitial && isLandscape {
                self.injectJavaScript("mraid.setCurrentPosition(\(x), \(y), \(height), \(width))")
            } else {
                self.injectJavaScript("mraid.setCurrentPosition(\(x), \(y), \(width), \(height))")
            }
        }
    }
    
    func fireStateChangeEvent() {
        injectJavaScript("mraid.fireStateChangeEvent('\(self.state.rawValue)');")
    }
    
    func fireViewableChangeEvent() {
        injectJavaScript("mraid.fireViewableChangeEvent(\(isViewable ? "true" : "false"));")
    }
    
    func setDefaultPosition() {
        if isInterstitial {
            // For interstitials, we define defaultPosition to be the same as screen size, so set the value there.
            return
        }
        
        // getDefault position from the parent frame if we are not directly added to the rootview
        guard let superview = superview, let rootView = rootViewController?.view else {
            return
        }
        if superview != rootView {
            injectJavaScript("mraid.setDefaultPosition(\(superview.frame.origin.x),\(superview.frame.origin.y),\(superview.frame.size.width),\(superview.frame.size.height));")
        } else {
            injectJavaScript("mraid.setDefaultPosition(\(frame.origin.x),\(frame.origin.y),\(frame.size.width),\(frame.size.height));")
        }
    }
    
    func setMaxSize() {
        if isInterstitial {
            // For interstitials, we define maxSize to be the same as screen size, so set the value there.
            return
        }
        if let maxSize = rootViewController?.view.bounds.size {
            if !maxSize.equalTo(previousMaxSize) {
                injectJavaScript("mraid.setMaxSize(\(Int(maxSize.width)),\(Int(maxSize.height)));")
                previousMaxSize = maxSize
            }
        }
    }
    
    func setScreenSize() {
        let screenSize = UIScreen.main.bounds.size
        if !screenSize.equalTo(previousScreenSize) {
            injectJavaScript("mraid.setScreenSize(\(Int(screenSize.width)),\(Int(screenSize.height)));")
            previousScreenSize = screenSize
            if (isInterstitial) {
                injectJavaScript("mraid.setMaxSize(\(Int(screenSize.width)),\(Int(screenSize.height)));")
                injectJavaScript("mraid.setDefaultPosition(0,0,\(Int(screenSize.width)),\(Int(screenSize.height)));")
            }
        }
    }
    
    func setSupports(_ currentFeatures: [XADMRAIDSupport]) {
        for feature in [XADMRAIDSupport.calendar, XADMRAIDSupport.inlineVideo, XADMRAIDSupport.sms, XADMRAIDSupport.storePicture, XADMRAIDSupport.tel] {
            let isOn = currentFeatures.contains(feature) ? "true" : "false"
            injectJavaScript("mraid.setSupports('\(feature.rawValue)',\(isOn));")
        }
    }
    
    // MARK: - internal helper methods
    func initWebView(_ frame: CGRect) -> WKWebView {
        
        let configuration = WKWebViewConfiguration()
        if Constants.kSupportedFeatures.contains(.inlineVideo) {
            configuration.allowsInlineMediaPlayback = true
            configuration.requiresUserActionForMediaPlayback = false
        } else {
            configuration.allowsInlineMediaPlayback = false
            configuration.requiresUserActionForMediaPlayback = true
            XADLogger.warning(message: "No inline video support has been included, videos will play full screen without autoplay.")
        }
        
        class ConsoleMessageHandler: NSObject, WKScriptMessageHandler {
            func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
                let messageDict = (message.body as? [String: String]) ?? [:]
                let messageBody = messageDict["message"] ?? "failed"
                let messageLogLevel = messageDict["level"] ?? "verbose"
                switch messageLogLevel {
                case LogLevel.debug.toString():
                    XADLogger.debug(message: "JS-Console.log: \(messageBody)")
                case LogLevel.warning.toString():
                    XADLogger.warning(message: "JS-Console.log: \(messageBody)")
                case LogLevel.error.toString():
                    XADLogger.error(message: "JS-Console.log: \(messageBody)")
                case LogLevel.info.toString():
                    XADLogger.info(message: "JS-Console.log: \(messageBody)")
                default:
                    XADLogger.verbose(message: "JS-Console.log: \(messageBody)")
                }
                
            }
        }
        
        let userContentController = WKUserContentController()
        let consoleMessageHandler = ConsoleMessageHandler()
        userContentController.add(consoleMessageHandler, name: "console")
        
        configuration.userContentController = userContentController
        
        //shared processpool will enforce sharing cookies between multiple webviews
        if sharedProcessPool == nil {
            sharedProcessPool = WKProcessPool()
        }
        configuration.processPool = self.sharedProcessPool!

        let webView = WKWebView(frame: frame, configuration: configuration)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        
        webView.isOpaque = false
        webView.autoresizingMask = [
            .flexibleWidth,
            .flexibleHeight,
            .flexibleLeftMargin,
            .flexibleRightMargin,
            .flexibleTopMargin,
            .flexibleBottomMargin
        ]
        webView.autoresizesSubviews = true
        webView.scrollView.isScrollEnabled = false
        
        // disable selection
        self.injectJavaScript(webView: webView, js: "window.getSelection().removeAllRanges();")
        
        
        // Alert suppression
        if XAD_SUPPRESS_JS_ALERT {
            self.injectJavaScript(webView: webView, js: "function alert(){}; function prompt(){}; function confirm(){}")
        }
        
        return webView
    }
    
    func parseCommandUrl(_ commandUrlString: String) {
        XADLogger.debug(message: "\(#function)")
        
        var command: XADMRAIDCommand?
        do {
            command = try XADMRAIDParser.parseCommandUrl(commandUrlString)
        } catch {
            XADLogger.error(message: "invalid command URL: \(commandUrlString)")
            sendError(errorCode: .contentParseCommandError, payload: self.htmlForReport, adGroupId: self.adGroupId)
        }
        
        if let command = command {
            execute(command)
        }
    }
    
    func execute(_ command: XADMRAIDCommand) {
        switch command.command {
        case .createCalendarEvent:
            self.createCalendarEvent(command.params?["eventJSON"])
        case .close:
            self.close()
        case .expand:
            self.expand(command.params)
        case .open:
            self.open(command.params?["url"])
        case .playVideo:
            self.playVideo(command.params?["url"])
        case .resize:
            self.resize()
        case .setOrientationProperties:
            self.setOrientationProperties(command.params)
        case .setResizeProperties:
            self.setResizeProperties(command.params)
        case .storePicture:
            self.storePicture(command.params?["url"])
        case .useCustomClose:
            self.useCustomClose(command.params?["useCustomClose"])
        default:
            break
        }
    }
    
    // MARK: - Gesture Methods
    
    func setUpTapGestureRecognizer() {
        if !XAD_SUPPRESS_BANNER_AUTO_REDIRECT {
            return  // return without adding the GestureRecognizer if the feature is not enabled
        }
        // One finger, one tap
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action:#selector(oneFingerOneTap))
        
        // Set up
        if let tapGestureRecognizer = tapGestureRecognizer{
            tapGestureRecognizer.numberOfTapsRequired = 1
            tapGestureRecognizer.numberOfTouchesRequired = 1
            tapGestureRecognizer.delegate = self
            // Add the gesture to the view
            addGestureRecognizer(tapGestureRecognizer)
            XADLogger.debug(message: "Adding gesture succeed")
        }
    }
    
    func oneFingerOneTap() {
        bonafideTapObserved = true
        tapGestureRecognizer?.delegate = nil
        tapGestureRecognizer = nil
        XADLogger.debug(message: "tapGesture oneFingerTap observed")
    }
    
}

extension XADMRAIDView: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            XADLogger.debug(message: "Navigation error with bad url request.")
            return
        }

        if self.testDelegate?.intercept(url: url) ?? false {
            XADLogger.debug(message: "URL loading is intercepted by tester")
            decisionHandler(.cancel)
            return
        }
        
        XADLogger.debug(message: "\(#function) -- \"\(navigationAction.navigationType.stringDescription())\" -- \(url.description)")
        
        let absUrlString:String = url.absoluteString
        
        if let scheme:String = url.scheme,
            scheme == "mraid"{
            XADLogger.debug(message: "\(absUrlString)")
            self.parseCommandUrl(absUrlString)
            decisionHandler(.cancel)
            return
        }
        
        if let scheme:String = url.scheme,
            scheme == "console-log" {
            XADLogger.debug(message: "JS console.log: \(url.absoluteString.replacingOccurrences(of: "console-log://", with: "").removingPercentEncoding ?? "")")
            decisionHandler(.cancel)
            return
        }
        
        if navigationAction.navigationType == .linkActivated {
            XADLogger.debug(message: "JS webview load: \(String(describing: absUrlString.removingPercentEncoding))")
            //Open landing page
            self.open(absUrlString)
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
        
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        XADLogger.debug(message: "\(#function) -- \(String(describing: navigationResponse.response.url?.description))")
        if self.testDelegate?.intercept(urlResponse: navigationResponse.response) ?? false {
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }
    
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        
        XADLogger.debug(message: "\(#function)")
        
    }
    
    public func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        
        XADLogger.debug(message: "\(#function)")
        
    }
    
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        
        XADLogger.debug(message: "\(#function) -- \(error)")
        
    }
    
    public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        
        XADLogger.debug(message: "\(#function) - \(String(describing: webView.url?.absoluteString)) - \(navigation.debugDescription)")
        
    }
    
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        XADLogger.debug(message: "\(#function)")
        //If wv is webViewPart2, that means the part 2 expanded web view has just loaded.
        //In this case, state should already be MRAIDStateExpanded and should not be changed.
        if (webView != webViewPart2) {

            if XAD_SUPPRESS_JS_ALERT {
                self.injectJavaScript(webView: webView, js: "function alert(){}; function prompt(){}; function confirm(){}")
            }
            
            if self.state == .loading {
                self.state = .normal
                injectJavaScript("mraid.setPlacementType('\(isInterstitial ? "interstitial" : "inline")');")
                setSupports(Constants.kSupportedFeatures)
                setDefaultPosition()
                setMaxSize()
                setScreenSize()
                fireSizeChangeEvent()
                fireReadyEvent()
                
                self.isViewable = true // solved expand to white page
                
                self.delegate?.mraidViewReady(self)
                
                // Start monitoring device orientation so we can reset max Size and screenSize if needed.
                UIDevice.current.beginGeneratingDeviceOrientationNotifications()
                NotificationCenter.default.addObserver(self, selector: #selector(deviceOrientationDidChange(_:)), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
            }
        }
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        
        XADLogger.error(message: "\(#function) \(error)")
        
    }
    
    public func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        
        XADLogger.debug(message: "\(#function)")
        
    }
}


extension XADMRAIDView: WKUIDelegate {
    public func webViewDidClose(_ webView: WKWebView) {
        
        XADLogger.debug(message: "\(#function)")
        
    }
    
    public func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        XADLogger.debug(message: "\(#function)")
        XADLogger.info("JS - Alert: ", message: message)
        completionHandler()
    }
    
    public func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        XADLogger.debug(message: "\(#function)")
        
    }
    
    public func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        XADLogger.debug(message: "\(#function)")
    }
}


// MARK: - MRAIDModalViewControllerDelegate

extension XADMRAIDView: XADMRAIDModalViewControllerDelegate {
    
    public func mraidModalViewControllerDidRotate(_ modalViewController: XADMRAIDModalViewController) {
        XADLogger.debug(message: "\(#function)")
        setScreenSize()
        fireSizeChangeEvent()
    }
}

extension XADMRAIDView: UIGestureRecognizerDelegate {

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        // required to allow UIWebview to work correctly, see http://stackoverflow.com/questions/2909807/does-uigesturerecognizer-work-on-a-uiwebview
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view == resizeCloseRegion || touch.view == closeEventRegion {
            XADLogger.debug(message: "tapGesture 'shouldReceiveTouch' = false")
            return false
        }
        XADLogger.debug(message: "tapGesture 'shouldReceiveTouch' = true")
        return true
    }
}

extension XADMRAIDView {
    open override func removeFromSuperview() {
        self.currentWebView?.removeFromSuperview()
        self.currentWebView = nil
        self.webView?.removeFromSuperview()
        self.webView = nil
        self.webViewPart2?.removeFromSuperview()
        self.webViewPart2 = nil
        self.resizeView?.removeFromSuperview()
        self.resizeView = nil
        super.removeFromSuperview()
    }
}
