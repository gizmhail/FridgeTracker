 //
//  NotificationScheduler.swift
//  FridgeTracker
//
//  Created by Sébastien POIVRE on 30/07/2017.
//  Copyright © 2017 Sébastien POIVRE. All rights reserved.
//

import Foundation
import UserNotifications
import UIKit

// Source: https://useyourloaf.com/blog/local-notifications-with-ios-10/

enum FoodNotificationAction {
    static let delete = "FoodNotificationAction.delete"
    static let ok = "FoodNotificationAction.ok"
    static let category = "FoodNotificationAction.category"
}

class NotificationScheduler: NSObject {
    static let shared = NotificationScheduler()
    let center = UNUserNotificationCenter.current()

    /// Must be call in AppDelegate didFinishLaunching
    func prepareReceivingNotifications(){
        let okAction = UNNotificationAction(identifier: FoodNotificationAction.ok,
                                                title: "Ok", options: [])
        let deleteAction = UNNotificationAction(identifier: FoodNotificationAction.delete,
                                                title: "Retirer", options: [.destructive])
        
        let category = UNNotificationCategory(identifier: FoodNotificationAction.category,
                                              actions: [okAction,deleteAction],
                                              intentIdentifiers: [], options: [])
        center.setNotificationCategories([category])
        center.delegate = self
        
        /*
        center.getPendingNotificationRequests(){ request in
            print("\(request)")
        }
        */
    }
    
    /// Ask the user to grant notification privileges
    func enableLocalNotifications(completionHandler:@escaping (_ granted:Bool)->()){
        let options: UNAuthorizationOptions = [.alert, .sound, .badge];
        center.getNotificationSettings { (settings) in
            if settings.authorizationStatus != .authorized {
                // Notifications not allowed
                self.center.requestAuthorization(options: options) {
                    (granted, error) in
                    if !granted {
                        print("[Error] User refused to grant access to notifications")
                        completionHandler(false)
                    } else {
                        completionHandler(true)
                    }
                }
            } else {
                completionHandler(true)
            }
        }
    }
    
    func cancelNotification(food:FridgeFoodInfo?) {
        guard let food = food, let foodId = food.foodId else {
            return
        }
        let notifIdentifier = "Notif\(foodId)"
        center.removePendingNotificationRequests(withIdentifiers: [notifIdentifier])
    }
    
    func scheduleNotification(food:FridgeFoodInfo?, completionHandler:@escaping (_ scheduled:Bool)->()) {
        enableLocalNotifications() { enabled in
            guard enabled == true, let food = food, let foodId = food.foodId, let expirationDate = food.expirationDate else {
                completionHandler(false)
                return
            }
            // Notification components
            let notifTitle = food.productName ?? "Aliment périmant bientôt"
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .none
            
            let notifSubtitle = formatter.string(from: expirationDate)
            let notifBody = "Périme bientôt"
            let notifDate = expirationDate.addingTimeInterval(-3600*24)
            let notifIdentifier = "Notif\(foodId)"
            let userInfo = ["FoodId":foodId]
            
            // Notfication content
            let content = UNMutableNotificationContent()
            content.title = notifTitle
            content.subtitle = notifSubtitle
            content.body = notifBody
            content.sound = UNNotificationSound.default()
            content.categoryIdentifier = FoodNotificationAction.category
            content.userInfo = userInfo
            if let imageURL = food.imageFileURL {
                do {
                    // Attachment "consumes" images, so we copy it
                    let notificationImagePath = imageURL.path + ".notification.png"
                    let notificationImageUrl = URL(fileURLWithPath: notificationImagePath)
                    do {
                        try FileManager.default.copyItem(at: URL(fileURLWithPath: imageURL.path) , to: URL(fileURLWithPath: notificationImageUrl.path))
                        let attachement = try UNNotificationAttachment(identifier: "\(foodId)_image", url: notificationImageUrl, options: nil)
                        content.attachments = [attachement]
                    } catch {
                        print("Unableto backup db")
                    }
                } catch {
                    print(error)
                }
            }

            // Notification scheduling
            var triggerDate = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute,.second,], from: notifDate)
            
            triggerDate.hour = 12
            triggerDate.minute = 0
            triggerDate.second = 0
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate,
                                                        repeats: false)
            let request = UNNotificationRequest(identifier: notifIdentifier,
                                                content: content, trigger: trigger)
            self.center.add(request, withCompletionHandler: { (error) in
                if let _ = error {
                    completionHandler(false)
                } else {
                    completionHandler(true)
                }
            })
        }

    }
}

extension NotificationScheduler:UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert,.sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.actionIdentifier == FoodNotificationAction.delete {
            if let foodId = response.notification.request.content.userInfo["FoodId"] as? String {
                var index = 0
                while (index<FoodHistory.shared.count) {
                    let food = FoodHistory.shared[index]
                    if food.foodId == foodId {
                        FoodHistory.shared.remove(at: index)
                        break
                    }
                    index += 1
                }
            }
        }
        completionHandler()
    }
}
