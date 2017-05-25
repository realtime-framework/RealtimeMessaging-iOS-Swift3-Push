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
    
    open static func registForNotifications() -> Bool {
        
        #if os(iOS)
            if #available(iOS 10.0, *) {
                let center = UNUserNotificationCenter.current()
                center.requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
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

        #endif
        
        #if os(tvOS)
            if #available(tvOS 10.0, *) {
                let center = UNUserNotificationCenter.current()
                center.requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
                    // actions based on whether notifications were authorized or not
                }
                UIApplication.shared.registerForRemoteNotifications()
            }
        #endif
        
        return true
    }
    
    open func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        var newToken: String = (deviceToken as NSData).description
        newToken = newToken.trimmingCharacters(in: CharacterSet(charactersIn: "<>"))
        newToken = newToken.replacingOccurrences(of: " ", with: "")
        print("\n\n - didRegisterForRemoteNotificationsWithDeviceToken:\n\((deviceToken as NSData).description)\n")
        OrtcClient.setDEVICE_TOKEN(newToken)
    }
    
    open func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void){
        completionHandler(UIBackgroundFetchResult.newData)
        self.application(application, didReceiveRemoteNotification: userInfo)
    }
    
    open func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        let NOTIFICATIONS_KEY = "Local_Storage_Notifications"
        
        if (userInfo["C"] as? NSString) != nil && (userInfo["M"] as? NSString) != nil && (userInfo["A"] as? NSString) != nil {

            if (((userInfo["aps"] as? NSDictionary)?["alert"]) is String) {
                
                var recRegex: NSRegularExpression?
                
                do{
                    recRegex = try NSRegularExpression(pattern: "^#(.*?):", options:NSRegularExpression.Options.caseInsensitive)
                }catch{
                    
                }
                
                let recMatch: NSTextCheckingResult? = recRegex?.firstMatch(in: userInfo["M"] as! String, options: NSRegularExpression.MatchingOptions.reportProgress, range: NSMakeRange(0, (userInfo["M"] as! NSString).length))
                
                var strRangeSeqId: NSRange?
                if recMatch != nil{
                    strRangeSeqId = recMatch!.rangeAt(1)
                }
                var seqId:NSString?
                var message:NSString?
                if (recMatch != nil && strRangeSeqId?.location != NSNotFound) {
                    seqId = (userInfo["M"] as! NSString).substring(with: strRangeSeqId!) as NSString
                    let parts:[String] = (userInfo["M"] as! NSString).components(separatedBy: "#\(seqId!):")
                    message = parts[1] as NSString
                }
                
                var ortcMessage: String
                if seqId != nil && seqId != ""  {
                    ortcMessage = "a[\"{\\\"ch\\\":\\\"\(userInfo["C"] as! String)\\\",\\\"s\\\":\\\"\(seqId! as! String)\\\",\\\"m\\\":\\\"\(message! as! String)\\\"}\"]"
                }else{
                    ortcMessage = "a[\"{\\\"ch\\\":\\\"\(userInfo["C"] as! String)\\\",\\\"m\\\":\\\"\(userInfo["M"] as! String)\\\"}\"]"
                }
                
                
                
                var notificationsDict: NSMutableDictionary?
                if UserDefaults.standard.object(forKey: NOTIFICATIONS_KEY) != nil{
                     notificationsDict = NSMutableDictionary(dictionary: UserDefaults.standard.object(forKey: NOTIFICATIONS_KEY) as! NSDictionary)
                }
                if notificationsDict == nil {
                    notificationsDict = NSMutableDictionary()
                }
                
                var notificationsArray: NSMutableDictionary?
                
                if notificationsDict?.object(forKey: userInfo["A"] as! String) != nil{
                    notificationsArray = NSMutableDictionary(dictionary: notificationsDict?.object(forKey: userInfo["A"] as! String) as! NSMutableDictionary)
                }
                
                if notificationsArray == nil{
                    notificationsArray = NSMutableDictionary()
                }
                
                notificationsArray!.setObject(false, forKey: ortcMessage as NSCopying)
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
    
    open func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
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
