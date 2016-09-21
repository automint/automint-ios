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
    
    let kDbName = "automint"
    let kChannelName = "TempChannel"
    var kTrementDocId:String?
    var kInventoryDocId:String?
    var kSettingDocId:String?
    
    let cblManager:CBLManager = CBLManager.sharedInstance()
    var database:CBLDatabase?
    
    private override init() {
        
        super.init()
        
        self.kTrementDocId = "treatment-\(kChannelName)"
        self.kInventoryDocId = "inventory-\(kChannelName)"
        self.kSettingDocId = "settings-\(kChannelName)"
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
    
    static func timeBasedUUID() -> String {
        let uuidSize = sizeof(uuid_t)
        let uuidPointer = UnsafeMutablePointer<UInt8>.alloc(uuidSize)
        uuid_generate_time(uuidPointer)
        let uuid = NSUUID(UUIDBytes: uuidPointer)
        uuidPointer.dealloc(uuidSize)
        
        return uuid.UUIDString.lowercaseString
    }
}
