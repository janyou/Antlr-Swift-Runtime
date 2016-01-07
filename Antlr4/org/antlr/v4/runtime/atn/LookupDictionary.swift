//
//  LookupDictionary.swift
//   antlr.swift
//
//  Created by janyou on 15/9/23.
//  Copyright © 2015 jlabs. All rights reserved.
//

import Foundation

public enum LookupDictionaryType: Int {
    case Lookup = 0
    case Ordered
}

public class LookupDictionary {
    private var type: LookupDictionaryType
    private var cache: Dictionary<Int, [ATNConfig]> = Dictionary<Int, [ATNConfig]>()

    public init(type: LookupDictionaryType = LookupDictionaryType.Lookup) {
        self.type = type
    }

    private func hash(config: ATNConfig) -> Int {
        if type == LookupDictionaryType.Lookup {

            var hashCode: Int = 7
            hashCode = 31 * hashCode + config.state.stateNumber
            hashCode = 31 * hashCode + config.alt
            hashCode = 31 * hashCode + config.semanticContext.hashValue
            return hashCode

        } else {
            //Ordered
            return config.hashValue
        }
    }

    private func equal(lhs: ATNConfig, _ rhs: ATNConfig) -> Bool {
        if type == LookupDictionaryType.Lookup {
            if lhs === rhs {
                return true
            }


            let same: Bool =
            lhs.state.stateNumber == rhs.state.stateNumber &&
                    lhs.alt == rhs.alt &&
                    lhs.semanticContext == rhs.semanticContext

            return same

        } else {
            //Ordered
            return lhs == rhs
        }
    }

    public func getOrAdd(config: ATNConfig) -> ATNConfig {

        let h = hash(config)
        var configList = cache[h]
        if configList != nil {
            for c in configList! {
                if equal(c, config) {
                    return c
                }
            }
        }

        if configList == nil {
            cache[h] = [config]
        } else {
            configList?.append(config)
        }

        return config

    }
    public var isEmpty: Bool {
        return cache.isEmpty
    }

    public func contains(config: ATNConfig) -> Bool {

        let h = hash(config)
        if let configList = cache[h] {
            for c in configList {
                if equal(c, config) {
                    return true
                }
            }
        }

        return false

    }

    public func removeAll() {
        cache.removeAll()
    }

}



 