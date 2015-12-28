//
//  ANTLRException.swift
//  antlr.swift
//
//  Created by janyou on 15/9/8.
//  Copyright © 2015 jlabs. All rights reserved.
//


import Foundation
public enum  ANTLRException: ErrorType{
   //- case  LexerNoViableAlt( e:  LexerNoViableAltException)
   // case  ParseCancellationException
    case  CannotInvokeStartRule
   // case  StartRuleDoesNotConsumeFullPattern
    case  Recognition(e: AnyObject) //RecognitionException
    //-case  NoViableAlt(e:  NoViableAltException)
    //-case  InputMismatch (e: InputMismatchException)
    //-case FailedPredicate (e: FailedPredicateException)
}
