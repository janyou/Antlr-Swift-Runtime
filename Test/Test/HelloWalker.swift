//
//  HelloWalker.swift
//  Exmples
//
//  Created by janyou on 15/12/26.
//  Copyright © 2015  jlabs. All rights reserved.
//

import Foundation

public class HelloWalker: HelloBaseListener{
    public override func enterR(ctx: HelloParser.RContext) {
        print( "enterR: " + ((ctx.ID()?.getText()) ?? ""))
    }
    
    public override func exitR(ctx: HelloParser.RContext) {
         print( "exitR  ")
    }
 
}