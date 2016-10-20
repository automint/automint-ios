//
//  AllServiceVC.swift
//  CouchBaseSwift
//
//  Created by Jignesh Patel on 10/09/16.
//  Copyright © 2016 Jignesh Patel. All rights reserved.
//


class AllServiceVC: UIViewController,UITableViewDelegate,UISearchBarDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    var searchActive : Bool = false
    var filtered:[VehicleService] = []
    
    var username: String!
    var database: CBLDatabase!
    
    var listsLiveQuery: CBLLiveQuery!
    //var listRows : [CBLQueryRow]?
    var serviceList : [VehicleService]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup SearchController:
        searchBar.delegate = self
        
        // get db instance
        database = SharedClass.sharedInstance.database
        
        // Setup view and query:
        setupViewAndQuery()
        
    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    
        //searchActive = false
        //tableView.reloadData()
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
            reloadTaskLists()
        }
    }
    
    // MARK: - UITableViewController
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //return serviceList?.count ?? 0
        if(searchActive) {
            return filtered.count
        }
        return serviceList?.count ?? 0
    }
    
    func tableView(tableView: UITableView,
                   cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ServiceCell") as UITableViewCell!
        
        //let row = listRows![indexPath.row] as CBLQueryRow
        //print(row.documentProperties)
        let nameLabel = cell.viewWithTag(101) as! UILabel
        let vehicleLabel = cell.viewWithTag(102) as! UILabel
        let dateLabel = cell.viewWithTag(103) as! UILabel
        let totalCostLabel = cell.viewWithTag(104) as! UILabel
        
        
        //if let name = row.documentProperties?["user"]?.valueForKey("name") {
        var service = serviceList![indexPath.row] as VehicleService
        
        if(searchActive){
            service = filtered[indexPath.row] as VehicleService
        }
        
        nameLabel.text = service.userName
        vehicleLabel.text = service.vehicleName
        
        if let serviceDate:NSDate = service.date {
            dateLabel.text = serviceDate.toString(format: "dd MMM")
        } else {
            vehicleLabel.text = ""
        }
        if let cost = service.totalCost {
            totalCostLabel.text = String(cost)
        } else {
            totalCostLabel.text = ""
        }
        
        cell.selectionStyle = .None
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        var service = serviceList![indexPath.row] as VehicleService
        
        if(searchActive){
            service = filtered[indexPath.row] as VehicleService
        }
        
        let addServiceVCObj = self.storyboard?.instantiateViewControllerWithIdentifier("AddServiceVC") as! AddServiceVC
        addServiceVCObj.exsistingService = service
        self.navigationController?.pushViewController(addServiceVCObj, animated: true)
        
    }
    
    // MARK: - UISearchController
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        searchActive = true;
        searchBar.showsCancelButton = true
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        searchActive = false;
        searchBar.showsCancelButton = false
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.text = ""
        searchActive = false;
        searchBar.showsCancelButton = false
        searchBar.resignFirstResponder()
        self.tableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
    
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        
        searchActive = true
        
        if searchText.characters.count <= 0 {
            
            searchActive = false
            self.tableView.reloadData()
            return
        }
        
        filtered = (serviceList?.filter{ $0.userName.lowercaseString.hasPrefix(searchText.lowercaseString)})!
        
        /*if(filtered.count == 0){
            searchActive = false;
        } else {
            searchActive = true;
        }*/
        self.tableView.reloadData()
        
    }
    
    // MARK: - Database
    
    func setupViewAndQuery() {
        
        let listsView = database.viewNamed("automint/users")
        
        if listsView.mapBlock == nil {
            listsView.setMapBlock({ (doc, emit) in
                if let _id: String = doc["_id"] as? String
                    where (_id != SharedClass.sharedInstance.kTrementDocId!) && (_id != SharedClass.sharedInstance.kInventoryDocId!) {
                    
                    var _deleted = false
                    if let _deletedTemp = doc["_deleted"] as? Bool {
                        _deleted = _deletedTemp
                    }
                    
                    if !_deleted {
                        emit(_id, nil)
                    }
                    
                }
                }, version: "2.0")
        }
        
        listsLiveQuery = listsView.createQuery().asLiveQuery()
        listsLiveQuery.prefetch = true
        listsLiveQuery.addObserver(self, forKeyPath: "rows", options: .New, context: nil)
        listsLiveQuery.start()
        
    }
    
    func reloadTaskLists() {
        //listRows = listsLiveQuery.rows?.allObjects as? [CBLQueryRow] ?? nil
        
        if serviceList == nil {
            serviceList = [VehicleService]()
        }
        serviceList?.removeAll()
        
        guard let docList = listsLiveQuery.rows?.allObjects as? [CBLQueryRow]
            else {
                tableView.reloadData()
                return;
        }
        
        for row in docList {
            
            guard let docData = row.documentProperties,let vehiclesDict = docData["user"]?.valueForKey("vehicles") as? NSDictionary else {
                continue;
            }
            
            for vehicleKey in vehiclesDict.allKeys {
                
                guard let servicesDict = vehiclesDict.valueForKey(vehicleKey as! String)!.valueForKey("services") as? NSDictionary else{
                    continue;
                }
                
                for serviceKey in servicesDict.allKeys {
                    
                    guard let serviceDict = servicesDict.valueForKey(serviceKey as! String) as? NSDictionary else {
                        continue;
                    }
                    
                    let serviceData:VehicleService? = VehicleService()
                    serviceData!.userName = (docData["user"]?.valueForKey("name") as? String)!
                    
                    if serviceData!.userName.lowercaseString == SharedClass.kAnonymous.lowercaseString {
                        serviceData!.userName = ""
                    }
                    
                    if let mobileNumber = docData["user"]!.valueForKey("mobile") as? String {
                        if let mobileNumberInt = Int(mobileNumber) {
                            serviceData!.userMobile = mobileNumberInt
                        }
                    } else if let mobileNumber = docData["user"]!.valueForKey("mobile") as? Int {
                        serviceData!.userMobile = mobileNumber
                    }
                    
                    
                    serviceData!.docID = row.documentID!
                    serviceData!.vehicleID = vehicleKey as! String
                    serviceData!.serviceId = serviceKey as! String
                    
                    // manuf
                    if let vehileManuf = (vehiclesDict.valueForKey(vehicleKey as! String)?.valueForKey("manuf") as? String) {
                        
                        serviceData!.vehicleName = vehileManuf + " "
                    }
                    
                    // model
                    if let vehicleModel = (vehiclesDict.valueForKey(vehicleKey as! String)?.valueForKey("model") as? String) {
                        serviceData!.vehicleName = serviceData!.vehicleName + vehicleModel
                    }
                    
                    // get service date
                    if let serviceDate = NSDate(fromString: serviceDict.valueForKey("date") as! String, format: "yyyy-MM-dd'T'HH:mm:ssXXXXX") {
                        serviceData!.date = serviceDate
                    }
                    
                    if let cost = serviceDict.valueForKey("cost") as? String {
                        if let costFloatValue = Float32(cost) {
                            serviceData!.totalCost = costFloatValue
                        }
                    } else if let cost = serviceDict.valueForKey("cost") as? Float32 {
                        serviceData!.totalCost = cost
                    }
                    // get total amount by problem cost + part cost
                    /*var totalAmmount:Float32 = 0.0
                    if let problemsDict = serviceDict.valueForKey("problems") as? [String:AnyObject] {
                        
                        for problemKey in problemsDict.keys {
                            
                            if let problem = problemsDict[problemKey] as? [String:Float32] {
                                
                               totalAmmount = totalAmmount + problem["rate"]!
                            }
                            
                        }
                    }
                    
                    if let partsDict = serviceDict.valueForKey("inventories") as? [String:AnyObject] {
                        
                        for partKey in partsDict.keys {
                            
                            if let problem = partsDict[partKey] as? [String:Float32] {
                                
                                totalAmmount = totalAmmount + problem["rate"]!
                            }
                            
                        }
                    }
                    
                    serviceData!.totalCost = totalAmmount*/
                    
                    
                    serviceList?.append(serviceData!)
                    
                }
            }
        }
        
        // sort array by date
        serviceList!.sortInPlace(sortByDate)
        tableView.reloadData()
    }
    
    func sortByDate(s1: VehicleService, _ s2: VehicleService) -> Bool {
    
        return s1.date > s2.date
    }
    
    func createTaskList(name: String) -> CBLSavedRevision? {
        let properties = [
            "type": "task-list",
            "name": name
        ]
        let doc = database.createDocument()
        do {
            return try doc.putProperties(properties)
        } catch let error as NSError {
            
            print(error.localizedDescription)
            return nil
        }
    }
    
    func updateTaskList(list: CBLDocument, withName name: String) {
        do {
            try list.update { newRev in
                newRev["name"] = name
                return true
            }
        } catch let error as NSError {
            print(error.localizedDescription)
            
        }
    }
    
    func deleteTaskList(list: CBLDocument) {
        do {
            try list.deleteDocument()
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
    //MARK:- IBAction
    @IBAction func logoutClick(sender: AnyObject) {
        
        let pref = SharedClass.sharedInstance.pref
        
        if (pref != nil) {
            pref!.isLoggedIn = false
            pref!.save(SharedClass.kPrefFile)
        }
        
        self.navigationController?.popToRootViewControllerAnimated(true)
        
    }
    
}
