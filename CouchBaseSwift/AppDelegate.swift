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
    
    var reachability    : Reachability?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        // Create sharedClass instance
        _ = SharedClass.sharedInstance
        
        // start rechablity fot internet connection status check
        setupRechablity()
        
        // check for license validation only if user logged in
        licenseValidation()
        
        // keyboard settings
        IQKeyboardManager.sharedManager().enable = true
        
        // start sync to server
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
        
        // check for license validation only if user logged in
        licenseValidation()
        
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
    
    //MARK:- setupRechablity
    func setupRechablity(){
        
        do {
            reachability = try Reachability.reachabilityForInternetConnection()
        } catch {
            print("Unable to create Reachability")
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self,selector: #selector(AppDelegate.reachabilityChanged(_:)), name: ReachabilityChangedNotification, object: reachability)
        
        do{
            try reachability!.startNotifier()
        }catch{
            print("cantaccess")
        }
    }
    
    func reachabilityChanged(note: NSNotification) {
        
        let reachability = note.object as! Reachability
        if reachability.isReachable() {
            
            if reachability.isReachableViaWiFi() {
                print("Reachable via WiFi")
            } else {
                print("Reachable via Cellular")
            }
            
            SharedClass.isReachable = true
            //SharedInstance.InternetDelegate?.changeConnectionStatus!()
            
        }else {
            
            print("Not reachable")
            SharedClass.isReachable = false
            //Constant.alertView("Error!", strMessage: AlertMessages.kInternetAlertMessage)
        }
    }
    
    //MARK: Helper Methods
    func licenseValidation () {
        
        guard let pref = SharedClass.sharedInstance.pref else {
            return
        }
        
        if pref.isLoggedIn {
            if SharedClass.isReachable {
                SharedClass.sharedInstance.getUpdatedUserDataWebservice(pref.username, password: pref.password, successHandler: { (isSuccess, errorString) in
                    // no need to check if success or failed as if success then appPref updated with new data else with old data, will check for license validation
                    let isValidLicense = SharedClass.sharedInstance.isLicenseValid()
                    
                    if !isValidLicense {
                        pref.isLoggedIn = false
                        pref.save(SharedClass.kPrefFile)
                        // navigate to login VC
                        dispatch_async(dispatch_get_main_queue(), {
                            SharedClass.navController!.popToRootViewControllerAnimated(false)
                        })
                    }
                })
            }else{
                // no internet then check with old data
                let isValidLicense = SharedClass.sharedInstance.isLicenseValid()
                
                if !isValidLicense {
                    pref.isLoggedIn = false
                    pref.save(SharedClass.kPrefFile)
                    // navigate to login VC
                    SharedClass.navController!.popToRootViewControllerAnimated(false)
                }
            }
        }
    }
    
}

