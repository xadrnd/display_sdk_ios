//
//  XADBrowserControlsView.swift
//  XADUtils
//
//  Created by Phillip Corrigan on 8/15/16.
//  Copyright © 2016 xAd, Inc. All rights reserved.
//

import UIKit


protocol XADBrowserControlsViewDelegate: class {
    func back()
    func forward()
    func refresh()
    func launchSafari()
    func dismiss()
}


class XADBrowserControlsView: UIView {

    weak var navigateDelegate: XADBrowserControlsViewDelegate?
    var controlsToolbar: UIToolbar?
    var loadingIndicator: UIBarButtonItem?

    
    init() {
        super.init(frame: CGRect.zero)
        self.controlsToolbar = UIToolbar(frame: CGRect.zero)

        // In left to right order, to make layout on screen more clear
        let backButtonImage = UIImage(named: "back")
        let backButton = UIBarButtonItem(image: backButtonImage, style: .plain, target: self, action: #selector(back(_:)))
        backButton.isEnabled = false
        
        let flexBack = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        let forwardButtonImage = UIImage(named: "forward")
        let forwardButton = UIBarButtonItem(image: forwardButtonImage, style: .plain, target: self, action: #selector(forward(_:)))
        forwardButton.isEnabled = false
        
        let flexForward = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        let placeHolder = UIView(frame: CGRect.zero)
        self.loadingIndicator = UIBarButtonItem(customView: placeHolder)  // loadingIndicator will be added here by the browser
        
        let flexLoading = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        let refreshButton = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refresh(_:)))
        
        let flexRefresh = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        let launchSafariButton = UIBarButtonItem(barButtonSystemItem: .action, target:self, action: #selector(launchSafari(_:)))
        
        let flexLaunch = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        let stopButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(dismiss(_:)))

        let toolbarButtons = [backButton, flexBack, forwardButton, flexForward, loadingIndicator!, flexLoading, refreshButton, flexRefresh, launchSafariButton, flexLaunch, stopButton]
        self.controlsToolbar!.setItems(toolbarButtons, animated: false)

        addSubview(self.controlsToolbar!)
        self.addToolbarConstraints(self.controlsToolbar!)
    }

    convenience required init?(coder aDecoder: NSCoder) {
        assertionFailure("initWithCoder is not a valid initializer for the class XADBrowserControlsView")
        self.init(coder: aDecoder)
    }
    
    func addToolbarConstraints(_ toolbar: UIToolbar) {

        toolbar.translatesAutoresizingMaskIntoConstraints = false
        
        let leftConstraint = NSLayoutConstraint(item: toolbar,
                                                attribute: .leading,
                                                relatedBy: .equal,
                                                toItem: self,
                                                attribute: .leading,
                                                multiplier: 1.0,
                                                constant: 0.0)
        addConstraint(leftConstraint)
        
        let topConstriant = NSLayoutConstraint(item: toolbar,
                                               attribute: .top,
                                               relatedBy: .equal,
                                               toItem: self,
                                               attribute: .top,
                                               multiplier: 1.0,
                                               constant: 0.0)
        
        addConstraint(topConstriant)
        
        let rightConstraint = NSLayoutConstraint(item: toolbar,
                                                attribute: .trailing,
                                                relatedBy: .equal,
                                                toItem: self,
                                                attribute: .trailing,
                                                multiplier: 1.0,
                                                constant: 0.0)
        addConstraint(rightConstraint)
        
        let bottomConstriant = NSLayoutConstraint(item: toolbar,
                                               attribute: .bottom,
                                               relatedBy: .equal,
                                               toItem: self,
                                               attribute: .bottom,
                                               multiplier: 1.0,
                                               constant: 0.0)
        
        addConstraint(bottomConstriant)
        
    }
    
    // MARK - XADBrowserControlsViewDelegate
    
    func back(_ sender: UIBarButtonItem) {
        self.navigateDelegate?.back()
    }
    
    func dismiss(_ sender: UIBarButtonItem) {
        self.navigateDelegate?.dismiss()
    }
    
    func forward(_ sender: UIBarButtonItem) {
        self.navigateDelegate?.forward()
    }
    
    func launchSafari(_ sender: UIBarButtonItem) {
        self.navigateDelegate?.launchSafari()
    }
    
    func refresh(_ sender: UIBarButtonItem) {
        self.navigateDelegate?.refresh()
    }

}

