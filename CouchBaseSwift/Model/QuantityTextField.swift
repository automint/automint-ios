//
//  QuantityTextField.swift
//  TableViewWithTextField
//
//
//  Created by Jignesh Patel on 01/09/16.
//  Copyright © 2016 Jignesh Patel. All rights reserved.
//


import UIKit


@objc protocol QuantityTextFieldDelegate{
    
    optional func quantityTextFieldDidEndEditing(strText:String,atIndextValue:Int)
}

class QuantityTextField: UITextField,UITextFieldDelegate {
    
    
    
    var quantityDelegate                        :   QuantityTextFieldDelegate?
    
    var atIndext                                : Int   = 0
    
    override func drawRect(rect: CGRect) {
    
    }

    //MARK:- UITextFieldDelegate*
    func textFieldDidBeginEditing(textField: UITextField) {
        
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
    
        //quantityDelegate?.quantityTextFieldDidEndEditing!(textField.text!,atIndextValue: atIndext);
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        textField.endEditing(true)
        return true
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        
        let userEnteredString = textField.text
        let newString = (userEnteredString! as NSString).stringByReplacingCharactersInRange(range, withString: string) as NSString
        
        if string == "" {
            quantityDelegate?.quantityTextFieldDidEndEditing!(newString as String,atIndextValue: atIndext);
            return true
        }
        
        let regEx = "([0-9])"
        let match = string.rangeOfString(regEx, options: .RegularExpressionSearch)
        if (match == nil){ return false}
        
        quantityDelegate?.quantityTextFieldDidEndEditing!(newString as String,atIndextValue: atIndext);
        
        return true
    }
    
}
