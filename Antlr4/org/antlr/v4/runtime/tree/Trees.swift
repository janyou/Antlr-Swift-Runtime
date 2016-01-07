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


/** A set of utility routines useful for all kinds of ANTLR trees. */

public class Trees {
    /*
    public class func getPS(t: Tree, _ ruleNames: Array<String>,
    _ fontName: String, _ fontSize: Int) -> String {
    let psgen: TreePostScriptGenerator =
    TreePostScriptGenerator(ruleNames, t, fontName, fontSize)
    return psgen.getPS()
    }
    
    public class func getPS(t: Tree, _ ruleNames: Array<String>) -> String {
    return getPS(t, ruleNames, "Helvetica", 11)
    }
    //TODO: write to file
    
    public class func writePS(t: Tree, _ ruleNames: Array<String>,
    _ fileName: String,
    _ fontName: String, _ fontSize: Int)
    throws {
    var ps: String = getPS(t, ruleNames, fontName, fontSize)
    var f: FileWriter = FileWriter(fileName)
    var bw: BufferedWriter = BufferedWriter(f)
    try {
    bw.write(ps)
    }
    defer {
    bw.close()
    }
    }
    
    public class func writePS(t: Tree, _ ruleNames: Array<String>, _ fileName: String)
    throws {
    writePS(t, ruleNames, fileName, "Helvetica", 11)
    }
    */
    /** Print out a whole tree in LISP form. {@link #getNodeText} is used on the
    *  node payloads to get the text for the nodes.  Detect
    *  parse trees and extract data appropriately.
    */
    public class func toStringTree(t: Tree) -> String {
        let rulsName: Array<String>? = nil
        return toStringTree(t, rulsName)
    }

    /** Print out a whole tree in LISP form. {@link #getNodeText} is used on the
     *  node payloads to get the text for the nodes.  Detect
     *  parse trees and extract data appropriately.
     */
    public class func toStringTree(t: Tree, _ recog: Parser?) -> String {
        let ruleNames: [String]? = recog != nil ? recog!.getRuleNames() : nil
        let ruleNamesList: Array<String>? = ruleNames != nil ? ruleNames : nil
        return toStringTree(t, ruleNamesList)
    }

    /** Print out a whole tree in LISP form. {@link #getNodeText} is used on the
     *  node payloads to get the text for the nodes.  Detect
     *  parse trees and extract data appropriately.
     */
    public class func toStringTree(t: Tree, _ ruleNames: Array<String>?) -> String {
        var s: String = Utils.escapeWhitespace(getNodeText(t, ruleNames), false)
        if t.getChildCount() == 0 {
            return s
        }
        let buf: StringBuilder = StringBuilder()
        buf.append("(")
        s = Utils.escapeWhitespace(getNodeText(t, ruleNames), false)
        buf.append(s)
        buf.append(" ")
        for var i: Int = 0; i < t.getChildCount(); i++ {
            if i > 0 {
                buf.append(" ")
            }
            buf.append(toStringTree(t.getChild(i)!, ruleNames))
        }
        buf.append(")")
        return buf.toString()
    }

    public class func getNodeText(t: Tree, _ recog: Parser?) -> String {
        let ruleNames: [String]? = recog != nil ? recog!.getRuleNames() : nil
        let ruleNamesList: Array<String>? = ruleNames != nil ? ruleNames : nil
        return getNodeText(t, ruleNamesList)
    }

    public class func getNodeText(t: Tree, _ ruleNames: Array<String>?) -> String {
        if ruleNames != nil {
            if t is RuleNode {
                let ruleIndex: Int = (t as! RuleNode).getRuleContext().getRuleIndex()
                let ruleName: String = ruleNames![ruleIndex]
                return ruleName
            } else {
                if t is ErrorNode {
                    return (t as! ErrorNode).description
                } else {
                    if t is TerminalNode {
                        let symbol: Token? = (t as! TerminalNode).getSymbol()
                        if symbol != nil {
                            let s: String = symbol!.getText()!
                            return s
                        }
                    }
                }
            }
        }
        // no recog for rule names
        let payload: AnyObject = t.getPayload()
        if payload is Token {
            return (payload as! Token).getText()!
        }
        return "\(t.getPayload())"

    }

