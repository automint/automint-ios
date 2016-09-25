//
//  AppPref.swift
//  Extensions
//
//  Created by Jignesh Patel on 01/09/16.
//  Copyright © 2016 Jignesh Patel. All rights reserved.
//

import UIKit

class AppPref: NSObject,NSCoding {
    
    // MARK: Declaration for string constants to be used to decode and also serialize.
    internal let kChannelKey: String = "channel"
    internal let kUsernameKey: String = "username"
    internal let kLicenseStartKey: String = "licenseStart"
    internal let kLicenseEndKey: String = "licenseEnd"
    internal let kCloudStartKey: String = "cloudStart"
    internal let kCloudEndKey: String = "cloudEnd"
    internal let kIsLoggedInKey: String = "isLoggedIn"
    internal let kPasswordKey: String = "password"

    var isLoggedIn:Bool
    var password:String
    var channel:String
    var username:String
    var licenseStart:NSDate?
    var licenseEnd:NSDate?
    var cloudStart:NSDate?
    var cloudEnd:NSDate?
    
    override init() {
        
        self.username = ""
        self.password = ""
        self.channel = ""
        self.isLoggedIn = false
        
        super.init()
        
        licenseStart = nil
        licenseEnd = nil
        cloudStart = nil
        cloudEnd = nil
    }

    class func loadFrom(fileName:NSString)-> AppPref?  {
        
        // load your custom object from the file
        if let temp = NSKeyedUnarchiver.unarchiveObjectWithFile(filePath(fileName).path!) {
            return temp as? AppPref
        } else {
            return nil
        }
    }

    /**
     * NSCoding required initializer.
     * Fills the data from the passed decoder
     */
    required convenience init?(coder aDecoder: NSCoder)
    {
        self.init()
        
        if let isLoggedInTemp = aDecoder.decodeObjectForKey(kIsLoggedInKey) as? Bool {
            isLoggedIn = isLoggedInTemp
        }
        if let user = aDecoder.decodeObjectForKey(kUsernameKey) as? String {
            username = user
        }
        if let pass = aDecoder.decodeObjectForKey(kPasswordKey) as? String {
            password = pass
        }
        if let channelTmp = aDecoder.decodeObjectForKey(kChannelKey) as? String {
            channel = channelTmp
        }
        
        licenseStart = aDecoder.decodeObjectForKey(kLicenseStartKey) as? NSDate
        licenseEnd = aDecoder.decodeObjectForKey(kLicenseEndKey) as? NSDate
        cloudStart = aDecoder.decodeObjectForKey(kCloudStartKey) as? NSDate
        cloudEnd = aDecoder.decodeObjectForKey(kCloudEndKey) as? NSDate
        
    }
    
    /**
     * NSCoding required method.
     * Encodes mode properties into the decoder
     */
    func encodeWithCoder(aCoder: NSCoder)
    {
        aCoder.encodeObject(username, forKey: kUsernameKey)
        aCoder.encodeObject(password, forKey: kPasswordKey)
        aCoder.encodeObject(channel, forKey: kChannelKey)
        aCoder.encodeObject(isLoggedIn, forKey: kIsLoggedInKey)
        
        if licenseStart != nil{
            aCoder.encodeObject(licenseStart, forKey: kLicenseStartKey)
        }
        if licenseEnd != nil{
            aCoder.encodeObject(licenseEnd, forKey: kLicenseEndKey)
        }
        if cloudStart != nil{
            aCoder.encodeObject(cloudStart, forKey: kCloudStartKey)
        }
        if cloudEnd != nil{
            aCoder.encodeObject(cloudEnd, forKey: kCloudEndKey)
        }
        
    }
    
   class func filePath(fileName : NSString) -> NSURL {
        
        let paths = NSURL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0])
        
        let getImagePath = paths.URLByAppendingPathComponent(fileName as String)
        
        return getImagePath!
    }
    
    func save(toFileName:NSString)-> Bool {
        
        let file = AppPref.filePath(toFileName)
        
        // save your custom object in a file
        let isPrefSaved =  NSKeyedArchiver.archiveRootObject(self, toFile: file.path!)
        
        return isPrefSaved
    }
    
    func clear(fileName:NSString)-> Bool {
        
        let fileUrl = AppPref.filePath(fileName)
        let filePath = fileUrl.path
        if filePath != nil && NSFileManager.defaultManager().fileExistsAtPath(filePath!) {
            
            if (try?NSFileManager.defaultManager().removeItemAtURL(fileUrl)) == nil {
                
                print("failed")
                
                return false
            }
        }
        
        return false
    }
}
