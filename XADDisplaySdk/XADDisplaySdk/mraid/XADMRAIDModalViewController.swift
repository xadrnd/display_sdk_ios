//
//  XADMRAIDModalViewController.swift
//  XADMRAID
//
//  Created by Phillip Corrigan on 7/6/16.
//  Copyright © 2016 xAd, Inc. All rights reserved.
//

import UIKit

protocol XADMRAIDModalViewControllerDelegate: class {

    func mraidModalViewControllerDidRotate(_ modalViewController: XADMRAIDModalViewController)

}

public class XADMRAIDModalViewController: UIViewController {

    weak var delegate: XADMRAIDModalViewControllerDelegate?

    var isStatusBarHidden: Bool = false
    var hasViewAppeared: Bool = false
    var needRotate: Bool = false
    var orientationProperties: XADMRAIDOrientationProperties
    var preferredOrientation: UIInterfaceOrientation = .portrait
    
    // This is to hide the status bar on iOS 7.
    override open var prefersStatusBarHidden : Bool {
        return true
    }
    
    
    override open var shouldAutorotate : Bool {
        var retval = false
        
        if let supportedOrientationsInPlist = Bundle.main.object(forInfoDictionaryKey: "UISupportedInterfaceOrientations") as? [String] {
            
            let isPortraitSupported = supportedOrientationsInPlist.contains("UIInterfaceOrientationPortrait")
            let isPortraitUpsideDownSupported = supportedOrientationsInPlist.contains("UIInterfaceOrientationPortraitUpsideDown")
            let isLandscapeLeftSupported = supportedOrientationsInPlist.contains("UIInterfaceOrientationLandscapeLeft")
            let isLandscapeRightSupported = supportedOrientationsInPlist.contains("UIInterfaceOrientationLandscapeRight")
            
            let currentInterfaceOrientation = UIApplication.shared.statusBarOrientation
            
            if orientationProperties.forceOrientation == .portrait {
                retval = (isPortraitSupported && isPortraitUpsideDownSupported)
            } else if orientationProperties.forceOrientation == .landscape {
                retval = (isLandscapeLeftSupported && isLandscapeRightSupported)
            } else {
                if (orientationProperties.allowOrientationChange) {
                    retval = true
                } else {
                    if (UIInterfaceOrientationIsPortrait(currentInterfaceOrientation)) {
                        retval = (isPortraitSupported && isPortraitUpsideDownSupported)
                    } else {
                        // currentInterfaceOrientation is landscape
                        return (isLandscapeLeftSupported && isLandscapeRightSupported)
                    }
                }
            }
        }
        
        return retval
    }
    
    override open var preferredInterfaceOrientationForPresentation : UIInterfaceOrientation {
        return preferredOrientation
    }
    
    override open var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        if orientationProperties.forceOrientation == .portrait {
            return [.portrait, .portraitUpsideDown]
        }
        
        if orientationProperties.forceOrientation == .landscape {
            return .landscape
        }
        
        if !orientationProperties.allowOrientationChange {
            if UIInterfaceOrientationIsPortrait(preferredOrientation) {
                return [.portrait, .portraitUpsideDown]
            } else {
                return .landscape
            }
        }
        
