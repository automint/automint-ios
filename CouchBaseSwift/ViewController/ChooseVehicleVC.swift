//
//  ChooseVehicleVC.swift
//  CouchBaseSwift
//
//  Created by Jignesh Patel on 01/09/16.
//  Copyright © 2016 Jignesh Patel. All rights reserved.
//

import UIKit

class ChooseVehicleVC: UIViewController,UITableViewDataSource, UITableViewDelegate {

    var retrievedDoc : CBLDocument?
    var dummyArray = NSMutableArray()
    var newPart : String?
    var newPartRate : Int?
    
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
        
        retrieveParts()
        
    }
    
    func reloadTableData() -> Bool {
        
        guard var docData = retrievedDoc!.properties
            else {return false}
        
        // display the retrieved document
        print("The retrieved document contains: \(docData)");
        
        dummyArray = []
        
        for item in docData.keys {
            
            let keyString = item 
            if keyString != "creator" && keyString != "_id" && keyString != "channel" {
                
                var valueString:[String:AnyObject] = ["rate":0]
                if let value = docData[keyString] as? [String:AnyObject]{
                    valueString = value
                    let partDict:NSDictionary = ["partName":keyString,"value":valueString]
                    dummyArray.addObject(partDict)
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
        
        return dummyArray.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
            
            let cell:LabelTextCell = tableView.dequeueReusableCellWithIdentifier("LabelTextCell") as! LabelTextCell
            
            if let treatment = dummyArray[indexPath.row] as? NSDictionary {
                
                // value
                if let key = treatment["partName"] as? String {
                    cell.nameLabel.text = key
                }
                
                cell.valueTextFieldWidth.constant = 0
                
                let bgColorView = UIView()
                bgColorView.backgroundColor = UIColor.init(red: 225/255.0, green: 235/255.0, blue: 248/255.0, alpha: 1)
                cell.selectedBackgroundView = bgColorView
            }
            
            
            return cell
        
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if indexPath.row != dummyArray.count {
            
        }
        
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        
        if indexPath.row == dummyArray.count {
            return false
        }
        return false//true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.Delete) {
        
            
        }
    }
    
    //MARK: Action
    
    @IBAction func backButtonClick(sender: AnyObject) {
        
        self.navigationController?.popViewControllerAnimated(true)
    }
    
}

