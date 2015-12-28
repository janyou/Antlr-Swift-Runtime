//
//  ANTLRError.swift
//  antlr.swift
//
//  Created by janyou on 15/9/4.
//  Copyright © 2015 jlabs. All rights reserved.
//

import Foundation
enum ANTLRError: ErrorType{
    case NullPointer(msg: String)  /* throw NullPointerException("listener cannot be null."); */
    case UnsupportedOperation(msg: String)   /* throw UnsupportedOperationException("there is no serialized ATN"); */
    case IndexOutOfBounds(msg: String)     /*throw IndexOutOfBoundsException("get("+i+") outside buffer:*/
    case IllegalState(msg: String) /* throw IllegalStateException("cannot consume EOF"); */
    case IllegalArgument(msg: String) /* throw IllegalArgumentException("cannot seek to negative index " + index); */
    case NegativeArraySize(msg: String)
    case ParseCancellation //throw ParseCancellationException(e);
   // case noViableAlt
}
