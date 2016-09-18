//
//  VehicleService.swift
//  CouchBaseSwift
//
//  Created by Jignesh Patel on 10/09/16.
//  Copyright © 2016 Jignesh Patel. All rights reserved.
//

class VehicleService {
    
    // MARK: Declaration for string constants to be used to decode and also serialize.
    internal let kAMSrvcUUIDProblemsKey: String = "problems"
    internal let kAMSrvcUUIDInventoriesKey: String = "inventories"
    internal let kAMSrvcUUIDPartialpaymentKey: String = "partialpayment"
    internal let kAMSrvcUUIDDateKey: String = "date"

    var docID:String = ""
    var userName:String = ""
    var userMobile:Int = 0
    var vehicleName:String = ""
    var totalCost:Float32?
    var vehicleID:String = ""
    var serviceId:String = ""
    var date:NSDate = NSDate()
    var isPartialpayment:Bool = false
    
}
