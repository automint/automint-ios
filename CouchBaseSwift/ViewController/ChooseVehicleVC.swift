//
//  ChooseVehicleVC.swift
//  CouchBaseSwift
//
//  Created by Jignesh Patel on 01/09/16.
//  Copyright © 2016 Jignesh Patel. All rights reserved.
//

import UIKit

class ChooseVehicleVC: UIViewController,UITableViewDataSource, UITableViewDelegate {

    var vehicleIdArray:[String]?
    var vehicleData : [String:AnyObject]?
    var selectedVehicle : [String:AnyObject]?
    var selectedVehicleKey : String?
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        if vehicleData != nil {
            vehicleIdArray = Array(vehicleData!.keys)
            
            // find selected key
            if selectedVehicle != nil && vehicleData != nil {
                
                for vehicleKey in vehicleData!.keys {
                    
                    // manuf
                    if let selectedVehiclevehicleManuf = selectedVehicle!["manuf"] as? String, let vehileManuf = (vehicleData![vehicleKey]?.valueForKey("manuf") as? String) {
                        
                        if vehileManuf.lowercaseString != selectedVehiclevehicleManuf.lowercaseString {continue}
                    }
                    
                    // model
                    if let selectedVehiclevehicleModel = selectedVehicle!["model"] as? String, let vehicleModel = (vehicleData![vehicleKey]?.valueForKey("model") as? String) {
                        
                        if vehicleModel.lowercaseString != selectedVehiclevehicleModel.lowercaseString {continue}
                    }
                    
                    // register number
                    if let selectedVehiclevehicleReg = selectedVehicle!["reg"] as? String, let vehicleReg = (vehicleData![vehicleKey]?.valueForKey("reg") as? String) {
                        
                        if vehicleReg.lowercaseString != selectedVehiclevehicleReg.lowercaseString {continue}
                    }
                    selectedVehicleKey = vehicleKey
                    
                    break
                    
                }
            }
            
            setupTableView()
        }
        
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
        
    }
    
    //MARK: TableView methods
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return vehicleIdArray?.count ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell:LabelTextCell = tableView.dequeueReusableCellWithIdentifier("LabelTextCell") as! LabelTextCell
        
        let vehicleKey = vehicleIdArray![indexPath.row]
        
        if selectedVehicleKey != nil && vehicleKey == selectedVehicleKey! {
            
            tableView.selectRowAtIndexPath(indexPath, animated: false, scrollPosition: UITableViewScrollPosition.None)
        }
        
        if let vehicleInfo = vehicleData![vehicleKey] as? [String:AnyObject] {
            
            var vehicleNameWithModel = ""
            // manuf
            if let manuf = vehicleInfo["manuf"] as? String {
                if manuf.characters.count > 0 {
                 vehicleNameWithModel = manuf + " "
                }
            }
            
            if let vehicleModel = vehicleInfo["model"] as? String {
                vehicleNameWithModel = vehicleNameWithModel + vehicleModel
            }
            
            cell.nameLabel.text = vehicleNameWithModel
            
            cell.valueTextFieldWidth.constant = 0
            
            let bgColorView = UIView()
            bgColorView.backgroundColor = UIColor.init(red: 225/255.0, green: 235/255.0, blue: 248/255.0, alpha: 1)
            cell.selectedBackgroundView = bgColorView
        }
        
        if indexPath.row == vehicleIdArray?.count {
            cell.bottomSepLabel.hidden = true
        } else {
            cell.bottomSepLabel.hidden = false
        }
        
        return cell
        
    }
    
    //MARK: Action
    
    @IBAction func backButtonClick(sender: AnyObject) {
        
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    
    @IBAction func doneButtonClick(sender: AnyObject) {
        
        let addSesrviceVCObj = self.navigationController?.viewControllers[(self.navigationController?.viewControllers.count)!-2] as! AddServiceVC
        
        var selectedVehicleId:String?
        
        if let selectedindex = tableView.indexPathForSelectedRow {
            selectedVehicleId = vehicleIdArray![selectedindex.row]
            
            addSesrviceVCObj.selectedVehicle = vehicleData![selectedVehicleId!] as? [String:AnyObject]
            
        }
        
        self.navigationController?.popViewControllerAnimated(true)
        
    }
    
}

