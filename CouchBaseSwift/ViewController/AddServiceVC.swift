//
//  AddServiceVC.swift
//  CouchBaseSwift
//
//  Created by Jignesh Patel on 07/09/16.
//  Copyright © 2016 Jignesh Patel. All rights reserved.
//

enum AddServiceSection {
    case none
    case Customer
    case Vehicle
    case Service
}

enum CheckMobileNumberStatus {
    case Error
    case NotFound
    case Found
}

class AddServiceVC: UIViewController,UITextFieldDelegate {
    
    // Globle Variable
    var exsistingService : VehicleService?
    var selectedVehicle : [String:AnyObject]?
    var vehicleData : [String:AnyObject]?
    var problemDict:[String:AnyObject]?
    var partDict:[String:AnyObject]?
    var selectedVehicleType : String?
    var currentSection:AddServiceSection = .Customer
    var database: CBLDatabase!
    var listsLiveQuery: CBLLiveQuery!
    var heightConstraintCustomerView:NSLayoutConstraint?
    var heightConstraintVehicleView:NSLayoutConstraint?
    var heightConstraintServiceView:NSLayoutConstraint?
    var mobilenumberChecked:String = ""
    var userNameList:[String] = []
    var userMobileList:[String:Int] = [:]
    
    // Outlets
    
    @IBOutlet weak var customerNameTextField: AutoCompleteTextField!
    @IBOutlet weak var customerMobileNumberTextField: UITextField!
    @IBOutlet weak var manufNameTextField: UITextField!
    @IBOutlet weak var modelNameTextField: UITextField!
    @IBOutlet weak var registrationNumberTextField: UITextField!
    @IBOutlet weak var vehicleTypeLabel: UILabel!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var customerTitleView: UIView!
    @IBOutlet weak var vehicleTitleView: UIView!
    @IBOutlet weak var serviceTitleView: UIView!
    @IBOutlet weak var customerContaintView: UIView!
    @IBOutlet weak var vehicleContaintView: UIView!
    @IBOutlet weak var serviceContaintView: UIView!
    @IBOutlet weak var customerStatic:UILabel!
    @IBOutlet weak var customerDetailStatic:UILabel!
    @IBOutlet weak var vehicleStatic:UILabel!
    @IBOutlet weak var vehicleDetailStatic:UILabel!
    @IBOutlet weak var serviceTotalInTitle:UILabel!
    @IBOutlet weak var serviceTotalStaticInTitle:UILabel!
    @IBOutlet weak var vehicleSelectedInTitleLable: UILabel!
    @IBOutlet weak var serviceStatic:UILabel!
    @IBOutlet weak var serviceDetailStatic:UILabel!
    @IBOutlet weak var treatmentsListContaintView: UIView!
    @IBOutlet weak var partListContaintView: UIView!
    @IBOutlet weak var paymentSwitch: UISwitch!
    
    //MARK: Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // get db instance
        database = SharedClass.sharedInstance.database
        // get username & mobile list for auto complete
        setupViewAndQuery()
        // parse doc to get username & mobile list
        getUserListWithMoileNumber()
        // configure for auto complete & UI
        configureTextField()
        // handle text change & update auto complete list
        handleTextFieldInterfaces()
        // UI for selected parts & tratment
        self.dynamicConstraints()
        
        vehicleTypeLabel.text = "default"
        
        // check if existing document
        if (exsistingService != nil) {
            setupAndViewOldData()
        }
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if selectedVehicle != nil {
            manufNameTextField.text = selectedVehicle!["manuf"] as? String
            modelNameTextField.text = selectedVehicle!["model"] as? String
            registrationNumberTextField.text = selectedVehicle!["reg"] as? String
        }
        
        updateSelectedTreateatmentUI()
        updateSelectedPartUI()
        
        if selectedVehicleType == nil {
            selectedVehicleType = "default"
        }
        vehicleTypeLabel.text = selectedVehicleType!
        vehicleSelectedInTitleLable.text = selectedVehicleType!.capitalizedString
        
