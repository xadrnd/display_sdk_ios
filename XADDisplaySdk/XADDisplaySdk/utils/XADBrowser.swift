//
//  XADBrowser.swift
//  XADUtils
//
//  Created by Phillip Corrigan on 8/15/16.
//  Copyright © 2016 xAd, Inc. All rights reserved.
//

import UIKit
import WebKit

protocol XADBrowserDelegate: class {
    func xadBrowserClosed(_ xadBrowser: XADBrowser)
    func xadBrowserWillExitApp(_ xadBrowser: XADBrowser)
    func xadTelPopupOpen(_ xadBrowser: XADBrowser)
    func xadTelPopupClosed(_ xadBrowser: XADBrowser)
}

enum BrowserFeature: String {
    case supportInlineMediaPlayback = "supportInlineMediaPlayback"
    case disableStatusBar = "disableStatusBar"
    case scalePagesToFit = "scalePagesToFit"
}

fileprivate let telPrefix = "tel://"
fileprivate let smsPrefix = "sms://"

class XADBrowser: UIViewController {
    weak var delegate: XADBrowserDelegate?

    var browserControlsView: XADBrowserControlsView?
    var currentRequest: URLRequest?
    var currentViewController: UIViewController?
    var features = [BrowserFeature]()
    var browserWebView: WKWebView?
    var disableStatusBar: Bool {
        get {
            return self.features.contains(.disableStatusBar)
        }
    }
    var scalePagesToFit: Bool {
        get {
            return self.features.contains(.scalePagesToFit)
        }
    }
    var supportInlineMediaPlayback :Bool {
        get {
            return self.features.contains(.supportInlineMediaPlayback)
        }
    }

    
    // Public
    // Designated initializer
    init(delegate: XADBrowserDelegate?, withFeatures features: [BrowserFeature]) {
        self.delegate = delegate
        self.features = features
        super.init(nibName: nil, bundle: nil)
    }

    // Do not use
    convenience required init?(coder aDecoder: NSCoder) {
        assertionFailure("initWithCoder is not a valid initializer for the class XADBrowser")
        self.init(coder: aDecoder)
    }
    
    // Public
    // Load urlRequest and present the XADBrowserViewController Note: requests such as tel: will immediately be presented using the UIApplication openURL: method without presenting the viewController
    
    func loadRequest(_ urlRequest: URLRequest) {
        currentViewController = UIApplication.shared.keyWindow?.rootViewController
        while currentViewController?.presentedViewController != nil {
            currentViewController = currentViewController?.presentedViewController
        }
        
        guard let currentViewController = currentViewController else {
            return
        }
        view.frame = currentViewController.view.bounds
        
        guard let url = urlRequest.url else {
            return
        }
        let scheme = url.scheme
        let host = url.host
        let absUrlString = url.absoluteString
        
        var openSystemBrowserDirectly = false
        
        if absUrlString.hasPrefix("tel") {
            getTelPermission(absUrlString)
            return
        } else if host == "itunes.apple.com" || host == "phobos.apple.com" || host == "maps.google.com" {
            // Handle known URL hosts
            openSystemBrowserDirectly = true
        } else if scheme != "http" && scheme != "https" {
            // Deep Links
            openSystemBrowserDirectly = true
        }
        
        if (openSystemBrowserDirectly) {
            // Notify the callers that the app will exit
            if UIApplication.shared.canOpenURL(url) {
                delegate?.xadBrowserWillExitApp(self)
                UIApplication.shared.openURL(url)
            }
        } else {
            currentRequest = urlRequest
            currentViewController.present(self, animated: true, completion: nil)
        }
    }
    
    open override var prefersStatusBarHidden : Bool {
        return disableStatusBar
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.browserWebView == nil {
            let configuration = WKWebViewConfiguration()
            configuration.allowsInlineMediaPlayback = self.supportInlineMediaPlayback
            configuration.mediaPlaybackRequiresUserAction = false
            let webView = WKWebView(frame: view.bounds, configuration: configuration)
            webView.autoresizesSubviews = true
            self.browserWebView = webView
            self.view.addSubview(webView)
            self.addConstraints(webView)
            self.browserControlsView = XADBrowserControlsView()
            self.browserControlsView!.navigateDelegate = self
            
            let indicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
            indicator.hidesWhenStopped = true
            self.browserControlsView!.loadingIndicator?.customView?.addSubview(indicator)

            view.addSubview(self.browserControlsView!)
            self.addConstraints(browserControlsView!)
            if let currentRequest = self.currentRequest {
                self.browserWebView!.load(currentRequest)
            } else {
                XADLogger.error(message: "No Url Request found")
            }
        }
    }
    
    func addConstraints(_ browserView: UIView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let viewsDict = ["browserView": browserView]
        var allConstraints = [NSLayoutConstraint]()
        
        let horz = NSLayoutConstraint.constraints(withVisualFormat: "H:|-[browserView]-|",
                                                                  options: [],
                                                                  metrics: nil,
                                                                  views: viewsDict)
        allConstraints += horz
        let vert = NSLayoutConstraint.constraints(withVisualFormat: "V:|-[browserView]-|",
                                                                  options: [],
                                                                  metrics: nil,
                                                                  views: viewsDict)
        allConstraints += vert
        view.addConstraints(allConstraints)
    }
    
    // MARK: - Telephone call permission AlertView
    
    func getTelPermission(_ telString: String) {
        delegate?.xadTelPopupOpen(self)
    
        let tel = telString.replacingOccurrences(of: telPrefix, with: "")
        
        let telPermissionAlert = UIAlertController(title: telString, message: nil, preferredStyle: .alert)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { [unowned self] (action) in
            self.delegate?.xadTelPopupClosed(self)
        })
        let callAction = UIAlertAction(title: "Call", style: .default, handler: { [unowned self] (action) in
            self.delegate?.xadTelPopupClosed(self)
            // Notify listener
            self.delegate?.xadBrowserWillExitApp(self)
            
            // Parse phone number and dial
            let toCall = telPrefix + tel
            if let toCallUrl = URL(string: toCall),
                UIApplication.shared.canOpenURL(toCallUrl) {
                UIApplication.shared.openURL(toCallUrl)
            }
        })
        telPermissionAlert.addAction(cancelAction)
        telPermissionAlert.addAction(callAction)
        telPermissionAlert.present(telPermissionAlert, animated: true, completion: nil)
    }
    

}

// MARK: - XADBrowserControlsView actions
extension XADBrowser: XADBrowserControlsViewDelegate {
    func back() {
        guard let browserWebView = browserWebView else {
            return
        }
        if browserWebView.canGoBack {
            browserWebView.goBack()
        }
    }
    
    func dismiss() {
        XADLogger.debug(message: "Dismissing XADBrowser")
        delegate?.xadBrowserClosed(self)
        
        delegate = nil
        browserWebView = nil
        browserControlsView = nil
        currentRequest = nil
        features.removeAll()
        
        currentViewController?.dismiss(animated: false, completion: nil)
    }
    
    func forward() {
        guard let browserWebView = browserWebView else {
            return
        }
        if browserWebView.canGoForward {
            browserWebView.goForward()
        }
    }
    
    func launchSafari() {
        if let url = currentRequest?.url,
            UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.openURL(url)
        }
    }
    
    func refresh() {
        guard let browserWebView = browserWebView else {
            return
        }
        browserWebView.reload()
    }
}
