//import Cocoa

#if os(OSX)

import Cocoa

#elseif os(iOS)

import UIKit

#endif

//http://stackoverflow.com/questions/28182441/swift-how-to-get-substring-from-start-to-last-index-of-character
//https://github.com/williamFalcon/Bolt_Swift/blob/master/Bolt/BoltLibrary/String/String.swift

public extension String {

    func trim() -> String {
        return self.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
    }

    func split(separator: String) -> [String] {
        return self.componentsSeparatedByString(separator)
    }

    func replaceAll(from: String, replacement: String) -> String {
        return self.stringByReplacingOccurrencesOfString(from, withString: replacement, options: NSStringCompareOptions.LiteralSearch, range: nil)
    }

    func contains(find: String) -> Bool {
        return self.rangeOfString(find) != nil
    }

    func containsIgnoreCase(find: String) -> Bool {
        return self.lowercaseString.rangeOfString(find.lowercaseString) != nil
    }

    var length: Int {
        return self.characters.count
    }

    func indexOf(target: String) -> Int {
        let range = self.rangeOfString(target)
        if let range = range {
            return self.startIndex.distanceTo(range.startIndex)

        } else {
            return -1
        }
    }

    func indexOf(target: String, startIndex: Int) -> Int {

        let startRange = self.startIndex.advancedBy(startIndex)
        let range = self.rangeOfString(target, options: NSStringCompareOptions.LiteralSearch, range: Range<String.Index>(start: startRange, end: self.endIndex))
        if let range = range {

            return self.startIndex.distanceTo(range.startIndex)
        } else {
            return -1
        }
    }

    func lastIndexOf(target: String) -> Int {
        var index = -1
        var stepIndex = self.indexOf(target)
        while stepIndex > -1 {
            index = stepIndex
            if stepIndex + target.length < self.length {
                stepIndex = indexOf(target, startIndex: stepIndex + target.length)
            } else {
                stepIndex = -1
            }
        }
        return index
    }

    func substringAfter(string: String) -> String {
        let range = self.rangeOfString(string)
        if range != nil {
            let intIndex: Int = self.startIndex.distanceTo(range!.endIndex)
            return self.substringFromIndex(self.startIndex.advancedBy(intIndex))
        }
        return self

    }

    var lowercaseFirstChar: String {
        var result = self
        if self.length > 0 {
            let startIndex = self.startIndex
            result.replaceRange(startIndex ... startIndex, with: String(self[startIndex]).lowercaseString)
        }
        return result
    }
    func substringWithRange(range: Range<Int>) -> String {


        let start = self.startIndex.advancedBy(range.startIndex)

        let end = self.startIndex.advancedBy(range.endIndex)
        return self.substringWithRange(start ..< end)
    }

    func substringBetween(start  start: String, end: String) -> String {

        let scanner = NSScanner(string: self)
        var scanned: NSString?

        //http://blog.csdn.net/binzi98/article/details/8588604
        scanner.scanUpToString(start, intoString: nil)
        if !scanner.scanString(start, intoString: nil) {
            return ""
        }
        scanner.scanUpToString(end, intoString: &scanned)

        if !scanner.scanString(end, intoString: nil) {
            return ""
        }

        if let result: String = scanned as? String {
            return result
        }
        return ""
    }

    func substringBetween1(start  start: String, end: String) -> String {
        var startIndex = indexOf(start)
        if startIndex == -1 {
            return ""
        }

        startIndex = startIndex + start.length

        let endIndex = indexOf(end, startIndex: startIndex)

        if endIndex == -1 || startIndex > endIndex {
            return ""
        }



        let range = Range(start: startIndex, end: endIndex)

        return substringWithRange(range)
    }

    var html2String: String {
        let encodeData = self.dataUsingEncoding(NSUTF8StringEncoding)
        if encodeData == nil {
            return ""
        }
        let aString = try? NSAttributedString(data: self.dataUsingEncoding(NSUTF8StringEncoding)!,
                options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType, NSCharacterEncodingDocumentAttribute: NSUTF8StringEncoding], documentAttributes: nil)

