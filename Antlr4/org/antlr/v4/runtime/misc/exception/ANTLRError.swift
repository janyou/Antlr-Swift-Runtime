//
//  ANTLRError.swift
//  antlr.swift
//
//  Created by janyou on 15/9/4.
//  Copyright © 2015 jlabs. All rights reserved.
//

import Foundation

enum ANTLRError: ErrorType {
    case NullPointer(msg:String)
    case UnsupportedOperation(msg:String)
    case IndexOutOfBounds(msg:String)
    case IllegalState(msg:String)
    case IllegalArgument(msg:String)
    case NegativeArraySize(msg:String)
    case ParseCancellation
}
