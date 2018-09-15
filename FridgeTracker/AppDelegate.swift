//
//  AppDelegate.swift
//  FridgeTracker
//
//  Created by Sébastien POIVRE on 27/07/2017.
//  Copyright © 2017 Sébastien POIVRE. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        if let navigationController = self.window?.rootViewController as? UINavigationController {
            navigationController.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor:UIColor.white]
        }
        
        let fh = FoodHistory.shared
        fh.loadHistory()
        NotificationScheduler.shared.prepareReceivingNotifications()
        return true
    }
}

