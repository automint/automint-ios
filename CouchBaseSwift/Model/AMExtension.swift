//
//  AMExtension.swift
//  CouchBaseSwift
//
//  Created by Jignesh Patel on 11/09/16.
//  Copyright © 2016 Jignesh Patel. All rights reserved.
//

import Foundation

extension Dictionary {
    mutating func update(other:Dictionary) {
        for (key,value) in other {
            self.updateValue(value, forKey:key)
        }
    }
}

extension NSMutableURLRequest {
    
    func setBodyContent(parameters: [String : String]) {
        let parameterArray = parameters.map { (key, value) -> String in
            return "\(key)=\(value.stringByAddingPercentEscapesForQueryValue()!)"
        }
        HTTPBody = parameterArray.joinWithSeparator("&").dataUsingEncoding(NSUTF8StringEncoding)
    }
}

extension String {
    
    func stringByAddingPercentEscapesForQueryValue() -> String? {
        let allowedCharacters = NSCharacterSet(charactersInString: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._* ")
        
        return stringByAddingPercentEncodingWithAllowedCharacters(allowedCharacters)?.stringByReplacingOccurrencesOfString(" ", withString: "+")
    }
}
