//
//  CommonUtil.swift
//   antlr.swift
//
//  Created by janyou on 15/9/4.
//  Copyright © 2015 jlabs. All rights reserved.
//

import Foundation

func errPrint(msg: String) {
    fputs(msg + "\n", __stderrp)
}

func +(lhs: String, rhs: Int) -> String {
    return lhs + String(rhs)
}

func +(lhs: Int, rhs: String) -> String {
    return String(lhs) + rhs
}

func +(lhs: String, rhs: Token) -> String {
    return lhs + rhs.description
}

func +(lhs: Token, rhs: String) -> String {
    return lhs.description + rhs
}

infix operator >>> { associativity right precedence 160 }

func >>>(lhs: Int32, rhs: Int32) -> Int32 {
    var left: UInt32, right: UInt32
    if lhs < 0 {

        left = UInt32(bitPattern: lhs)

    } else {
        left = UInt32(lhs)
    }

    let bit: Int32 = 32

    if rhs > Int32(bit - 1) {
        right = UInt32(rhs % bit)
    } else if rhs < 0 {
        right = UInt32(bit + (rhs % bit))

    } else {
        right = UInt32(rhs)
    }

    return Int32(left >> right)
}

func >>>(lhs: Int64, rhs: Int64) -> Int64 {
    var left: UInt64, right: UInt64
    if lhs < 0 {

        left = UInt64(bitPattern: lhs)

    } else {
        left = UInt64(lhs)
    }

    let bit: Int64 = 64

    if rhs > Int64(bit - 1) {
        right = UInt64(rhs % bit)
    } else if rhs < 0 {
        right = UInt64(bit + (rhs % bit))

    } else {
        right = UInt64(rhs)
    }

    return Int64(left >> right)
}

func >>>(lhs: Int, rhs: Int) -> Int {
    var left: UInt, right: UInt
    if lhs < 0 {

        left = UInt(bitPattern: lhs)

    } else {
        left = UInt(lhs)
    }

    let bit: Int = sizeof(Int) == sizeof(Int64) ? 64 : 32

    if rhs > (bit - 1) {
        right = UInt(rhs % bit)
    } else if rhs < 0 {
        right = UInt(bit + (rhs % bit))

    } else {
        right = UInt(rhs)
    }

    return Int(left >> right)
}


public func synced(lock: AnyObject, closure: () -> ()) {
    objc_sync_enter(lock)
    closure()
    objc_sync_exit(lock)
}


public func intChar2String(i: Int) -> String {
    return String(Character(integerLiteral: i))
}

public func log(message: String = "", file: String = __FILE__, function: String = __FUNCTION__, lineNum: Int = __LINE__) {

    // #if DEBUG
    print("FILE: \(NSURL(fileURLWithPath: file).pathComponents!.last!),FUNC: \(function), LINE: \(lineNum) MESSAGE: \(message)")
    //   #else
    // do nothing
    //   #endif
}


public func RuntimeException(message: String = "", file: String = __FILE__, function: String = __FUNCTION__, lineNum: Int = __LINE__) {
    // #if DEBUG
    let info = "FILE: \(NSURL(fileURLWithPath: file).pathComponents!.last!),FUNC: \(function), LINE: \(lineNum) MESSAGE: \(message)"
    //   #else
    // let info = "FILE: \(NSURL(fileURLWithPath: file).pathComponents!.last!),FUNC: \(function), LINE: \(lineNum) MESSAGE: \(message)"
    //   #endif

    fatalError(info)

}


//class
public func toInt(c: Character) -> Int {
    return c.unicodeValue
}
//class
public func toInt32(data: [Character], _ offset: Int) -> Int {
    return data[offset].unicodeValue | (data[offset + 1].unicodeValue << 16)
}

public func toLong(data: [Character], _ offset: Int) -> Int64 {
    let mask: Int64 = 0x00000000FFFFFFFF
    let lowOrder: Int64 = Int64(toInt32(data, offset)) & mask
    return lowOrder | Int64(toInt32(data, offset + 2) << 32)
}

public func toUUID(data: [Character], _ offset: Int) -> NSUUID {
    let leastSigBits: Int64 = toLong(data, offset)
    let mostSigBits: Int64 = toLong(data, offset + 4)
    //TODO:NSUUID(mostSigBits, leastSigBits);
    return NSUUID(mostSigBits: mostSigBits, leastSigBits: leastSigBits)
}

public func ArrayEquals<T:Equatable>(a: [T], _ a2: [T]) -> Bool {

    if a2.count != a.count {
        return false
    }

    let length = a.count

    for var i = 0; i < length; i++ {
        let o1 = a[i]
        let o2 = a2[i]

        if o1 != o2 {
            return false
        }


    }

    return true
}

public func ArrayEquals<T:Equatable>(a: [T?], _ a2: [T?]) -> Bool {

    if a2.count != a.count {
        return false
    }

    let length = a.count

    for var i = 0; i < length; i++ {
        let o1 = a[i]
        let o2 = a2[i]

        if o1 == nil && o2 != nil {
            return false
        }
        if o2 == nil && o1 != nil {
            return false
        }

        if o2 != nil && o1 != nil && o1! != o2! {
            return false
        }


    }

    return true
}