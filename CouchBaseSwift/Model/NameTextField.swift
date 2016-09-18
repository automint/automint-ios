//
//  NameTextField.swift
//  CouchBaseSwift
//
//  Created by Jignesh Patel on 06/09/16.
//  Copyright © 2016 Jignesh Patel. All rights reserved.
//

//
//  NameTextField.swift
//  TableViewWithTextField
//
//
//  Created by Jignesh Patel on 01/09/16.
//  Copyright © 2016 Jignesh Patel. All rights reserved.
//


import UIKit


@objc protocol NameTextFieldDelegate{
    
    optional func nameTextFieldDidEndEditing(strText:String,atIndextValue:Int)
}

class NameTextField: UITextField,UITextFieldDelegate {
    
    var nameDelegate                        :   NameTextFieldDelegate?
    
    var atIndext                                : Int   = 0
    
    override func drawRect(rect: CGRect) {
        
    }
    
    //MARK:- UITextFieldDelegate*
    func textFieldDidBeginEditing(textField: UITextField) {
        
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        
        //nameDelegate?.nameTextFieldDidEndEditing!(textField.text!,atIndextValue: atIndext)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        textField.endEditing(true)
        return true
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        
        let userEnteredString = textField.text
        
        let newString = (userEnteredString! as NSString).stringByReplacingCharactersInRange(range, withString: string) as NSString
        
        nameDelegate?.nameTextFieldDidEndEditing!(newString as String,atIndextValue: atIndext)
        
        return true
    }
    
}
