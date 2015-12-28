//
//  StringBuilder.swift
//   antlr.swift
//
//  Created by janyou on 15/9/4.
//  Copyright © 2015 jlabs. All rights reserved.
//

import Foundation

/**
Supports creation of a String from pieces
*/
public class StringBuilder {
    private var stringValue: String
    /**
    Construct with initial String contents
    :param: string Initial value; defaults to empty string
    */
    public init(string: String = "") {
        self.stringValue = string
    }
    /**
    Return the String object
    :return: String
    */
    public func toString() -> String {
        return stringValue
    }
    /**
    Return the current length of the String object
    */
    public var length: Int {
        return   stringValue.length
    }
    /**
    Append a String to the object
    :param: string String
    :return: reference to this StringBuilder instance
    */
    public func append(string: String) -> StringBuilder {
        stringValue += string
        return self
    }
    /**
    Append a Printable to the object
    :param: value a value supporting the Printable protocol
    :return: reference to this StringBuilder instance
    */
    public func append<T: CustomStringConvertible>(value: T) -> StringBuilder {
        stringValue += value.description
        return self
    }
    /**
    Append a String and a newline to the object
    :param: string String
    :return: reference to this StringBuilder instance
    */
    public func appendLine(string: String) -> StringBuilder {
        stringValue += string + "\n"
        return self
    }
    /**
    Append a Printable and a newline to the object
    :param: value a value supporting the Printable protocol
    :return: reference to this StringBuilder instance
    */
    public func appendLine<T: CustomStringConvertible>(value: T) -> StringBuilder {
        stringValue += value.description + "\n"
        return self
    }
    /**
    Reset the object to an empty string
    :return: reference to this StringBuilder instance
    */
    public func clear() -> StringBuilder {
        stringValue = ""
        return self
    }
}
/**
Append a String to a StringBuilder using operator syntax
:param: lhs StringBuilder
:param: rhs String
*/
public func += (lhs: StringBuilder, rhs: String) {
    lhs.append(rhs)
}
/**
Append a Printable to a StringBuilder using operator syntax
:param: lhs Printable
:param: rhs String
*/
public func += <T: CustomStringConvertible>(lhs: StringBuilder, rhs: T) {
    lhs.append(rhs.description)
}
/**
Create a StringBuilder by concatenating the values of two StringBuilders
:param: lhs first StringBuilder
:param: rhs second StringBuilder
:result StringBuilder
*/
public func +(lhs: StringBuilder, rhs: StringBuilder) -> StringBuilder {
    return StringBuilder(string: lhs.toString() + rhs.toString())
}
 