//
//  LoginVC.swift
//  CouchBaseSwift
//
//  Created by Jignesh Patel on 24/09/16.
//  Copyright © 2016 Jignesh Patel. All rights reserved.
//

import UIKit

class LoginVC: UIViewController,UITextFieldDelegate {

    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var emailTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        SharedClass.navController = self.navigationController
        
        // check if user already logged in then move to service list
        let pref = SharedClass.sharedInstance.pref
        
        if (pref != nil) && pref!.isLoggedIn {
            
            SharedClass.sharedInstance.kTrementDocId = "treatment-\(pref!.channel)"
            SharedClass.sharedInstance.kInventoryDocId = "inventory-\(pref!.channel)"
            SharedClass.sharedInstance.kSettingDocId = "settings-\(pref!.channel)"
            
            let serviceListVCObj = self.storyboard?.instantiateViewControllerWithIdentifier("AllServiceVC") as! AllServiceVC
            self.navigationController?.pushViewController(serviceListVCObj, animated: false)
        }
        
        emailTextField.layer.borderWidth = 1.0
        emailTextField.layer.borderColor = UIColor.lightGrayColor().CGColor
        passwordTextField.layer.borderWidth = 1.0
        passwordTextField.layer.borderColor = UIColor.lightGrayColor().CGColor
        

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    //MARK: IBAction
    @IBAction func loginClick(sender: AnyObject) {
        
        if emailTextField.text?.characters.count == 0 {
            SharedClass.alertView("", strMessage: "Please enter your user name")
            return
        }
        if passwordTextField.text?.characters.count == 0 {
            SharedClass.alertView("", strMessage: "Please enter your password")
            return
        }
        
        if SharedClass.isReachable {
            
            dispatch_async(dispatch_get_main_queue(), {
                MBProgressHUD.showHUDAddedTo(self.view, animated: true)
            })
            
            SharedClass.sharedInstance.getUpdatedUserDataWebservice(emailTextField.text!, password: passwordTextField.text!, successHandler: { (isSuccess,errorString) in
                
                dispatch_async(dispatch_get_main_queue(), {
                    MBProgressHUD.hideHUDForView(self.view, animated: true)
                })
                
                if isSuccess {
                    
                    // check for valid license
                    let status = SharedClass.sharedInstance.isLicenseValid()
                    if status {
                        let pref = SharedClass.sharedInstance.pref!
                        pref.isLoggedIn = true
                        pref.password = self.passwordTextField.text!
                        pref.username = self.emailTextField.text!
                        pref.save(SharedClass.kPrefFile)
                        
                        SharedClass.sharedInstance.kTrementDocId = "treatment-\(pref.channel)"
                        SharedClass.sharedInstance.kInventoryDocId = "inventory-\(pref.channel)"
                        SharedClass.sharedInstance.kSettingDocId = "settings-\(pref.channel)"
            
                        
                        let serviceListVCObj = self.storyboard?.instantiateViewControllerWithIdentifier("AllServiceVC") as! AllServiceVC
                        dispatch_async(dispatch_get_main_queue(), {
                            self.navigationController?.pushViewController(serviceListVCObj, animated: true)
                        })
                    } else {
                        dispatch_async(dispatch_get_main_queue(), {
                            SharedClass.alertView("Error!!", strMessage: "License is not valid, Please update your license")})
                    }
                    
                } else {
                    dispatch_async(dispatch_get_main_queue(), {
                        SharedClass.alertView("Failed!", strMessage: errorString)
                    })
                }
                
            })
            
        } else {
            SharedClass.alertView("No Internet!", strMessage: "Please check your internet connection")
        }
        
    }
    
    //MARK: UITextField
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        if textField == emailTextField {
            passwordTextField .becomeFirstResponder()
        } else {
            loginClick(self)
        }
        
        return true
    }
    
}