    /** Return ordered list of all children of this node */
    public class func getChildren(t: Tree) -> Array<Tree> {
        var kids: Array<Tree> = Array<Tree>()
        for var i: Int = 0; i < t.getChildCount(); i++ {
            kids.append(t.getChild(i)!)
        }
        return kids
    }

    /** Return a list of all ancestors of this node.  The first node of
     *  list is the root and the last is the parent of this node.
     */

    public class func getAncestors(t: Tree) -> Array<Tree> {
        var ancestors: Array<Tree> = Array<Tree>()
        if t.getParent() == nil {

            return ancestors
            //return Collections.emptyList();
        }

        var tp = t.getParent()
        while tp != nil {
            ancestors.insert(t, atIndex: 0)
            //ancestors.add(0, t); // insert at start
            tp = tp!.getParent()
        }
        return ancestors
    }

    public class func findAllTokenNodes(t: ParseTree, _ ttype: Int) -> Array<ParseTree> {
        return findAllNodes(t, ttype, true)
    }

    public class func findAllRuleNodes(t: ParseTree, _ ruleIndex: Int) -> Array<ParseTree> {
        return findAllNodes(t, ruleIndex, false)
    }

    public class func findAllNodes(t: ParseTree, _ index: Int, _ findTokens: Bool) -> Array<ParseTree> {
        var nodes: Array<ParseTree> = Array<ParseTree>()
        _findAllNodes(t, index, findTokens, &nodes)
        return nodes
    }

    public class func _findAllNodes(t: ParseTree,
                                    _ index: Int, _ findTokens: Bool, inout _ nodes: Array<ParseTree>) {
        // check this node (the root) first
        if findTokens && t is TerminalNode {
            let tnode: TerminalNode = t as! TerminalNode
            if tnode.getSymbol()!.getType() == index {
                nodes.append(t)
            }
        } else {
            if !findTokens && t is ParserRuleContext {
                let ctx: ParserRuleContext = t as! ParserRuleContext
                if ctx.getRuleIndex() == index {
                    nodes.append(t)
                }
            }
        }
        // check children
        for var i: Int = 0; i < t.getChildCount(); i++ {
            _findAllNodes(t.getChild(i) as! ParseTree, index, findTokens, &nodes)
        }
    }

    public class func descendants(t: ParseTree) -> Array<ParseTree> {
        var nodes: Array<ParseTree> = Array<ParseTree>()
        nodes.append(t)

        let n: Int = t.getChildCount()
        for var i: Int = 0; i < n; i++ {

            //nodes.addAll(descendants(t.getChild(i)));
            let child = t.getChild(i)
            if child != nil {
                nodes.concat(descendants(child as! ParseTree))
            }

        }
        return nodes
    }

    /** Find smallest subtree of t enclosing range startTokenIndex..stopTokenIndex
     *  inclusively using postorder traversal.  Recursive depth-first-search.
     *
     *  @since 4.5.1
     */
    public class func getRootOfSubtreeEnclosingRegion(t: ParseTree,
                                                      _ startTokenIndex: Int,
                                                      _ stopTokenIndex: Int) -> ParserRuleContext? {
        let n: Int = t.getChildCount()

        for var i: Int = 0; i < n; i++ {
            //TODO t.getChild(i) nil
            let child: ParseTree? = t.getChild(i) as? ParseTree
            //Added by janyou
            if child == nil {
                return nil
            }
            let r: ParserRuleContext? = getRootOfSubtreeEnclosingRegion(child!, startTokenIndex, stopTokenIndex)
            if r != nil {
                return r!
            }
        }
        if t is ParserRuleContext {
            let r: ParserRuleContext = t as! ParserRuleContext
            if startTokenIndex >= r.getStart()!.getTokenIndex() && // is range fully contained in t?
                    stopTokenIndex <= r.getStop()!.getTokenIndex() {
                return r
            }
        }
        return nil
    }

    private init() {
    }
}
