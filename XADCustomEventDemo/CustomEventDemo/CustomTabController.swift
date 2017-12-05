//
//  CustomTabController.swift
//  CustomEventDemo
//
//  Created by Ray Wu on 1/19/17.
//  Copyright © 2017 Xad. All rights reserved.
//

import UIKit

class CustomTabController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Sets the default color of the icon of the selected UITabBarItem and Title
        UITabBar.appearance().tintColor = UIColor(red: 114.0, green: 186.0, blue: 50.0, alpha: 255.0)
        
        // Sets the default color of the background of the UITabBar
        //        UITabBar.appearance().barTintColor = UIColor(red: 147.0, green: 190.0, blue: 106.0, alpha: 255.0)
        
        // Sets the background color of the selected UITabBarItem (using and plain colored UIImage with the width = 1/3 of the tabBar (if you have 3 items) and the height of the tabBar)
        UITabBar.appearance().selectionIndicatorImage = UIImage().makeImageWithColorAndSize(UIColor(red: 114.0/255.0, green: 186.0/255.0, blue: 50.0/255.0, alpha: 1.0), size: CGSize(width: tabBar.frame.width/3, height: tabBar.frame.height))
        
        // Uses the original colors for your images, so they aren't not rendered as grey automatically.
        for item in (tabBar.items)! {
            if let image = item.image {
                item.image = image.withRenderingMode(.alwaysOriginal)
            }
        }
    }
}

extension UIImage {
    func makeImageWithColorAndSize(_ color: UIColor, size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
}
