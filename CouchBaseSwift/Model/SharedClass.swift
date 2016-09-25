//
//  SharedClass.swift
//  CouchBaseSwift
//
//  Created by Jignesh Patel on 01/09/16.
//  Copyright © 2016 Jignesh Patel. All rights reserved.
//

//import Cocoa

class SharedClass: NSObject {

    static let sharedInstance = SharedClass()
    static let kAnonymous = "Anonymous"
    static let kPrefFile = "pref"
    static var navController:UINavigationController? = nil
    
    var pref:AppPref?

    let kDbName = "automint"
    var kTrementDocId:String?
    var kInventoryDocId:String?
    var kSettingDocId:String?
    
    let cblManager:CBLManager = CBLManager.sharedInstance()
    var database:CBLDatabase?
    static var isReachable:Bool   = false
    
    private override init() {
        
        super.init()
        
        setupPrefrences()
        
        if CBLManager.isValidDatabaseName(kDbName) {
            
            do {
                
                try self.database = self.cblManager.databaseNamed(kDbName)
                
            } catch let error as NSError {
                
                print("Cannot create database. Error message: \(error), \(error.userInfo)")
                
            }
            
        }
        
    }
    
    //MARK:-  alertView
    static func alertView(strTitle:String,strMessage:String){
        
        let alert:UIAlertView = UIAlertView(title: strTitle as String, message: strMessage as String, delegate: nil, cancelButtonTitle: "Ok")
        
        dispatch_async(dispatch_get_main_queue(), {
            alert.show()
        })
    }
    
    //MARK:- internal helper methods
    internal func setupPrefrences() {
        if let tmpAppPref = AppPref.loadFrom(SharedClass.kPrefFile) {
            self.pref = tmpAppPref
        } else {
            self.pref = AppPref.init()
        }
    }
    
    //MARK:- Helper Methods
    static func timeBasedUUID() -> String {
        let uuidSize = sizeof(uuid_t)
        let uuidPointer = UnsafeMutablePointer<UInt8>.alloc(uuidSize)
        uuid_generate_time(uuidPointer)
        let uuid = NSUUID(UUIDBytes: uuidPointer)
        uuidPointer.dealloc(uuidSize)
        
        return uuid.UUIDString.lowercaseString
    }
    
    // check internet if available then get user data & update appRef
    // check for lic start & end date
    // if current date out of range then logout
    func getUpdatedUserDataWebservice(username:String,password:String, successHandler:((isSuccess:Bool,errorString:String)-> Void)?) {
        
        let postData = ["name":username,"password":password]
        
        let webAPI = Webservice()
        //TODO: update url
        webAPI.RequestForPost("/licensing/0.1/auth", postData: postData) { (response, isSuccess) in
            
            var messageString = ""
            var isOk = false
            
            if isSuccess {
                
                NSLog("response : %@",response)
                
                guard  let status :String  = (response.valueForKey("data")?.valueForKey("mint_code"))! as? String else {
                    
                    if successHandler != nil {
                        successHandler!(isSuccess: false, errorString: "Something went wrong, Please try again")
                    }
                    return
                }
                
                switch status {
                    case "AU100":
                        let (status,message) = self.parseSuccessData(response.valueForKey("data") as? [String:AnyObject])
                        messageString = message
                        isOk = status
                    case "AU200":
                        messageString = "Invalid user name or password"
                        isOk = false
                    case "AU311":
                        messageString = "User name is not valid"
                        isOk = false
                    case "AU312":
                        messageString = "User name is not valid"
                        isOk = false
                    case "AU321","AU322":
                        messageString = "User name is not valid"
                        isOk = false
                    //case "AU330":// no lic data in db
                    default:
                        messageString = "Something went wrong, Please try again"
                        isOk = false
                }
                
                if successHandler != nil {
                    successHandler!(isSuccess: isOk, errorString: messageString)
                }
                
            } else {
                if !SharedClass.isReachable{
                    messageString = "Please check your internet connection"
                } else {
                    messageString = "Something went wrong, Please try again"
                }
                
                if successHandler != nil {
                    successHandler!(isSuccess: false, errorString: messageString)
                }
            }
        }
    }
    
    func parseSuccessData(let data:[String:AnyObject]?) -> (status:Bool,message:String) {
        
        var messageString = "Something went wrong, Please try again"
        var status = false
        
        guard data != nil else {
            return (status,messageString)
        }
        guard let licenseDict = data!["license"] as? [String:AnyObject], let licenseData = licenseDict["license"] as? [String:AnyObject], let cloudData = licenseDict["cloud"] as? [String:AnyObject] else {
            return (status,messageString)
        }
        
        guard let licStartString = licenseData["starts"] as? String, let licEndString = licenseData["ends"] as? String, let cloudStartString = cloudData["starts"] as? String, let cloudEndString = cloudData["ends"] as? String else {
            return (status,messageString)
        }
        
        let dateFormat = "yyyy-MM-dd"
        guard let licStartDate = NSDate(fromString: licStartString, format: dateFormat), let licEndDate = NSDate(fromString: licEndString, format: dateFormat), let cloudStartDate = NSDate(fromString: cloudStartString, format: dateFormat), let cloudEndDate = NSDate(fromString: cloudEndString, format: dateFormat) else {
            return (status,messageString)
        }
        
        guard let userData = data!["userCtx"] as? [String:AnyObject], let channelData = userData["channels"] as? [String:AnyObject] else {
            return (status,messageString)
        }
        
        let characterset = NSCharacterSet(charactersInString: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLKMNOPQRSTUVWXYZ0123456789")
        
        // get channel from channel data
        var channel:String? = nil
        for channelKey in channelData.keys {
            
            if channelKey.rangeOfCharacterFromSet(characterset.invertedSet) != nil {
                print("string contains special characters")
            } else {
                channel = channelKey
                break
            }
        }
        
        if channel == nil {
            return (status,messageString)
        }
        
        guard let pref = SharedClass.sharedInstance.pref else {
            return (status,messageString)
        }
        
        pref.channel = channel!
        pref.licenseStart = licStartDate
        pref.licenseEnd = licEndDate
        pref.cloudStart = cloudStartDate
        pref.cloudEnd = cloudEndDate
        
        //Save pref to disk
        pref.save(SharedClass.kPrefFile)
        
        status = true
        messageString = "Success!!"
        return (status,messageString)
    }
    
    func isLicenseValid() -> Bool {
        
        guard let licStart = SharedClass.sharedInstance.pref?.licenseStart else {
            return false
        }
        
        guard let licEnd = SharedClass.sharedInstance.pref?.licenseEnd else {
            return false
        }
        
        guard let cloudStart = SharedClass.sharedInstance.pref?.cloudStart else {
            return false
        }
        
        guard let cloudEnd = SharedClass.sharedInstance.pref?.cloudEnd else {
            return false
        }
        
        let currentDate = NSDate()
        
        // Compare them
        if currentDate >= licStart && currentDate < licEnd && currentDate >= cloudStart && currentDate < cloudEnd {
            
            return true
            
        }
        
        return false
    }
}
