//
//  NSMapTableExtension.swift
//  antlr.swift
//
//  Created by janyou on 15/9/9.
//  Copyright © 2015 jlabs. All rights reserved.
//

import Foundation

extension NSMapTable {

    public subscript(key: AnyObject?) -> AnyObject? {
        get {
            return objectForKey(key)
        }
        set {
            setObject(newValue, forKey: key)
        }
    }


}