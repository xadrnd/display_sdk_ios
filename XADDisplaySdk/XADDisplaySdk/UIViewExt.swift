//
//  UIViewExt.swift
//  XADDisplaySdk
//
//  Created by Ray Wu on 4/10/17.
//  Copyright © 2017 Xad. All rights reserved.
//

import UIKit

public enum Position: Int{
    case top
    case right
    case left
    case bottom
    case centerX
    case centerY
}

public extension UIView {
    public func add(subView: UIView, withSize size:(Double, Double), toPosition postions:[(Position, Double)] ) {
        subView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(subView)
        let widthConstraints = NSLayoutConstraint(item: subView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: CGFloat(size.0))
        let heightConstraints = NSLayoutConstraint(item: subView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: CGFloat(size.1))
        subView.addConstraints([widthConstraints, heightConstraints])
        
        for (position, offset) in postions {
            switch position {
            case .top:
                let constraint = NSLayoutConstraint(item: subView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: CGFloat(offset))
                self.addConstraint(constraint)
            case .right:
                let constraint = NSLayoutConstraint(item: subView, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1.0, constant: CGFloat(-offset))
                self.addConstraint(constraint)
            case .left:
                let constraint = NSLayoutConstraint(item: subView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1.0, constant: CGFloat(offset))
                self.addConstraint(constraint)
            case .bottom:
                let constraint = NSLayoutConstraint(item: subView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: CGFloat(-offset))
                self.addConstraint(constraint)
            case .centerX:
                let xconstraint = NSLayoutConstraint(item: subView, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1.0, constant: CGFloat(offset))
                self.addConstraint(xconstraint)
            case .centerY:
                let yconstraint = NSLayoutConstraint(item: subView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: CGFloat(offset))
                self.addConstraint(yconstraint)
            }
            
        }
        
    }
}
