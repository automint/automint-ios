//
//  AppDelegate.swift
//  CouchBaseSwift
//
//  Created by Jignesh Patel on 01/09/16.
//  Copyright © 2016 Jignesh Patel. All rights reserved.
//

import UIKit

let kSyncEnabled = true
let kSyncGatewayUrl = NSURL(string: "http://localhost:4984/automint/")!
let kLoggingEnabled = false


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var pusher: CBLReplication!
    var puller: CBLReplication!
    var syncError: NSError?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        IQKeyboardManager.sharedManager().enable = true
        
        startReplication()
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    // MARK: - Replication
    
    func startReplication() {
        guard kSyncEnabled else {
            return
        }
        
        let database = SharedClass.sharedInstance.database!
        pusher = database.createPushReplication(kSyncGatewayUrl)
        pusher.continuous = true
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AppDelegate.replicationProgress(_:)), name: kCBLReplicationChangeNotification, object: pusher)
        puller = database.createPullReplication(kSyncGatewayUrl)
        puller.continuous = true
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AppDelegate.replicationProgress(_:)), name: kCBLReplicationChangeNotification, object: puller)
        pusher.start()
        puller.start()
        
    }
    
    func replicationProgress(notification: NSNotification) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible =
            (pusher.status == .Active || puller.status == .Active)
        
        let error = pusher.lastError ?? puller.lastError
        if (error != syncError) {
            syncError = error
            if (error?.code) != nil {
                NSLog("Replication Error: %@", error!)
            }
        }
    }
    
    // MARK: - Logging
    func enableLogging() {
        CBLManager.enableLogging("CBLDatabase")
        CBLManager.enableLogging("View")
        CBLManager.enableLogging("ViewVerbose")
        CBLManager.enableLogging("Query")
        CBLManager.enableLogging("Sync")
        CBLManager.enableLogging("SyncVerbose")
    }
    

}

