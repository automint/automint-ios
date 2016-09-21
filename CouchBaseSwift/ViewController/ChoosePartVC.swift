//
//  ChoosePartVC.swift
//  CouchBaseSwift
//
//  Created by Jignesh Patel on 01/09/16.
//  Copyright © 2016 Jignesh Patel. All rights reserved.
//

import UIKit

class ChoosePartVC: UIViewController,UITableViewDataSource, UITableViewDelegate,QuantityTextFieldDelegate, NameTextFieldDelegate {

    var retrievedDoc : CBLDocument?
    var partsArray = NSMutableArray()
    var newPart : String?
    var newPartRate : Int = 0
    var partDict:[String:AnyObject]?
    
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        setupTableView()
    
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    /* deinit {
     
     if retrievedDoc != nil {
     retrievedDoc!.removeObserver(self, forKeyPath: "rows")
     }
     }
     
     // MARK: - KVO
     
     override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
     
     tableView.reloadData()
     
     }*/

    
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
    
        /*let docData:NSDictionary = ["_id":"inventory-(channel)","creator": "NAME","channel": "CHANNEL","PART-NAME-1":["rate": 9999],"PART-NAME-2":["rate": 9999]]
        
        for item in docData.allKeys {
            
            let keyString = item as! String
            if keyString != "creator" && keyString != "_id" && keyString != "channel" {
                
                let partDict:NSDictionary = ["partName":keyString,"value":docData[keyString]!]
                partsArray.addObject(partDict)
            }
            
        }*/
        
        retrieveParts()
        
    }
    
    func reloadTableData() -> Bool {
        
        guard var docData = retrievedDoc!.properties
            else {return false}
        
        // display the retrieved document
        print("The retrieved document contains: \(docData)");
        
        partsArray = []
        
        for item in docData.keys {
            
            let keyString = item 
            if keyString != "creator" && keyString != "_id" && keyString != "channel" {
                
                var valueString:[String:AnyObject] = ["rate":0,"amount":0]
                if let value = docData[keyString] as? [String:AnyObject]{
                    valueString = value
                    valueString["amount"] = value["rate"]
                    let partDict:NSDictionary = ["partName":keyString,"value":valueString]
                    partsArray.addObject(partDict)
                }
            }
            
        }
        
        tableView.reloadData()
        
        return true
    }
    
    // retrieves the parts
    func retrieveParts() -> Bool {
        
        // retrieve the document from the database
        if let retrievedDocTemp = SharedClass.sharedInstance.database?.documentWithID(SharedClass.sharedInstance.kInventoryDocId!) {
            
            retrievedDoc = retrievedDocTemp
            
            //retrievedDoc?.addObserver(self, forKeyPath: "regular", options: .New, context: nil)
            
            reloadTableData()
            
        } else {
            
            return false
        }
        
        return true
        
    }
    
    /*// add Treatment
    func addPart(documentID:String,newPartString:String, rate:Int) -> Bool {
        
        let retrDoc = SharedClass.sharedInstance.database?.documentWithID(documentID)
        
        var docData : [String:AnyObject] = [:]
        if let docDataTemp = retrDoc?.properties {
            docData = docDataTemp
        } else {
            docData["creator"] = "JIGNESH"
            docData["channel"] = "inventory-CHANNEL"
            docData[newPartString] = ["rate":rate]
        }
        
        docData[newPartString] = ["rate":rate]
        
        do {
            
            try retrDoc?.putProperties(docData)
            if partDict == nil { partDict = [:] }
            partDict![newPartString] = ["rate":rate]
            newPart = ""
            newPartRate = 0
            
            let partDictToArray:NSDictionary = ["partName":newPartString,"value":["rate":rate]]
            partsArray.addObject(partDictToArray)
            tableView.reloadData()
            
        } catch let error as NSError {
            
            print(error.localizedDescription)
            
            return false
        }
        
        return true
        
    }*/
    
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
        
        return partsArray.count+1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if indexPath.row == partsArray.count {
            
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
            
            if let part = partsArray[indexPath.row] as? NSDictionary {
                
                // value
                if let key = part["partName"] as? String {
                    cell.nameLabel.text = key
                    
                    if (partDict?[key]) != nil {
                        tableView.selectRowAtIndexPath(indexPath, animated: false, scrollPosition: UITableViewScrollPosition.None)
                    }
                    
                }
                
                if let rate = part["value"]?.valueForKey("rate") as? Int {
                    
                    cell.valueTextField.text = String(rate)
                    
                }
                
                cell.valueTextField.delegate = cell.valueTextField
                cell.valueTextField.atIndext = indexPath.row
                cell.valueTextField.quantityDelegate = self
                
                
                let bgColorView = UIView()
                bgColorView.backgroundColor = UIColor.init(red: 225/255.0, green: 235/255.0, blue: 248/255.0, alpha: 1)
                cell.selectedBackgroundView = bgColorView
            }
            
            
            return cell
        }
    }
    
    /*func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if indexPath.row < partsArray.count {
            let cell:LabelTextCell = tableView.cellForRowAtIndexPath(indexPath) as! LabelTextCell
            cell.setSelected(true, animated: true)
            
        }
        
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        
        if indexPath.row < partsArray.count {
            
            let cell:LabelTextCell = tableView.cellForRowAtIndexPath(indexPath) as! LabelTextCell
            cell.setSelected(false, animated: true)
            
        }
    }*/
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        
        if indexPath.row == partsArray.count {
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
        
        if atIndextValue == partsArray.count {
            newPartRate = Int(strText)!
        }
        
    }
    
    func nameTextFieldDidEndEditing(strText: String, atIndextValue: Int) {
        
        print("Value : \(strText) for index:\(atIndextValue)")
        
        if atIndextValue == partsArray.count {
            newPart = strText
        }
        
    }
    
    //MARK: Action
    @IBAction func doneButtonClick(sender: AnyObject) {
        
        partDict = nil
        
        guard let selectedIndexPaths = tableView.indexPathsForSelectedRows
            else {
                let addSesrviceVCObj = self.navigationController?.viewControllers[(self.navigationController?.viewControllers.count)!-2] as! AddServiceVC
                addSesrviceVCObj.partDict = partDict
                self.navigationController?.popViewControllerAnimated(true)
                return
        }
        
        for indexPath in selectedIndexPaths {
            
            if indexPath.row < partsArray.count {
                if partDict == nil { partDict = [:] }
                let partInfo = partsArray[indexPath.row]
                partDict![partInfo.valueForKey("partName") as! String] = partInfo.valueForKey("value")
            }
            
        }
        
        print(partDict)
        let addSesrviceVCObj = self.navigationController?.viewControllers[(self.navigationController?.viewControllers.count)!-2] as! AddServiceVC
        addSesrviceVCObj.partDict = partDict
        self.navigationController?.popViewControllerAnimated(true)
        
    }
    
    @IBAction func backButtonClick(sender: AnyObject) {
        
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func addNewFeilds() {
        
        if newPart != nil && newPart?.characters.count>0 {
            
            //addPart ( SharedClass.sharedInstance.kInventoryDocId!, newPartString: newPart!, rate: newPartRate)
            
            if partDict == nil { partDict = [:] }
            
            partDict![newPart!] = ["rate":newPartRate,"amount":newPartRate]
            
            let partDictToArray:NSDictionary = ["partName":newPart!,"value":["rate":newPartRate,"amount":newPartRate]]
            partsArray.addObject(partDictToArray)
            tableView.reloadData()
            
            newPart = ""
            newPartRate = 0
            
            
        } else {
            
            SharedClass.alertView("", strMessage: "Please enter part name")
        }
        
    }
    
    
}