        serviceTotalInTitle.text = String(getTotalCostForService())
        
    }
    
    deinit {
        if listsLiveQuery != nil {
            listsLiveQuery.removeObserver(self, forKeyPath: "rows")
            listsLiveQuery.stop()
        }
    }
    
    // MARK: - KVO
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if object as? NSObject == listsLiveQuery {
            
            getUserListWithMoileNumber()
            
        }
    }
    
    //MARK: Helper Methods
    func setupAndViewOldData() {
        
        guard let docID = (exsistingService?.docID)
            else {return}
        
        let retrDoc = SharedClass.sharedInstance.database?.documentWithID(docID)
        
        guard let docData = retrDoc?.properties
            else {return}
        
        guard let userData = docData["user"] as? [String:AnyObject]
            else{return}
        
        if let username = userData["name"] as? String {
            if username.lowercaseString != SharedClass.kAnonymous.lowercaseString {
                customerNameTextField.text = username
            }
        }
        
        if let mobile = userData["mobile"] as? Int {
            customerMobileNumberTextField.text = String(mobile)
        }
        
        guard let vechileID = exsistingService?.vehicleID
            else {return}
        
        vehicleData = userData["vehicles"] as? [String:AnyObject]
        
        guard let vehicleData = userData["vehicles"]?.valueForKey(vechileID) as? [String:AnyObject]
            else{return}
        
        selectedVehicle = vehicleData
        
        manufNameTextField.text = vehicleData["manuf"] as? String
        modelNameTextField.text = vehicleData["model"] as? String
        vehicleTypeLabel.text   = vehicleData["type"] as? String
        
        registrationNumberTextField.text = vehicleData["reg"] as? String
        
        guard let serviceID = exsistingService?.serviceId
            else {return}
        
        guard let serviceData = vehicleData["services"]?.valueForKey(serviceID) as? [String:AnyObject]
            else {return}
        
        if serviceData["partialpayment"] != nil {
            paymentSwitch.on = false
        }
        
        problemDict = serviceData["problems"] as? [String:AnyObject]
        partDict = serviceData["inventories"] as? [String:AnyObject]
        selectedVehicleType = vehicleData["type"] as? String
        
    }
    
    func dynamicConstraints() {
        
        heightConstraintCustomerView = NSLayoutConstraint(item: customerContaintView, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: 16)
        
        heightConstraintVehicleView = NSLayoutConstraint(item: vehicleContaintView, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: 16)
        vehicleContaintView.addConstraint(heightConstraintVehicleView!)
        vehicleTitleView.backgroundColor = UIColor.init(colorLiteralRed: 246/255.0, green: 246/255.0, blue: 246/255.0, alpha: 1.0)
        vehicleStatic.textColor = UIColor.init(colorLiteralRed: 0, green: 0, blue: 0, alpha: 0.7)
        vehicleDetailStatic.textColor = vehicleStatic.textColor
        vehicleSelectedInTitleLable.textColor = vehicleDetailStatic.textColor
        
        heightConstraintServiceView = NSLayoutConstraint(item: serviceContaintView, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: 16)
        serviceContaintView.hidden = true
        serviceContaintView.addConstraint(heightConstraintServiceView!)
        serviceTitleView.backgroundColor = UIColor.init(colorLiteralRed: 246/255.0, green: 246/255.0, blue: 246/255.0, alpha: 1.0)
        serviceStatic.textColor = vehicleStatic.textColor
        serviceDetailStatic.textColor = vehicleStatic.textColor
        serviceTotalInTitle.textColor = serviceStatic.textColor
        serviceTotalStaticInTitle.textColor = serviceDetailStatic.textColor
    }
    
    func addNewServiceInDoc(documentID:String) -> Bool {
    
        var retrDoc = SharedClass.sharedInstance.database?.documentWithID(documentID)
        
        guard var docData = (retrDoc?.properties)
        else {
            SharedClass.alertView("Error!!", strMessage: "Something went wrong, please try again")
            return false
        }
        
        let paymentStatus = paymentSwitch.on ? "paid" : "due"
        var serviceProperty:[String:AnyObject] = ["date":NSDate().toString(format: "yyyy-MM-dd'T'HH:mm:ssXXXXX"),"state":"Bill","status":paymentStatus,"cost" : Float32(serviceTotalInTitle.text!)!]
        
        if let latInvoiceNumber = getLastInvoiceNumber() {
            serviceProperty["invoiceno"] = latInvoiceNumber+1
        }
        
        if !paymentSwitch.on {
            serviceProperty["partialpayment"] =  ["total":0]
        }
        
        if problemDict != nil {
            serviceProperty["problems"] = problemDict!
        }
        
        if partDict != nil {
            serviceProperty["inventories"] = partDict!
        }
        
        let serviceKey = "srvc-" + SharedClass.timeBasedUUID()
        let servicesDict = [serviceKey:serviceProperty]
        
        if var vehiclesDict = docData["user"]?.valueForKey("vehicles") as? [String:AnyObject]{
            
            // check vehicle is same or not
            var vehicleFound:[String:AnyObject]? = nil
            var vehicleFoundKey:String?
            for vehicleKey in vehiclesDict.keys {
                
                // manuf
                if !((manufNameTextField.text?.isEmpty)!), let vehileManuf = (vehiclesDict[vehicleKey]?.valueForKey("manuf") as? String) {
                    
                    if vehileManuf.lowercaseString != manufNameTextField.text?.lowercaseString {continue}
                }
                
                // model
                if !((modelNameTextField.text?.isEmpty)!), let vehicleModel = (vehiclesDict[vehicleKey]?.valueForKey("model") as? String) {
                    
                    if vehicleModel.lowercaseString != modelNameTextField.text?.lowercaseString {continue}
                }
                
                // register number
                if !((registrationNumberTextField.text?.isEmpty)!), let vehicleReg = (vehiclesDict[vehicleKey]?.valueForKey("reg") as? String) {
                    
                    if vehicleReg.lowercaseString != registrationNumberTextField.text?.lowercaseString {continue}
                }
                vehicleFoundKey = vehicleKey
                vehicleFound = vehiclesDict[vehicleKey] as? [String:AnyObject]
                break
                
            }
            
            if vehicleFound != nil {
                // vehicle is same only new service
                
                // get existing service
                var services = vehicleFound!["services"] as? [String:AnyObject]
                // add new service
                services?.update(servicesDict)
                // update document
                
                var userData = docData["user"] as! [String:AnyObject]
                var vehiclesData = userData["vehicles"] as! [String:AnyObject]
                var serviceData = vehiclesData[vehicleFoundKey!] as! [String:AnyObject]
                serviceData["services"] = services
                // check if name changed then delete doc and create new
                let oldUserName = userData["name"] as! String
                var newUserName = customerNameTextField.text!
                if oldUserName.lowercaseString != newUserName.lowercaseString {
                    docData["_deleted"] = true
                    do {
                        try retrDoc?.putProperties(docData)
                    } catch _ as NSError { /* do nothing */ }
                    
                    // create new docId
                    newUserName = SharedClass.kAnonymous
                    if let userName = customerNameTextField?.text {
                        if userName != "" { newUserName = userName}
                    }
                    let documentID = "usr-\(newUserName.lowercaseString)-\(SharedClass.timeBasedUUID())"
                    docData.removeValueForKey("_deleted")
                    docData.removeValueForKey("_rev")
                    docData.removeValueForKey("_revisions")
                    docData["_id"] = documentID
                    retrDoc = SharedClass.sharedInstance.database?.documentWithID(documentID)
                }
                vehiclesData[vehicleFoundKey!] = serviceData
                userData["vehicles"] = vehiclesData
                userData["name"] = newUserName
                docData["user"] = userData
                
            } else {
                // new vehicle & new service
                let newVehicleKey = "vhcl-" + SharedClass.timeBasedUUID()
                let vehicleProperty = [newVehicleKey:["reg":registrationNumberTextField.text!,"manuf":manufNameTextField.text!,"model":modelNameTextField.text!,"type":vehicleTypeLabel.text!,"services":servicesDict]]
                // add new vehicle in exsiting vehicle list
                vehiclesDict.update(vehicleProperty)
                // check if name changed then delete doc and create new
                var userData = docData["user"] as! [String:AnyObject]
                let oldUserName = userData["name"] as! String
                var newUserName = customerNameTextField.text!
                if oldUserName.lowercaseString != newUserName.lowercaseString {
                    docData["_deleted"] = true
                    do {
                        try retrDoc?.putProperties(docData)
                    } catch _ as NSError { /* do nothing */ }
                    
                    // create new docId
                    newUserName = SharedClass.kAnonymous
                    if let userName = customerNameTextField?.text {
                        if userName != "" { newUserName = userName}
                    }
                    let documentID = "usr-\(newUserName.lowercaseString)-\(SharedClass.timeBasedUUID())"
                    docData.removeValueForKey("_deleted")
                    docData.removeValueForKey("_rev")
                    docData.removeValueForKey("_revisions")
                    docData["_id"] = documentID
                    retrDoc = SharedClass.sharedInstance.database?.documentWithID(documentID)
                }
                
                userData["vehicles"] = vehiclesDict
                userData["name"] = newUserName
                docData["user"] = userData
            }
        
        } else {
            // no vehicle then add vehice & service
            let newVehicleKey = "vhcl-" + SharedClass.timeBasedUUID()
            let vehicleProperty = [newVehicleKey:["reg":registrationNumberTextField.text!,"manuf":manufNameTextField.text!,"model":modelNameTextField.text!,"type":vehicleTypeLabel.text!,"services":servicesDict]]
        
            var userData = docData["user"] as! [String:AnyObject]
            // check if name changed then delete doc and create new
            let oldUserName = userData["name"] as! String
            var newUserName = customerNameTextField.text!
            if oldUserName.lowercaseString != newUserName.lowercaseString {
                docData["_deleted"] = true
                do {
                    try retrDoc?.putProperties(docData)
                } catch _ as NSError { /* do nothing */ }
                
                // create new docId
                newUserName = SharedClass.kAnonymous
                if let userName = customerNameTextField?.text {
                    if userName != "" { newUserName = userName}
                }
                let documentID = "usr-\(newUserName.lowercaseString)-\(SharedClass.timeBasedUUID())"
                docData.removeValueForKey("_deleted")
                docData.removeValueForKey("_rev")
                docData.removeValueForKey("_revisions")
                docData["_id"] = documentID
                retrDoc = SharedClass.sharedInstance.database?.documentWithID(documentID)
            }
            userData["vehicles"] = vehicleProperty
            userData["name"] = newUserName
            docData["user"] = userData
            
        }
        
        do {
            try retrDoc?.putProperties(docData)
            updateInvoiceNumberbyOne()
        } catch let error as NSError {
            SharedClass.alertView("Error!!", strMessage: error.localizedDescription)
            return false
        }
        
        return true
    }
    
    func updateService(documentID:String) -> Bool {
    
        var retrDoc = SharedClass.sharedInstance.database?.documentWithID(documentID)
        
        guard var docData = retrDoc?.properties else {
            SharedClass.alertView("Error!!", strMessage: "Something went wrong. Please try again")
            return false
        }
        
        guard let serviceKey = exsistingService?.serviceId else {
            SharedClass.alertView("Error!!", strMessage: "Something went wrong. Please try again")
            return false
        }
        guard let vehicleKey = exsistingService?.vehicleID else {
            SharedClass.alertView("Error!!", strMessage: "Something went wrong. Please try again")
            return false
        }
        guard let vehiclesDict = docData["user"]?.valueForKey("vehicles") as? [String:AnyObject] else {
            SharedClass.alertView("Error!!", strMessage: "Something went wrong. Please try again")
            return false
        }
        guard var vehicleFound = vehiclesDict[vehicleKey] as? [String:AnyObject] else {
            SharedClass.alertView("Error!!", strMessage: "Something went wrong. Please try again")
            return false
        }

        // get existing service list
        guard var services = vehicleFound["services"] as? [String:AnyObject] else {
            SharedClass.alertView("Error!!", strMessage: "Something went wrong. Please try again")
            return false
        }
        
        // get sevice
        guard var serviceProperty = services[serviceKey] as? [String:AnyObject] else {
            SharedClass.alertView("Error!!", strMessage: "Something went wrong. Please try again")
            return false
        }
        
        serviceProperty["date"] = NSDate().toString(format: "yyyy-MM-dd'T'HH:mm:ssXXXXX")
        let paymentStatus = paymentSwitch.on ? "paid" : "due"
        serviceProperty["status"] = paymentStatus
        serviceProperty["cost"] = Float32(serviceTotalInTitle.text!)!
        
        if !paymentSwitch.on {
            serviceProperty["partialpayment"] =  ["total":0]
        } else {
            serviceProperty.removeValueForKey("partialpayment")
        }
        
        if problemDict != nil {
            serviceProperty["problems"] = problemDict!
        }
        
        if partDict != nil {
            serviceProperty["inventories"] = partDict!
        }
        
        services[serviceKey] = serviceProperty
     
        // update document
        var userData = docData["user"] as! [String:AnyObject]
        // check if name changed then delete doc and create new
        let oldUserName = userData["name"] as! String
        var newUserName = customerNameTextField.text!
        if oldUserName.lowercaseString != newUserName.lowercaseString {
            docData["_deleted"] = true
            do {
                try retrDoc?.putProperties(docData)
            } catch _ as NSError { /* do nothing */ }
            
            // create new docId
            newUserName = SharedClass.kAnonymous
            if let userName = customerNameTextField?.text {
                if userName != "" { newUserName = userName}
            }
            let documentID = "usr-\(newUserName.lowercaseString)-\(SharedClass.timeBasedUUID())"
            docData.removeValueForKey("_deleted")
            docData.removeValueForKey("_rev")
            docData.removeValueForKey("_revisions")
            docData["_id"] = documentID
            retrDoc = SharedClass.sharedInstance.database?.documentWithID(documentID)
        }
        
        var vehiclesData = userData["vehicles"] as! [String:AnyObject]
        var vehicleInfo = vehiclesData[vehicleKey] as! [String:AnyObject]
        vehicleInfo["services"] = services
        vehicleInfo["reg"] = registrationNumberTextField.text!
        vehicleInfo["manuf"] = manufNameTextField.text!
        vehicleInfo["model"] = modelNameTextField.text!
        vehicleInfo["type"] = vehicleTypeLabel.text!
        vehiclesData[vehicleKey] = vehicleInfo
        userData["vehicles"] = vehiclesData
        userData["mobile"] = Int(customerMobileNumberTextField.text!)!
        userData["name"] = newUserName
        docData["user"] = userData
        
        do {
            try retrDoc?.putProperties(docData)
        } catch let error as NSError {
            SharedClass.alertView("Error!!", strMessage: error.localizedDescription)
            return false
        }
        
        return true
    }
    
    func addServiceInNewDoc(documentID:String) -> Bool {
    
        var docData : [String:AnyObject] = [:]
        
        let retrDoc = SharedClass.sharedInstance.database?.documentWithID(documentID)
        
        if let tempDataDict = (retrDoc?.properties) {
            docData = tempDataDict
        } else {
            docData["creator"] = SharedClass.sharedInstance.pref!.username
            docData["channel"] = SharedClass.sharedInstance.pref!.channel
        }
        
        let paymentStatus = paymentSwitch.on ? "paid" : "due"
        var serviceProperty:[String:AnyObject] = ["date":NSDate().toString(format: "yyyy-MM-dd'T'HH:mm:ssXXXXX"),"state":"Bill","status":paymentStatus,"cost" : Float32(serviceTotalInTitle.text!)!]
        
        if let latInvoiceNumber = getLastInvoiceNumber() {
            serviceProperty["invoiceno"] = latInvoiceNumber+1
        }
        
        if !paymentSwitch.on {
            serviceProperty["partialpayment"] =  ["total":0]
        }
        
        if problemDict != nil {
            serviceProperty["problems"] = problemDict!
        }
        
        if partDict != nil {
            serviceProperty["inventories"] = partDict!
        }
        
        let newServiceKey = "srvc-" + SharedClass.timeBasedUUID()
        let servicesDict = [newServiceKey:serviceProperty]
        
        let newVehicleKey = "vhcl-" + SharedClass.timeBasedUUID()
        let vehicleProperty = [newVehicleKey:["reg":registrationNumberTextField.text!,"manuf":manufNameTextField.text!,"model":modelNameTextField.text!,"type":vehicleTypeLabel.text!,"services":servicesDict]]
        
        var newUserName = SharedClass.kAnonymous
        if let userName = customerNameTextField?.text {
            if userName != "" { newUserName = userName}
        }
        
        var userData:[String:AnyObject] = ["name":newUserName,"vehicles":vehicleProperty]
        userData["mobile"] = Int(customerMobileNumberTextField.text!)!
        
        docData["user"] = userData
        
        do {
            try retrDoc?.putProperties(docData)
            updateInvoiceNumberbyOne()
        } catch let error as NSError {
            SharedClass.alertView("Error!!", strMessage: error.localizedDescription)
            return false
        }
        
        return true
    }
    
    func saveServiceInDB() -> Bool {
        
        // if existing service then get existing doc and update
        if exsistingService != nil, let docID = (exsistingService?.docID)  {
            
            if exsistingService!.userMobile != Int(customerMobileNumberTextField.text!) {
                // check new number exist in docs
                let (status,_) = isMobileNumerExist()
                if status == .Found {
                    // show error
                    SharedClass.alertView("Error!!", strMessage: "Updated mobile number linked to another customer, Please double check mobile number")
                    return false
                }
            }
            
            // update existing service in existing doc
            return updateService(docID)
            
        } else {
            
            /// new service
            // check user exist
            let (status,docId) = isMobileNumerExist()
            
            if status == .Found {
                //Add new service in same doc
                return addNewServiceInDoc(docId!)
            } else {
                // new service in new doc
                // create docId
                var newUserName = SharedClass.kAnonymous
                if let userName = customerNameTextField?.text {
                    if userName != "" { newUserName = userName}
                }
                let documentID = "usr-\(newUserName.lowercaseString)-\(SharedClass.timeBasedUUID())"
                return addServiceInNewDoc(documentID)
            }
            
        }
        
    }
    
    func noTreatmentUI() {
        
        let marging = 16
        
        let serviceTreatments = UILabel()
        serviceTreatments.textColor = UIColor.blackColor().colorWithAlphaComponent(0.5)
        serviceTreatments.font = UIFont.systemFontOfSize(15.0)
        serviceTreatments.text = "N/A"
        treatmentsListContaintView.addSubview(serviceTreatments)
        
        serviceTreatments.snp_makeConstraints { make in
            
            make.top.equalTo(treatmentsListContaintView).inset(marging)
            make.bottom.equalTo(treatmentsListContaintView).inset(marging)
            make.right.equalTo(treatmentsListContaintView).inset(marging)
            make.left.equalTo(treatmentsListContaintView).inset(marging)
        }
        
    }
    
    func updateSelectedTreateatmentUI() {
        
        for item in treatmentsListContaintView.subviews {
            item.removeFromSuperview()
        }
        
        let marging = 8
        
        guard let totalItems = problemDict?.count else {
            noTreatmentUI()
            return
        }
        
        if totalItems == 0 {
            noTreatmentUI()
            return
        }
        
        var previousLable:UILabel? = nil
        var itemNumber = 0
        for key in problemDict!.keys {
            
            let serviceTreatments = UILabel()
            //serviceTreatments.numberOfLines = 0
            serviceTreatments.textColor = UIColor.blackColor().colorWithAlphaComponent(0.7)
            serviceTreatments.font = UIFont.systemFontOfSize(15.0)
            serviceTreatments.text = "◦ \(key.capitalizedString)"
            treatmentsListContaintView.addSubview(serviceTreatments)
            
            let serviceTreatmentPrice = UILabel()
            //serviceTreatmentPrice.backgroundColor = UIColor.blueColor()
            serviceTreatmentPrice.text = "\((String(problemDict![key]!.valueForKey("rate")!).capitalizedString)) Rs"
            serviceTreatmentPrice.setContentHuggingPriority(1000, forAxis: .Horizontal)
            serviceTreatmentPrice.setContentCompressionResistancePriority(1000, forAxis: .Horizontal)
            
            serviceTreatmentPrice.textAlignment = .Right
            treatmentsListContaintView.addSubview(serviceTreatmentPrice)
            
            
            if itemNumber == 0 {
                
                serviceTreatments.snp_makeConstraints { make in
                    
                    make.top.equalTo(treatmentsListContaintView).inset(marging)
                    if totalItems == 1 {
                        make.bottom.equalTo(treatmentsListContaintView).inset(marging)
                    }
                    make.left.equalTo(treatmentsListContaintView).inset(marging)
                }
                
                previousLable = serviceTreatments
                
            } else if itemNumber == totalItems-1 {
                
                serviceTreatments.snp_makeConstraints{ make in
                    make.top.equalTo(previousLable!.snp_bottom).offset(marging)
                    make.bottom.equalTo(treatmentsListContaintView).inset(marging)
                    make.left.equalTo(previousLable!.snp_left)
                    //make.right.equalTo(previousLable!.snp_right)
                }
                
            } else {
                
                serviceTreatments.snp_makeConstraints{ make in
                    make.top.equalTo(previousLable!.snp_bottom).offset(marging)
                    make.left.equalTo(previousLable!.snp_left)
                    //make.right.equalTo(previousLable!.snp_right)
                }
                
                previousLable = serviceTreatments
            }
            
            serviceTreatmentPrice.snp_makeConstraints { make in
                
                make.top.equalTo(serviceTreatments.snp_top)
                make.right.equalTo(treatmentsListContaintView).inset(marging)
                make.left.equalTo(serviceTreatments.snp_right).offset(marging)
                //make.width.equalTo(50)
            }
            itemNumber += 1
        }
        
    }
    
    func noPartsUI() {
        let marging = 16
        let partLabel = UILabel()
        partLabel.textColor = UIColor.blackColor().colorWithAlphaComponent(0.5)
        partLabel.font = UIFont.systemFontOfSize(15.0)
        partLabel.text = "N/A"
        partListContaintView.addSubview(partLabel)
        partLabel.snp_makeConstraints { make in
            make.top.equalTo(partListContaintView).inset(marging)
            make.bottom.equalTo(partListContaintView).inset(marging)
            make.right.equalTo(partListContaintView).inset (marging)
            make.left.equalTo(partListContaintView).inset(marging)
        }
    }
    
    func updateSelectedPartUI() {
        // serviceParts.text = "◦ Tyres\n\n◦ Headlights"
        for item in partListContaintView.subviews {
            item.removeFromSuperview()
        }
        guard let totalItems = partDict?.count else {
            noPartsUI()
            return
        }
        if totalItems == 0 {
            noPartsUI()
            return
        }
        let marging = 8
        var previousLable:UILabel? = nil
        var itemNumber = 0
        for key in partDict!.keys {
            
            let serviceParts = UILabel()
            //serviceTreatments.numberOfLines = 0
            serviceParts.textColor = UIColor.blackColor().colorWithAlphaComponent(0.7)
            serviceParts.font = UIFont.systemFontOfSize(15.0)
            serviceParts.text = "◦ \(key.capitalizedString)"
            partListContaintView.addSubview(serviceParts)
            
            let partPriceLabel = UILabel()
            //serviceTreatmentPrice.backgroundColor = UIColor.blueColor()
            partPriceLabel.text = "\((String(partDict![key]!.valueForKey("rate")!).capitalizedString)) Rs"
            partPriceLabel.setContentHuggingPriority(1000, forAxis: .Horizontal)
            partPriceLabel.setContentCompressionResistancePriority (1000, forAxis: .Horizontal)
            partPriceLabel.textAlignment = .Right
            partListContaintView.addSubview(partPriceLabel)
            
            if itemNumber == 0 {
                serviceParts.snp_makeConstraints { make in
                    make.top.equalTo(partListContaintView).inset(marging)
                    if totalItems == 1 {
                        make.bottom.equalTo(partListContaintView).inset(marging)
                    }
                    make.left.equalTo(partListContaintView).inset(marging)
                }
                previousLable = serviceParts
                
            } else if itemNumber == totalItems-1 {
                serviceParts.snp_makeConstraints{ make in
                    make.top.equalTo(previousLable!.snp_bottom).offset(marging)
                    make.bottom.equalTo(partListContaintView).inset(marging)
                    make.left.equalTo(previousLable!.snp_left)
                    //make.right.equalTo(previousLable!.snp_right)
                }
                
            } else {
                
                serviceParts.snp_makeConstraints{ make in
                    make.top.equalTo(previousLable!.snp_bottom).offset(marging)
                    make.left.equalTo(previousLable!.snp_left)
                    //make.right.equalTo(previousLable!.snp_right)
                }
                
                previousLable = serviceParts
            }
            
            partPriceLabel.snp_makeConstraints { make in
                
                make.top.equalTo(serviceParts.snp_top)
                make.right.equalTo(partListContaintView).inset(marging)
                make.left.equalTo(serviceParts.snp_right).offset(marging)
                //make.width.equalTo(50)
            }
            itemNumber += 1
        }
        
    }
    
    func getTotalCostForService() -> Float32 {
        
        // get total amount by problem cost + part cost
        var totalAmmount:Float32 = 0.0
        
        if problemDict != nil {
            
            for problemKey in problemDict!.keys {
                
                if let problem = problemDict![problemKey] as? [String:Float32] {
                    
                    totalAmmount = totalAmmount + problem["rate"]!
                }
                
            }
        }
        
        if partDict != nil {
            
            for partKey in partDict!.keys {
                
                if let part = partDict![partKey] as? [String:Float32] {
                    
                    totalAmmount = totalAmmount + part["rate"]!
                }
                
            }
        }
        
        return totalAmmount
        
    }
    
    func getUserListWithMoileNumber() {
        
        userNameList = []
        userMobileList = [:]
        
        guard let userList = listsLiveQuery.rows?.allObjects as? [CBLQueryRow] ?? nil else {
            return
        }
        
        for userDoc in userList {
            
            //let doc = userDoc.document!
            guard let user = userDoc.document?["user"] as? [String:AnyObject]
                else {continue}
            
            if let name = user["name"] as? String, let number = user["mobile"] as? Int {
                
                userNameList.append(name)
                userMobileList[name] = number
            }
            
        }
        
    }
    
    func isMobileNumerExist() -> (CheckMobileNumberStatus,String?) {
        
        guard let mobileNumber = Int((customerMobileNumberTextField?.text)!) else {
            SharedClass.alertView("Error", strMessage: "Invalid mobile number, please try again!!")
            return (.Error,nil)
        }
        
        guard let userList = listsLiveQuery.rows?.allObjects as? [CBLQueryRow] ?? nil else {
            return (.NotFound,nil)
        }
        
        for userDoc in userList {
            
            let doc = userDoc.document!
            guard let user = userDoc.document?["user"] as? [String:AnyObject]
                else {continue}
            
            if let number = user["mobile"] as? Int {
                if number == mobileNumber {
                    return (.Found,doc["_id"] as? String)
                }
            }
            
        }
        
        return (.NotFound,nil)
    }
    
    func validation () -> Bool {
        
        if customerMobileNumberTextField.text!.isEmpty {
            SharedClass.alertView("", strMessage: "Please enter mobile number")
            return false
        }
        
//        if customerNameTextField.text!.isEmpty {
//            SharedClass.alertView("", strMessage: "Please enter name")
//            return false
//        }
//        
        return true
        
    }
    
    func setupViewAndQuery() {
        
        let listsView = database.viewNamed("automint/userName_mobile")
        
        if listsView.mapBlock == nil {
            listsView.setMapBlock({ (doc, emit) in
                if let name = doc["user"]?.valueForKey("name") as? String,
                    let mobile = doc["user"]?.valueForKey("mobile") as? Int,
                    let _id: String = doc["_id"] as? String
                    where (_id != SharedClass.sharedInstance.kTrementDocId!) && (_id != SharedClass.sharedInstance.kInventoryDocId!) {
                    
                    var _deleted = false
                    if let _deletedTemp = doc["_deleted"] as? Bool {
                        _deleted = _deletedTemp
                    }
                    
                    if !_deleted {
                        emit([_id,name,mobile],nil)
                    }
                    
                }
                }, version: "3.0")
        }
        
        listsLiveQuery = listsView.createQuery().asLiveQuery()
        listsLiveQuery.prefetch = false
        listsLiveQuery.addObserver(self, forKeyPath: "rows", options: .New, context: nil)
        listsLiveQuery.start()
        
    }
    
    private func configureTextField(){
        customerNameTextField.autoCompleteTextColor = UIColor.darkGrayColor()
        customerNameTextField.autoCompleteTextFont = UIFont.systemFontOfSize(17.0)
        customerNameTextField.autoCompleteCellHeight = 40.0
        customerNameTextField.maximumAutoCompleteCount = 20
        customerNameTextField.hidesWhenSelected = true
        customerNameTextField.hidesWhenEmpty = true
        customerNameTextField.enableAttributedText = false
        customerNameTextField.clearButtonMode = .Never
        var attributes = [String:AnyObject]()
        attributes[NSForegroundColorAttributeName] = UIColor.blackColor()
        attributes[NSFontAttributeName] = UIFont.systemFontOfSize(15.0)
        customerNameTextField.autoCompleteAttributes = attributes
    }
    
    private func handleTextFieldInterfaces(){
        customerNameTextField.onTextChange = {[weak self] text in
            
            let nameArray = self?.userNameList.filter { $0.lowercaseString.hasPrefix(text.lowercaseString) }
            if nameArray?.count == 0 {
                self?.customerNameTextField.autoCompleteStrings = nil
            } else {
                self?.customerNameTextField.autoCompleteStrings = nameArray
            }
            
        }
        
        customerNameTextField.onSelect = {[weak self] text, indexpath in
            
            print(text)
            
            if indexpath.row < self!.userMobileList.count {
                
                if self!.userMobileList[text] != nil {
                    self?.customerMobileNumberTextField.text = String(self!.userMobileList[text]!)
                }
                
            }
        }
    }

    // get last invoice number form setting document
    func getLastInvoiceNumber() -> Int? {
        
        // retrieve the document from the database
        guard let retrievedDoc = SharedClass.sharedInstance.database?.documentWithID(SharedClass.sharedInstance.kSettingDocId!)
        else { return nil }
        
        guard let settings = retrievedDoc.properties?["settings"] as? [String:AnyObject]
        else { return nil }
        
        guard let invoices = settings["invoices"] as? [String:AnyObject]
        else { return nil }
        
        return invoices["lastInvoiceNo"] as? Int
        
    }
    
    // add +1 & write new invoice number back to setting doc
    func updateInvoiceNumberbyOne() -> Bool {
        
        // retrieve the document from the database
        guard let retrievedDoc = SharedClass.sharedInstance.database?.documentWithID(SharedClass.sharedInstance.kSettingDocId!)
            else { return false }
        
        guard var settings = retrievedDoc.properties?["settings"] as? [String:AnyObject]
            else { return false }
        
        guard var invoices = settings["invoices"] as? [String:AnyObject]
            else { return false }
        
        guard let lastInvoiceNumber = invoices["lastInvoiceNo"] as? Int
            else { return false }
        
        invoices["lastInvoiceNo"] = lastInvoiceNumber + 1
        settings["invoices"] = invoices
        
        var docData = retrievedDoc.properties
        docData!["settings"] = settings
        
        do {
            try retrievedDoc.putProperties(docData!)
        } catch let error as NSError {
            print(error.localizedDescription)
            return false
        }
        
        return true
    }
    
    func checkMobileNumerAndUpdateData() {
        
        mobilenumberChecked = customerMobileNumberTextField.text!
        
        MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        
        
        let (status,docId) = isMobileNumerExist()
        
        if status == .Found {
            let retrDoc = SharedClass.sharedInstance.database?.documentWithID(docId!)
            
            guard let docData = retrDoc!.properties else {
                MBProgressHUD.hideHUDForView(self.view, animated: true)
                return
            }
            guard let userData = docData["user"] as? [String:AnyObject] else {
                MBProgressHUD.hideHUDForView(self.view, animated: true)
                return
            }
            if let username = userData["name"] as? String {
                if username.lowercaseString != SharedClass.kAnonymous.lowercaseString {
                    customerNameTextField.text = username
                }
            }
            guard let (_,vehicleValue) = (userData["vehicles"] as? [String:AnyObject])?.first else {
                MBProgressHUD.hideHUDForView(self.view, animated: true)
                return
            }
            guard let vehicle = vehicleValue as?  [String:AnyObject]
                else {
                    MBProgressHUD.hideHUDForView(self.view, animated: true)
                    return
            }
            manufNameTextField.text = vehicle["manuf"] as? String
            registrationNumberTextField.text = vehicle["reg"] as? String
            modelNameTextField.text = vehicle["model"] as? String
            
            vehicleData = userData["vehicles"] as? [String:AnyObject]
            selectedVehicle = vehicle
            if let selectedType = vehicle["type"] as? String{
                vehicleTypeLabel.text = selectedType
                selectedVehicleType = selectedType
            }
            
        }
        
        MBProgressHUD.hideHUDForView(self.view, animated: true)
    }
    
    //MARK: IBAction
    @IBAction func customerTitleTap(sender: AnyObject) {
    
        if currentSection == .Customer {
            currentSection = .none
            customerContaintView.addConstraint(heightConstraintCustomerView!)
            customerTitleView.backgroundColor = UIColor.init(colorLiteralRed: 246/255.0, green: 246/255.0, blue: 246/255.0, alpha: 1.0)
            customerStatic.textColor = UIColor.init(colorLiteralRed: 0, green: 0, blue: 0, alpha: 0.7)
            customerDetailStatic.textColor = customerStatic.textColor
            
        } else {
            
            currentSection = .Customer
            customerContaintView.removeConstraint(heightConstraintCustomerView!)
            vehicleContaintView.addConstraint(heightConstraintVehicleView!)
            serviceContaintView.hidden = true
            serviceContaintView.addConstraint(heightConstraintServiceView!)
            
            customerTitleView.backgroundColor = UIColor.init(colorLiteralRed: 239/255.0, green: 249/255.0, blue: 251/255.0, alpha: 1.0)
            customerStatic.textColor = UIColor.init(colorLiteralRed: 19/255.0, green: 93/255.0, blue: 177/255.0, alpha: 1.0)
            customerDetailStatic.textColor = UIColor.init(colorLiteralRed: 19/255.0, green: 93/255.0, blue: 177/255.0, alpha: 1.0)
            
            vehicleTitleView.backgroundColor = UIColor.init(colorLiteralRed: 246/255.0, green: 246/255.0, blue: 246/255.0, alpha: 1.0)
            vehicleStatic.textColor = UIColor.init(colorLiteralRed: 0, green: 0, blue: 0, alpha: 0.7)
            vehicleDetailStatic.textColor = UIColor.init(colorLiteralRed: 0, green: 0, blue: 0, alpha: 0.7)
            vehicleSelectedInTitleLable.textColor = UIColor.init(colorLiteralRed: 0, green: 0, blue: 0, alpha: 0.7)
            
            serviceTitleView.backgroundColor = UIColor.init(colorLiteralRed: 246/255.0, green: 246/255.0, blue: 246/255.0, alpha: 1.0)
            serviceStatic.textColor = UIColor.init(colorLiteralRed: 0, green: 0, blue: 0, alpha: 0.7)
            serviceDetailStatic.textColor = UIColor.init(colorLiteralRed: 0, green: 0, blue: 0, alpha: 0.7)
            serviceTotalInTitle.textColor = serviceStatic.textColor
            serviceTotalStaticInTitle.textColor = serviceDetailStatic.textColor
            
        }
    }
    
    @IBAction func VehicleTitleTap(sender: AnyObject) {
    
        if currentSection == .Vehicle {
            
            currentSection = .none
            vehicleContaintView.addConstraint(heightConstraintVehicleView!)
            vehicleTitleView.backgroundColor = customerTitleView.backgroundColor
            vehicleStatic.textColor = customerStatic.textColor
            vehicleDetailStatic.textColor = customerStatic.textColor
            vehicleSelectedInTitleLable.textColor = vehicleDetailStatic.textColor
            
        } else {
            
            currentSection = .Vehicle
            customerContaintView.addConstraint(heightConstraintCustomerView!)
            vehicleContaintView.removeConstraint (heightConstraintVehicleView!)
            serviceContaintView.hidden = true
            serviceContaintView.addConstraint(heightConstraintServiceView!)
            
            customerTitleView.backgroundColor = UIColor.init(colorLiteralRed: 246/255.0, green: 246/255.0, blue: 246/255.0, alpha: 1.0)
            customerStatic.textColor = UIColor.init(colorLiteralRed: 0, green: 0, blue: 0, alpha: 0.7)
            customerDetailStatic.textColor = customerStatic.textColor
            
            vehicleTitleView.backgroundColor = UIColor.init(colorLiteralRed: 239/255.0, green: 249/255.0, blue: 251/255.0, alpha: 1.0)
            vehicleStatic.textColor = UIColor.init(colorLiteralRed: 19/255.0, green: 93/255.0, blue: 177/255.0, alpha: 1.0)
            vehicleDetailStatic.textColor = UIColor.init(colorLiteralRed: 19/255.0, green: 93/255.0, blue: 177/255.0, alpha: 1.0)
            vehicleSelectedInTitleLable.textColor = vehicleDetailStatic.textColor
            
            serviceTitleView.backgroundColor = UIColor.init(colorLiteralRed: 246/255.0, green: 246/255.0, blue: 246/255.0, alpha: 1.0)
            serviceStatic.textColor = customerStatic.textColor
            serviceDetailStatic.textColor = customerStatic.textColor
            serviceTotalInTitle.textColor = serviceStatic.textColor
            serviceTotalStaticInTitle.textColor = serviceDetailStatic.textColor
            
            // check if new service then check for mobile number if exist then get first vehicle
            
            if exsistingService == nil && mobilenumberChecked != customerMobileNumberTextField.text! {
                
                checkMobileNumerAndUpdateData()
            }
        }
    }
    
    @IBAction func ServiceTitleTap(sender: AnyObject) {
    
        if currentSection == .Service {
            
            currentSection = .none
            serviceContaintView.hidden = true
            serviceContaintView.addConstraint(heightConstraintServiceView!)
            serviceTitleView.backgroundColor = UIColor.init(colorLiteralRed: 246/255.0, green: 246/255.0, blue: 246/255.0, alpha: 1.0)
            serviceStatic.textColor = UIColor.init(colorLiteralRed: 0, green: 0, blue: 0, alpha: 0.7)
            serviceDetailStatic.textColor = UIColor.init(colorLiteralRed: 0, green: 0, blue: 0, alpha: 0.7)
            serviceTotalInTitle.textColor = serviceStatic.textColor
            serviceTotalStaticInTitle.textColor = serviceDetailStatic.textColor
            
            
        } else {
            
            currentSection = .Service
            customerContaintView.addConstraint(heightConstraintCustomerView!)
            vehicleContaintView.addConstraint(heightConstraintVehicleView!)
            serviceContaintView.hidden = false
            serviceContaintView.removeConstraint(heightConstraintServiceView!)
            
            customerTitleView.backgroundColor = UIColor.init(colorLiteralRed: 246/255.0, green: 246/255.0, blue: 246/255.0, alpha: 1.0)
            customerStatic.textColor = UIColor.init(colorLiteralRed: 0, green: 0, blue: 0, alpha: 0.7)
            customerDetailStatic.textColor = customerStatic.textColor
            
            vehicleTitleView.backgroundColor = customerTitleView.backgroundColor
            vehicleStatic.textColor = customerStatic.textColor
            vehicleDetailStatic.textColor = customerStatic.textColor
            vehicleSelectedInTitleLable.textColor = vehicleDetailStatic.textColor
            
            serviceTitleView.backgroundColor = UIColor.init(colorLiteralRed: 239/255.0, green: 249/255.0, blue: 251/255.0, alpha: 1.0)
            serviceStatic.textColor = UIColor.init(colorLiteralRed: 19/255.0, green: 93/255.0, blue: 177/255.0, alpha: 1.0)
            serviceDetailStatic.textColor = serviceStatic.textColor
            serviceTotalInTitle.textColor = serviceStatic.textColor
            serviceTotalStaticInTitle.textColor = serviceDetailStatic.textColor
        }
    }
    
    @IBAction func backButtonClick(sender: AnyObject) {
        
        self.navigationController?.popViewControllerAnimated (true)
    }
    
    @IBAction func saveTap(sender: AnyObject) {
        
        if !validation() {
            MBProgressHUD.hideHUDForView(self.view, animated: true)
            return
        }
        
        MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        
        if saveServiceInDB() {
            self.navigationController?.popViewControllerAnimated(true)
        }
        MBProgressHUD.hideHUDForView(self.view, animated: true)
        
    }
    
    @IBAction func ChooseVehicleTypeClick(sender: AnyObject) {
        
        let chooseVehicleTypeVCObj = self.storyboard?.instantiateViewControllerWithIdentifier("ChooseVehicleTypeVC") as! ChooseVehicleTypeVC
        chooseVehicleTypeVCObj.selectedVehicleType = selectedVehicleType
        self.navigationController?.pushViewController(chooseVehicleTypeVCObj, animated: true)
    }
    
    
    @IBAction func ChooseVehicleClick(sender: AnyObject) {
    
        /*SharedClass.alertView("", strMessage: "Cooming Soon!!")
        return*/
        let chooseVehicleVCObj = self.storyboard?.instantiateViewControllerWithIdentifier("ChooseVehicleVC") as! ChooseVehicleVC
        chooseVehicleVCObj.vehicleData = vehicleData
        chooseVehicleVCObj.selectedVehicle = selectedVehicle
        self.navigationController?.pushViewController(chooseVehicleVCObj, animated: true)
    }
    
    @IBAction func SelectTreatmentsButtonClick(sender: AnyObject) {
        
        let chooseTreatmentVCObj = self.storyboard?.instantiateViewControllerWithIdentifier("ChooseTreatmentVC") as! ChooseTreatmentVC
        chooseTreatmentVCObj.problemDict = problemDict
        chooseTreatmentVCObj.selectedVehicleType = selectedVehicleType
        self.navigationController?.pushViewController(chooseTreatmentVCObj, animated: true)
    }
    
    
    @IBAction func SelectPartsButtonClick(sender: AnyObject) {
        
        let choosePartVCObj = self.storyboard?.instantiateViewControllerWithIdentifier("ChoosePartVC") as! ChoosePartVC
        choosePartVCObj.partDict = partDict
        self.navigationController?.pushViewController(choosePartVCObj, animated: true)
    }
    
    
    func tempDelteDoc() {
        
        do {
            
            let documentID = "usr-Jignesh-<__NSConcreteUUID 0x7fc5e2e32480> 19240514-7718-11E6-81A7-9801A799C1B1"
            try SharedClass.sharedInstance.database?.documentWithID(documentID)?.deleteDocument()
            
        } catch let error as NSError {
            
            print(error.localizedDescription)
            
        }
    }
    
    //MARK: UITextField
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        
        if string == "" {
            return true
        }
    
        if textField == customerMobileNumberTextField {
            
            if ((textField.text?.characters.count)! > 15  || (string.characters.count + (textField.text?.characters.count)!) > 15) && string != "" {
                return false
            }
            
            let regEx = "([0-9])"
            let match = string.rangeOfString(regEx, options: .RegularExpressionSearch)
            if (match == nil){ return false}
            
            return true
        
        }
        
        return true
        
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        if textField == customerMobileNumberTextField /*&& (customerNameTextField.text?.isEmpty)!*/ {
            
            // check & get user detail only for new service
            if exsistingService == nil && mobilenumberChecked != customerMobileNumberTextField.text! {
                checkMobileNumerAndUpdateData()
            }
        }
    }
}
