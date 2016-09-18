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
