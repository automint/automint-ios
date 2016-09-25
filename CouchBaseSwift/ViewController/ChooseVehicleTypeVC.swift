//
//  ChooseVehicleTypeVC.swift
//  CouchBaseSwift
//
//  Created by Jignesh Patel on 01/09/16.
//  Copyright © 2016 Jignesh Patel. All rights reserved.
//

import UIKit

class ChooseVehicleTypeVC: UIViewController,UITableViewDataSource, UITableViewDelegate {

    var retrievedDoc : CBLDocument?
    var vehicleTypesArray = [String]()
    var selectedVehicleType : String?
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        setupTableView()
    
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Helper Methods
    
    // setup table view
    func setupTableView() {
        
        // register table cell
        tableView.registerNib(UINib.init(nibName: "LabelTextCell", bundle: nil), forCellReuseIdentifier: "LabelTextCell")
        
        // auto resize height
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44
        tableView.alwaysBounceVertical = true
        tableView.tableFooterView = UIView()
    
        //writedummyDocForSetting()
        retrieveVehicleTypes()
        
    }
    
    func writedummyDocForSetting() -> Bool {
        
        if let retrievedDocTemp = SharedClass.sharedInstance.database?.documentWithID(SharedClass.sharedInstance.kSettingDocId!) {
            
            retrievedDoc = retrievedDocTemp
            
            var docData : [String:AnyObject] = [:]
            if let docDataTemp = retrievedDoc?.properties {
                docData = docDataTemp
                docData["vehicletypes"] = ["default", "OTHER-TYPES"]
            } else {
                docData["creator"] = SharedClass.sharedInstance.pref!.username
                docData["channel"] = SharedClass.sharedInstance.pref!.channel
                docData["vehicletypes"] = ["default", "OTHER-TYPES"]
            }
            
            do {
                
                try retrievedDoc?.putProperties(docData)
                
            } catch let error as NSError {
                
                print(error.localizedDescription)
                
                return false
            }
            
            return true
        }
        
        return false
        
    }
    
    // retrieves the parts
    func retrieveVehicleTypes() -> Bool {
        
        // retrieve the document from the database
        if let retrievedDocTemp = SharedClass.sharedInstance.database?.documentWithID(SharedClass.sharedInstance.kSettingDocId!) {
            
            retrievedDoc = retrievedDocTemp
            
            if let typesArray = retrievedDoc?.properties?["vehicletypes"] as? [String] {
                vehicleTypesArray = typesArray
            } else {
                writedummyDocForSetting()
            }
            
            tableView.reloadData()
            
        } else {
            
            writedummyDocForSetting()
            
            return false
        }
        
        return true
        
    }
    
    //MARK: TableView methods
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return vehicleTypesArray.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell:LabelTextCell = tableView.dequeueReusableCellWithIdentifier("LabelTextCell") as! LabelTextCell
        
        let vehicleType = vehicleTypesArray[indexPath.row]
        if selectedVehicleType != nil && selectedVehicleType == vehicleType {
            tableView.selectRowAtIndexPath(indexPath, animated: false, scrollPosition: UITableViewScrollPosition.None)
        }
        cell.nameLabel.text = vehicleType
        cell.valueTextFieldWidth.constant = 0
        
        let bgColorView = UIView()
        bgColorView.backgroundColor = UIColor.init(red: 225/255.0, green: 235/255.0, blue: 248/255.0, alpha: 1)
        cell.selectedBackgroundView = bgColorView
        
        return cell
        
    }
    
    //MARK: Action
    
    @IBAction func backButtonClick(sender: AnyObject) {
        
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func doneButtonClick(sender: AnyObject) {
        
        var selectedVehicleType:String?
        
        if let selectedindex = tableView.indexPathForSelectedRow {
            selectedVehicleType = vehicleTypesArray[selectedindex.row]
        }

        let addSesrviceVCObj = self.navigationController?.viewControllers[(self.navigationController?.viewControllers.count)!-2] as! AddServiceVC
        addSesrviceVCObj.selectedVehicleType = selectedVehicleType
        self.navigationController?.popViewControllerAnimated(true)
        
    }
}

