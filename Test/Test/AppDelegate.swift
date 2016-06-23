//
//  AppDelegate.swift
//  Test
//
//  Created by janyou on 15/12/28.
//  Copyright © 2015  jlabs. All rights reserved.
//

import Cocoa
import Antlr4
@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    @IBOutlet weak var window: NSWindow!
 
    
    @IBAction func runHelloWalker(_ sender: AnyObject) {
        do {
            //            let text = Utils.readFile2String("TestHello.txt")
            //            let chars :CharStream  =   ANTLRInputStream(text)
            //            let lexer =   HelloLexer(chars)
            
            let textFileName = "TestHello.txt"
            
            if let textFilePath = Bundle.main().pathForResource(textFileName, ofType: nil) {
                let lexer =  HelloLexer(ANTLRFileStream(textFilePath))
                let tokens =  CommonTokenStream(lexer)
                let parser = try HelloParser(tokens)
                
                let tree = try parser.r()
                let walker = ParseTreeWalker()
                try walker.walk(HelloWalker(),tree)
            } else {
                print("error occur: can not open \(textFileName)")
            }
            
        }catch ANTLRException.cannotInvokeStartRule {
            print("error occur: CannotInvokeStartRule")
        }catch ANTLRException.recognition(let e )   {
            print("error occur\(e)")
        }catch {
            print("error occur")
        }
    }
    
    
    func applicationDidFinishLaunching(_ aNotification: Notification){
        // Insert code here to initialize your application
        
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    
}

