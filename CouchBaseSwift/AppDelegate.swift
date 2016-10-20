//
//  AppDelegate.swift
//  CouchBaseSwift
//
//  Created by Jignesh Patel on 01/09/16.
//  Copyright © 2016 Jignesh Patel. All rights reserved.
//

import UIKit

let kSyncEnabled = true
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
        
        //enableLogging()
        
        guard kSyncEnabled, let userName = SharedClass.sharedInstance.pref?.username, let password = SharedClass.sharedInstance.pref?.password else {
            return
        }
        
        guard let syncUrl = NSURL(string:Webservice.kSyncGatewayUrl) else {
            return
        }
        
        var authenticator: CBLAuthenticatorProtocol?
        var headers: [String: String]?
        
        authenticator = CBLAuthenticator.SSLClientCertAuthenticatorWithAnonymousIdentity("MySSLXYWIK")
        authenticator = CBLAuthenticator.basicAuthenticatorWithName(userName, password: password)
        
        //CBLReplication.setAnchorCerts([], onlyThese: false)
        
        let cred = NSString(format: "%@:%@", userName, password)
        let credData = cred.dataUsingEncoding(NSUTF8StringEncoding)!
        let credBase64 = credData.base64EncodedStringWithOptions([])
        headers = ["Authorization": "Basic \(credBase64)"]
        
        let database = SharedClass.sharedInstance.database!
        pusher = database.createPushReplication(syncUrl)
        pusher.continuous = true
        pusher.authenticator = authenticator
        pusher.headers = headers
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AppDelegate.replicationProgress(_:)), name: kCBLReplicationChangeNotification, object: pusher)
        puller = database.createPullReplication(syncUrl)
        puller.continuous = true
        puller.authenticator = authenticator
        puller.headers = headers

        //puller.credential = NSURLCredential(user: "vrl", password: "asdf", persistence: .ForSession)
        var certs = NSMutableArray()
        let resourcePath = NSBundle.mainBundle().pathForResource("cert_viral_mac", ofType: "cer")
        if resourcePath != nil {
            if let certData = NSData(contentsOfFile: resourcePath!) {
                
                //puller.customProperties = ["pinnedCert":certData]
                //pusher.customProperties = ["pinnedCert":certData]
                
                let dataPtr = CFDataCreate(kCFAllocatorDefault, UnsafePointer<UInt8>(certData.bytes), certData.length)
                
                let certRef = SecCertificateCreateWithData(nil, dataPtr)
                if certRef != nil {
                    certs.addObject(certRef!)
                    CBLReplication.setAnchorCerts(certs as [AnyObject], onlyThese: false)
                }
            }
        }
        
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AppDelegate.replicationProgress(_:)), name: kCBLReplicationChangeNotification, object: puller)
        
        //pusher.start()
        puller.start()
        
    }
    
    func stopReplication() {
        pusher.stop()
        puller.stop()
    }
    
    func replicationProgress(notification: NSNotification) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible =
            (pusher.status == .Active || puller.status == .Active)
        
        let error = pusher.lastError
        if (error != syncError) {
            syncError = error
            if (error?.code) != nil {
                print(puller.serverCertificate)
                print(pusher.serverCertificate)
                NSLog("Push: Replication Error: %@", error!)
            }
        }
        
        let error1 = puller.lastError
        if (error1 != syncError) {
            syncError = error1
            if (error1?.code) != nil {
                print(puller.serverCertificate)
                print(pusher.serverCertificate)
                NSLog("puller: Replication Error: %@", error1!)
            }
        }
        
    }
    
    // MARK: - Logging
    func enableLogging() {
        //CBLManager.enableLogging("CBLDatabase")
        //CBLManager.enableLogging("View")
        //CBLManager.enableLogging("ViewVerbose")
        //CBLManager.enableLogging("Query")
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
                            
                            self.stopReplication()
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
                    self.stopReplication()
                    // navigate to login VC
                    SharedClass.navController!.popToRootViewControllerAnimated(false)
                }
            }
        }
    }
    
}

