//
//  ANTLRException.swift
//  antlr.swift
//
//  Created by janyou on 15/9/8.
//  Copyright © 2015 jlabs. All rights reserved.
//


import Foundation

public enum ANTLRException: ErrorType {
    case CannotInvokeStartRule
    case Recognition(e:AnyObject)
}
