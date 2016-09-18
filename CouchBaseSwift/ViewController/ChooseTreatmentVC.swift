//
//  ChooseTreatmentVC.swift
//  CouchBaseSwift
//
//  Created by Jignesh Patel on 01/09/16.
//  Copyright © 2016 Jignesh Patel. All rights reserved.
//

import UIKit

class ChooseTreatmentVC: UIViewController,UITableViewDataSource, UITableViewDelegate,QuantityTextFieldDelegate, NameTextFieldDelegate {

    var retrievedDoc : CBLDocument?
    var treatmentArray:NSMutableArray = NSMutableArray()
    var newTreatment : String?
    var newTreatmentRate : Int = 0
    var problemDict:[String:AnyObject]?
    var tableViewDidDisplayed = false
    var selectedVehicleType:String?
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        if selectedVehicleType == nil {
            selectedVehicleType = "default"
        }
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
        tableView.registerNib(UINib.init(nibName: "FooterCell", bundle: nil), forCellReuseIdentifier: "FooterCell")
        
        // auto resize height
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44
        tableView.alwaysBounceVertical = true
        tableView.tableFooterView = UIView()
    
        retrieveTreatments()
        
    }
    
    func reloadTableData() -> Bool {
        
        guard var docData = retrievedDoc!.properties
            else {return false}
        
        // display the retrieved document
        print("The retrieved document contains: \(docData)");
        
        treatmentArray = []
        if let tempDict = docData["regular"] as? NSDictionary {
            for key in tempDict.allKeys {
                
                let keyStrinValue = key as! String
                let keyValue = tempDict.valueForKey(keyStrinValue) as! [String:AnyObject]
                
                let treatmentTemp = [keyStrinValue : keyValue]
                
                treatmentArray.addObject(treatmentTemp)
            }
        }
        
        tableView.reloadData()
        
        return true
    }
    
    // retrieves the treatments
    func retrieveTreatments() -> Bool {
        
        // retrieve the document from the database
        if let retrievedDocTemp = SharedClass.sharedInstance.database?.documentWithID(SharedClass.sharedInstance.kTrementDocId!) {
            
            retrievedDoc = retrievedDocTemp
            
            //retrievedDoc?.addObserver(self, forKeyPath: "regular", options: .New, context: nil)
            
            tableViewDidDisplayed = false
            reloadTableData()
            
        } else {
            
            return false
        }
        
        return true
        
    }
    
    // add Treatment
    func addTreatment(documentID:String,newTreatmentString:String, rate:Int) -> Bool {
        
        var newTreatmentDict : [String:AnyObject] = [:]
        if selectedVehicleType! == "default" {
            newTreatmentDict = [newTreatmentString:["rate":["default":rate]]]
        } else {
            newTreatmentDict = [newTreatmentString:["rate":["default":rate,selectedVehicleType!:rate]]]
        }
        
        let retrDoc = SharedClass.sharedInstance.database?.documentWithID(documentID)
        
        var docData : [String:AnyObject]
        if let docDataTemp = retrDoc?.properties {
            docData = docDataTemp
        } else {
            docData = ["regular":newTreatmentDict]
        }
        
        var treatmentDict:[String:AnyObject] = [:]
        
        if let tempDict = docData["regular"] as? [String:AnyObject] {
            treatmentDict = tempDict
        }
    
        treatmentDict.update(newTreatmentDict)
        docData["regular"] = treatmentDict
        
        do {
            
            try retrDoc?.putProperties(docData)
            
            newTreatment = ""
            newTreatmentRate = 0
            
            if problemDict == nil {problemDict = [:]}
            
            problemDict![newTreatmentString] = ["rate":["default":rate]]
            
            treatmentArray.addObject(newTreatmentDict)
            
            tableView.reloadData()
            
        } catch let error as NSError {
            
            print(error.localizedDescription)
            
            return false
        }
        
        return true
        
    }
    
    // deletes the document
    func deleteDb(documentID:String) -> Bool {
        
        do {
            
           try SharedClass.sharedInstance.database?.documentWithID(documentID)?.deleteDocument()
            
            // verify the deletion by retrieving the document and checking whether it has been deleted
            if let ddoc = SharedClass.sharedInstance.database?.documentWithID(documentID) {
                
                print ("The document with ID \(documentID) \(ddoc.isDeleted ? "deleted" : "not deleted")")
                
            }
            
            
        } catch let error as NSError {
            
            print(error.localizedDescription)
            return false
        }
        
        return true
    }

    //MARK: TableView methods
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return treatmentArray.count+1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if indexPath.row == treatmentArray.count {
            
            let cell:FooterCell = tableView.dequeueReusableCellWithIdentifier("FooterCell") as! FooterCell
            
            cell.nameText.delegate = cell.nameText
            cell.nameText.atIndext = indexPath.row
            cell.nameText.nameDelegate = self
            cell.nameText.text = ""
            
            cell.valueText.delegate = cell.valueText
            cell.valueText.atIndext = indexPath.row
            cell.valueText.quantityDelegate = self
            cell.valueText.text = ""
            
            cell.addButton.addTarget(self, action: #selector(addNewFeilds), forControlEvents: .TouchUpInside)
            
            cell.selectionStyle = .None
            
            return cell
            
        } else {
            
            let cell:LabelTextCell = tableView.dequeueReusableCellWithIdentifier("LabelTextCell") as! LabelTextCell
            
            let treatmentDict = treatmentArray[indexPath.row] as! NSDictionary
            let key = treatmentDict.allKeys[0] as! String
            
            if let treatment = treatmentDict.valueForKey(key) as? NSDictionary {
            
                if (problemDict?[key]) != nil {
                    tableView.selectRowAtIndexPath(indexPath, animated: false, scrollPosition: UITableViewScrollPosition.None)
                }
                
                cell.nameLabel.text = key
                cell.valueTextField.delegate = cell.valueTextField
                cell.valueTextField.atIndext = indexPath.row
                cell.valueTextField.quantityDelegate = self
                
                if let valueString = (treatment.objectForKey("rate")?.valueForKey(selectedVehicleType!)) {
                    
                    cell.valueTextField.text = String(valueString)
                    
                } else if let valueString = treatment.objectForKey("rate")?.valueForKey("default") {
                    
                    cell.valueTextField.text = String(valueString)
                }
                
                let bgColorView = UIView()
                bgColorView.backgroundColor = UIColor.init(red: 225/255.0, green: 235/255.0, blue: 248/255.0, alpha: 1)
                cell.selectedBackgroundView = bgColorView
            }
            
            return cell
        }
    }
    
    /*func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
     
        if indexPath.row < treatmentArray.count {
            
            let cell:LabelTextCell = tableView.cellForRowAtIndexPath(indexPath) as! LabelTextCell
            cell.setSelected(true, animated: true)
            
        }
        
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        
        if indexPath.row < treatmentArray.count {
            
            let cell:LabelTextCell = tableView.cellForRowAtIndexPath(indexPath) as! LabelTextCell
            cell.setSelected(false, animated: true)
            
        }
    }*/
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        
        if indexPath.row == treatmentArray.count {
            return false
        }
        return false//true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.Delete) {
        
            
        }
    }
    
    //MARK: Quantity Textfield delegate
    func quantityTextFieldDidEndEditing(strText: String, atIndextValue: Int) {
        
        print("Value : \(strText) for index:\(atIndextValue)")
        
        if atIndextValue == treatmentArray.count {
            newTreatmentRate = Int(strText)!
        }
        
    }
    
    func nameTextFieldDidEndEditing(strText: String, atIndextValue: Int) {
        
        print("Value : \(strText) for index:\(atIndextValue)")
        
        if atIndextValue == treatmentArray.count {
            newTreatment = strText
        }
        
    }
    
    //MARK: Action
    
    @IBAction func backButtonClick(sender: AnyObject) {
        
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func doneButtonClick(sender: AnyObject) {
        
        problemDict = nil
        
        guard let selectedIndexPaths = tableView.indexPathsForSelectedRows
            else {
                let addSesrviceVCObj = self.navigationController?.viewControllers[(self.navigationController?.viewControllers.count)!-2] as! AddServiceVC
                addSesrviceVCObj.problemDict = problemDict
                self.navigationController?.popViewControllerAnimated(true)
                return
            }
        
        
        for indexPath in selectedIndexPaths {
            
            if indexPath.row == treatmentArray.count {continue}
            
            let treatmentDict = treatmentArray[indexPath.row]
            let key = (treatmentDict.allKeys[0] as! String)
            
            if let defaultRate = treatmentDict.valueForKey(key)?.valueForKey("rate")?.valueForKey(selectedVehicleType!) as? Float32 {
                
                if problemDict == nil {problemDict = [:]}
            
                problemDict![key] = ["rate":defaultRate]
                
            } else if let defaultRate = treatmentDict.valueForKey(key)?.valueForKey("rate")?.valueForKey("default") as? Float32 {
                
                if problemDict == nil {problemDict = [:]}
                
                problemDict![key] = ["rate":defaultRate]
            }

        }
        
        print(problemDict)
        
        let addSesrviceVCObj = self.navigationController?.viewControllers[(self.navigationController?.viewControllers.count)!-2] as! AddServiceVC
        addSesrviceVCObj.problemDict = problemDict
        self.navigationController?.popViewControllerAnimated(true)
    
    }
    
    
    func addNewFeilds() {
        
        if newTreatment != nil && newTreatment?.characters.count>0 {
            addTreatment(SharedClass.sharedInstance.kTrementDocId!, newTreatmentString: newTreatment!, rate: newTreatmentRate)
        } else {
            SharedClass.alertView("", strMessage: "Please enter treatment name")
        }
        
    }
    
    
}

