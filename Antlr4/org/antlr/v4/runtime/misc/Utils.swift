/*
 * [The "BSD license"]
 *  Copyright (c) 2012 Terence Parr
 *  Copyright (c) 2012 Sam Harwell
 *  Copyright (c) 2015 Janyou
 *  All rights reserved.
 *
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions
 *  are met:
 *
 *  1. Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *  2. Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *  3. The name of the author may not be used to endorse or promote products
 *     derived from this software without specific prior written permission.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 *  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 *  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 *  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 *  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 *  NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 *  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 *  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 *  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 *  THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


import Foundation

public class Utils {

    public static func escapeWhitespace(s: String, _ escapeSpaces: Bool) -> String {
        let buf: StringBuilder = StringBuilder()
        for c: Character in s.characters {
            if c == " " && escapeSpaces {
                buf.append("\u{00B7}")
            } else {
                if c == "\t" {
                    buf.append("\\t")
                } else {
                    if c == "\n" {
                        buf.append("\\n")
                    } else {
                        if c == "\r" {
                            buf.append("\\r")
                        } else {
                            buf.append(String(c))
                        }
                    }
                }
            }
        }
        return buf.toString()
    }


    public static func writeFile(fileName: String, _ content: String, _ encoding: NSStringEncoding = NSUTF8StringEncoding) {

        //writing
        do {
            try content.writeToFile(fileName, atomically: false, encoding: encoding)
        } catch {
            /* error handling here */
            RuntimeException(" write file fail \(error)")
        }

    }


    public static func readFile(path: String, _ encoding: NSStringEncoding = NSUTF8StringEncoding) -> [Character] {
        
        var fileContents: String? = nil
        
        do {
            fileContents = try String(contentsOfFile: path, encoding: encoding)
        } catch _ as NSError {
            return [Character]()
        }
        
        return Array(fileContents!.characters)
    }

    public static func readFile2String(fileName: String, _ encoding: NSStringEncoding = NSUTF8StringEncoding) -> String {
        let path = NSBundle.mainBundle().pathForResource(fileName, ofType: nil)
        if path == nil {
            return ""
        }

        var fileContents: String? = nil
        do {
            fileContents = try String(contentsOfFile: path!, encoding: encoding)
        } catch _ as NSError {
            return ""
        }



        return fileContents ?? ""
    }

    public static func readFile2StringByPath(path: String, _ encoding: NSStringEncoding = NSUTF8StringEncoding) -> String {

        //let path = fileName.stringByExpandingTildeInPath
        var fileContents: String? = nil
        do {
            fileContents = try NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding) as String          //try String(contentsOfFile: path!, encoding: encoding)
        } catch _ as NSError {
            return ""
        }

        return fileContents ?? ""
    }

}