        return (aString != nil) ? aString!.string : ""
    }

    subscript(integerIndex: Int) -> Character {

        let index = startIndex.advancedBy(integerIndex)
        return self[index]
    }

    subscript(integerRange: Range<Int>) -> String {

        let start = startIndex.advancedBy(integerRange.startIndex)
        let end = startIndex.advancedBy(integerRange.endIndex)
        let range = start ..< end
        return self[range]
    }

    func charAt(index: Int) -> Character {
        return [Character](characters)[index]
    }

}

// Mapping from XML/HTML character entity reference to character
// From http://en.wikipedia.org/wiki/List_of_XML_and_HTML_character_entity_references
private let characterEntities: [String:Character] = [
        // XML predefined entities:
        "&quot;": "\"",
        "&amp;": "&",
        "&apos;": "'",
        "&lt;": "<",
        "&gt;": ">",

        // HTML character entity references:
        "&nbsp;": "\u{00a0}",
        // ...
        "&diams;": "♦",
]

extension String {

    /// Returns a new string made by replacing in the `String`
    /// all HTML character entity references with the corresponding
    /// character.
    var stringByDecodingHTMLEntities: String {


        // Convert the number in the string to the corresponding
        // Unicode character, e.g.
        //    decodeNumeric("64", 10)   --> "@"
        //    decodeNumeric("20ac", 16) --> "€"
        func decodeNumeric(string: String, base: Int32) -> Character? {
            let code = UInt32(strtoul(string, nil, base))
            return Character(UnicodeScalar(code))
        }

        // Decode the HTML character entity to the corresponding
        // Unicode character, return `nil` for invalid input.
        //     decode("&#64;")    --> "@"
        //     decode("&#x20ac;") --> "€"
        //     decode("&lt;")     --> "<"
        //     decode("&foo;")    --> nil
        func decode(entity: String) -> Character? {

            if entity.hasPrefix("&#x") || entity.hasPrefix("&#X") {
                return decodeNumeric(entity.substringFromIndex(entity.startIndex.advancedBy(3)), base: 16)
            } else if entity.hasPrefix("&#") {
                return decodeNumeric(entity.substringFromIndex(entity.startIndex.advancedBy(2)), base: 10)
            } else {
                return characterEntities[entity]
            }
        }


        var result = ""
        var position = startIndex

        // Find the next '&' and copy the characters preceding it to `result`:
        while let ampRange = self.rangeOfString("&", range: position ..< endIndex) {
            result.appendContentsOf(self[position ..< ampRange.startIndex])
            position = ampRange.startIndex

            // Find the next ';' and copy everything from '&' to ';' into `entity`
            if let semiRange = self.rangeOfString(";", range: position ..< endIndex) {
                let entity = self[position ..< semiRange.endIndex]
                position = semiRange.endIndex

                if let decoded = decode(entity) {
                    // Replace by decoded character:
                    result.append(decoded)
                } else {
                    // Invalid entity, copy verbatim:
                    result.appendContentsOf(entity)
                }
            } else {
                // No matching ';'.
                break
            }
        }
        // Copy remaining characters to `result`:
        result.appendContentsOf(self[position ..< endIndex])
        return result
    }
}

extension String {
    static let htmlEscapedDictionary = [

            "&amp;": "&",
            "&quot;": "\"",
            "&#x27;": "'",
            "&#x39;": "'",
            "&#x92;": "'",
            "&#x96;": "'",
            "&gt;": ">",
            "&lt;": "<"]

    public var escapedHtmlString: String {
        var newString = "\(self)"

        for (key, value) in String.htmlEscapedDictionary {
            newString = newString.replaceAll(value, replacement: key)
        }
        return newString
    }

}