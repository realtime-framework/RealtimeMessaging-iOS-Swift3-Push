//
//  RealtimePushNotifications.swift
//  OrtcClient
//
//  Created by joao caixinha on 21/01/16.
//  Copyright © 2016 Realtime. All rights reserved.
//

import Foundation
import UIKit
import UserNotifications
import RealtimeMessaging_iOS_Swift3

/**
 * OrtcClientPushNotificationsDelegate process custom push notification with payload
 */
public protocol OrtcClientPushNotificationsDelegate{

    /**
     * Process custom push notifications with payload.
     * If receive custom push and not declared in AppDelegate class trow's excpetion
     * - parameter channel: from witch channel the notification was send.
     * - parameter message: the remote notification title
     * - parameter payload: a dictionary containig the payload data
     */
    func onPushNotificationWithPayload(_ channel:String, message:String, payload:NSDictionary?)
}

/**
 * UIResponder extenssion for auto configure application to use remote notifications
 */
extension UIResponder: OrtcClientPushNotificationsDelegate{
    
/**
     Overrides UIResponder initialize method
*/
    override open class func initialize() {
        NotificationCenter.default.addObserver(self.self, selector: #selector(UIResponder.registForNotifications), name: NSNotification.Name.UIApplicationDidFinishLaunching, object: nil)
    }
    
    static func registForNotifications() -> Bool {
        if #available(iOS 10.0, *) {
            let center = UNUserNotificationCenter.current()
            center.requestAuthorization(options: [.alert, .sound]) { (granted, error) in
                // actions based on whether notifications were authorized or not
            }
            UIApplication.shared.registerForRemoteNotifications()
        }else{
            if UIApplication.shared.responds(to: #selector(UIApplication.registerUserNotificationSettings(_:))) {
                let settings: UIUserNotificationSettings = UIUserNotificationSettings(types:[.alert, .badge, .sound], categories: nil)
                UIApplication.shared.registerUserNotificationSettings(settings)
                UIApplication.shared.registerForRemoteNotifications()
            }else {
                UIApplication.shared.registerForRemoteNotifications(matching: [.sound, .alert, .badge])
            }
        }
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        var newToken: String = (deviceToken as NSData).description
        newToken = newToken.trimmingCharacters(in: CharacterSet(charactersIn: "<>"))
        newToken = newToken.replacingOccurrences(of: " ", with: "")
        print("\n\n - didRegisterForRemoteNotificationsWithDeviceToken:\n\((deviceToken as NSData).description)\n")
        OrtcClient.setDEVICE_TOKEN(newToken)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void){
        completionHandler(UIBackgroundFetchResult.newData)
        self.application(application, didReceiveRemoteNotification: userInfo)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        let NOTIFICATIONS_KEY = "Local_Storage_Notifications"
        
        if (userInfo["C"] as? NSString) != nil && (userInfo["M"] as? NSString) != nil && (userInfo["A"] as? NSString) != nil {

            if (((userInfo["aps"] as? NSDictionary)?["alert"]) is String) {
                let ortcMessage: String = "a[\"{\\\"ch\\\":\\\"\(userInfo["C"] as! String)\\\",\\\"m\\\":\\\"\(userInfo["M"] as! String)\\\"}\"]"
                
                var notificationsDict: NSMutableDictionary?
                if UserDefaults.standard.object(forKey: NOTIFICATIONS_KEY) != nil{
                     notificationsDict = NSMutableDictionary(dictionary: UserDefaults.standard.object(forKey: NOTIFICATIONS_KEY) as! NSDictionary)
                }
                if notificationsDict == nil {
                    notificationsDict = NSMutableDictionary()
                }
                
                var notificationsArray: NSMutableArray?
                
                if notificationsDict?.object(forKey: userInfo["A"] as! String) != nil{
                    notificationsArray = NSMutableArray(array: notificationsDict?.object(forKey: userInfo["A"] as! String) as! NSArray)
                }
                
                if notificationsArray == nil{
                    notificationsArray = NSMutableArray()
                }
                
                notificationsArray!.add(ortcMessage)
                notificationsDict!.setObject(notificationsArray!, forKey: (userInfo["A"] as! String as NSCopying))
                UserDefaults.standard.set(notificationsDict!, forKey: NOTIFICATIONS_KEY)
                UserDefaults.standard.synchronize()
                NotificationCenter.default.post(name: Notification.Name(rawValue: "ApnsNotification"), object: nil, userInfo: userInfo)
            }
            else if((UIApplication.shared.delegate?.responds(to: #selector(onPushNotificationWithPayload(_:message:payload:)))) != nil){
                (UIApplication.shared.delegate as! OrtcClientPushNotificationsDelegate).onPushNotificationWithPayload(userInfo["C"] as! String,
                    message: userInfo["M"] as! String,
                    payload: userInfo["aps"] as? NSDictionary)
            }
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        NSLog("Failed to register with error : %@", error)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "ApnsRegisterError"), object: nil, userInfo: [
            "ApnsRegisterError" : error
            ]
        )
    }
    
    /**
     * Process custom push notifications with payload.
     * If receive custom push and not declared in AppDelegate class trow's excpetion
     * - parameter channel: from witch channel the notification was send.
     * - parameter message: the remote notification title
     * - parameter payload: a dictionary containig the payload data
     */
    open func onPushNotificationWithPayload(_ channel:String, message:String, payload:NSDictionary?){
            preconditionFailure("Must override onPushNotificationWithPayload method on AppDelegate")
    }

}