        return .all
    }
    

    convenience init() {
        self.init(orientationProperties: XADMRAIDOrientationProperties())
    }
    
    init(orientationProperties: XADMRAIDOrientationProperties) {
        
        self.orientationProperties = orientationProperties;
        super.init(nibName: nil, bundle: nil)
        
        modalPresentationStyle = UIModalPresentationStyle.fullScreen
        modalTransitionStyle = UIModalTransitionStyle.crossDissolve
        
        let currentInterfaceOrientation = UIApplication.shared.statusBarOrientation
        
        // If the orientation is forced, accomodate it.
        // If it's not fored, then match the current orientation.
        if self.orientationProperties.forceOrientation == .portrait {
            self.preferredOrientation = .portrait;
        } else if self.orientationProperties.forceOrientation == .landscape {
            if UIInterfaceOrientationIsLandscape(currentInterfaceOrientation) {
                self.preferredOrientation = currentInterfaceOrientation
            } else {
                self.preferredOrientation = .landscapeLeft
            }
        } else {
            self.preferredOrientation = currentInterfaceOrientation
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        self.orientationProperties = XADMRAIDOrientationProperties()
        super.init(coder: aDecoder)
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    
        XADLogger.debug(message: "\(#function)")
        self.hasViewAppeared = true
        
        if self.needRotate {
            self.delegate?.mraidModalViewControllerDidRotate(self)
            self.needRotate = false
        }
    }
    
    override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    
        super.viewWillTransition(to: size, with: coordinator)
        XADLogger.debug(message: "\(#function) -- \(size.debugDescription)")
        // willRotateToInterfaceOrientation code goes here
        coordinator.animate( alongsideTransition:{_ in}, completion: { [weak self] context in
            // didRotateFromInterfaceOrientation goes here
            guard let _self = self else {
                return
            }
            
            if _self.hasViewAppeared {
                _self.delegate?.mraidModalViewControllerDidRotate(_self)
            }
        })
    }
    
    func forceToOrientation(_ orientationProps: XADMRAIDOrientationProperties) -> Bool {
        self.orientationProperties = orientationProps
        let currentInterfaceOrientation = UIApplication.shared.statusBarOrientation
        
        if orientationProperties.forceOrientation == .portrait {
            if UIInterfaceOrientationIsPortrait(currentInterfaceOrientation) {
                // this will accomodate both portrait and portrait upside down
                preferredOrientation = currentInterfaceOrientation
            } else {
                preferredOrientation = .portrait
            }
        } else if orientationProperties.forceOrientation == .landscape {
            if (UIInterfaceOrientationIsLandscape(currentInterfaceOrientation)) {
                // this will accomodate both landscape left and landscape right
                preferredOrientation = currentInterfaceOrientation
            } else {
                preferredOrientation = .landscapeLeft
            }
        } else {
            if orientationProperties.allowOrientationChange {
                let currentDeviceOrientation = UIDevice.current.orientation
                if currentDeviceOrientation == .portrait {
                    preferredOrientation = .portrait
                } else if currentDeviceOrientation == .portraitUpsideDown {
                    preferredOrientation = .portraitUpsideDown
                } else if currentDeviceOrientation == .landscapeRight {
                    preferredOrientation = .landscapeLeft
                } else if currentDeviceOrientation == .landscapeLeft {
                    preferredOrientation = .landscapeRight
                }
                
                // Make sure that the preferredOrientation is supported by the app. If not, then change it.
                var preferredOrientationString = ""
                if preferredOrientation == .portrait {
                    preferredOrientationString = "UIInterfaceOrientationPortrait"
                } else if preferredOrientation == .portraitUpsideDown {
                    preferredOrientationString = "UIInterfaceOrientationPortraitUpsideDown"
                } else if preferredOrientation == .landscapeLeft {
                    preferredOrientationString = "UIInterfaceOrientationLandscapeLeft"
                } else if preferredOrientation == .landscapeRight {
                    preferredOrientationString = "UIInterfaceOrientationLandscapeRight"
                }
                if let supportedOrientationsInPlist = Bundle.main.object(forInfoDictionaryKey: "UISupportedInterfaceOrientations") as? [String] {
                    let isSupported = supportedOrientationsInPlist.contains(preferredOrientationString)
                    if !isSupported {
                        // use the first supported orientation in the plist
                        preferredOrientationString = supportedOrientationsInPlist[0]
                        if preferredOrientationString == "UIInterfaceOrientationPortrait" {
                            preferredOrientation = .portrait
                        } else if preferredOrientationString == "UIInterfaceOrientationPortraitUpsideDown" {
                            preferredOrientation = .portraitUpsideDown
                        } else if preferredOrientationString == "UIInterfaceOrientationLandscapeLeft" {
                            preferredOrientation = .landscapeLeft
                        } else if preferredOrientationString == "UIInterfaceOrientationLandscapeRight" {
                            preferredOrientation = .landscapeRight;
                        }
                    }
                }
            } else {
                preferredOrientation = currentInterfaceOrientation
            }
        }
        
        if (orientationProperties.forceOrientation == .portrait && UIInterfaceOrientationIsPortrait(currentInterfaceOrientation)) ||
            (orientationProperties.forceOrientation == .landscape && UIInterfaceOrientationIsLandscape(currentInterfaceOrientation)) ||
            (orientationProperties.forceOrientation == .none && (preferredOrientation == currentInterfaceOrientation))  {
            return false
        }
        
        if let presentingVC = presentingViewController {
            dismiss(animated: false, completion: {
                presentingVC.present(self, animated: false, completion: nil)
            })
        }
        
        needRotate = true
        return true
    }
    
    func stringfromUIInterfaceOrientation(_ interfaceOrientation: UIInterfaceOrientation) -> String {
        switch interfaceOrientation {
        case .portrait:
            return "portrait"
        case .portraitUpsideDown:
            return "portrait upside down"
        case .landscapeLeft:
            return "landscape left"
        case .landscapeRight:
            return "landscape right"
        default:
            return "unknown"
        }
    }

}


