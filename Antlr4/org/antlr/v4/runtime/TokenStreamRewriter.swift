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


/**
* Useful for rewriting out a buffered input token stream after doing some
* augmentation or other manipulations on it.
*
* <p>
* You can insert stuff, replace, and delete chunks. Note that the operations
* are done lazily--only if you convert the buffer to a {@link String} with
* {@link org.antlr.v4.runtime.TokenStream#getText()}. This is very efficient because you are not
* moving data around all the time. As the buffer of tokens is converted to
* strings, the {@link #getText()} method(s) scan the input token stream and
* check to see if there is an operation at the current index. If so, the
* operation is done and then normal {@link String} rendering continues on the
* buffer. This is like having multiple Turing machine instruction streams
* (programs) operating on a single input tape. :)</p>
*
* <p>
* This rewriter makes no modifications to the token stream. It does not ask the
* stream to fill itself up nor does it advance the input cursor. The token
* stream {@link org.antlr.v4.runtime.TokenStream#index()} will return the same value before and
* after any {@link #getText()} call.</p>
*
* <p>
* The rewriter only works on tokens that you have in the buffer and ignores the
* current input cursor. If you are buffering tokens on-demand, calling
* {@link #getText()} halfway through the input will only do rewrites for those
* tokens in the first half of the file.</p>
*
* <p>
* Since the operations are done lazily at {@link #getText}-time, operations do
* not screw up the token index values. That is, an insert operation at token
* index {@code i} does not change the index values for tokens
* {@code i}+1..n-1.</p>
*
* <p>
* Because operations never actually alter the buffer, you may always get the
* original token stream back without undoing anything. Since the instructions
* are queued up, you can easily simulate transactions and roll back any changes
* if there is an error just by removing instructions. For example,</p>
*
* <pre>
* CharStream input = new ANTLRFileStream("input");
* TLexer lex = new TLexer(input);
* CommonTokenStream tokens = new CommonTokenStream(lex);
* T parser = new T(tokens);
* TokenStreamRewriter rewriter = new TokenStreamRewriter(tokens);
* parser.startRule();
* </pre>
*
* <p>
* Then in the rules, you can execute (assuming rewriter is visible):</p>
*
* <pre>
* Token t,u;
* ...
* rewriter.insertAfter(t, "text to put after t");}
* rewriter.insertAfter(u, "text after u");}
* System.out.println(rewriter.getText());
* </pre>
*
* <p>
* You can also have multiple "instruction streams" and get multiple rewrites
* from a single pass over the input. Just name the instruction streams and use
* that name again when printing the buffer. This could be useful for generating
* a C file and also its header file--all from the same buffer:</p>
*
* <pre>
* rewriter.insertAfter("pass1", t, "text to put after t");}
* rewriter.insertAfter("pass2", u, "text after u");}
* System.out.println(rewriter.getText("pass1"));
* System.out.println(rewriter.getText("pass2"));
* </pre>
*
* <p>
* If you don't use named rewrite streams, a "default" stream is used as the
* first example shows.</p>
*/

import Foundation

public class TokenStreamRewriter {
    public let DEFAULT_PROGRAM_NAME: String = "default"
    public static let PROGRAM_INIT_SIZE: Int = 100
    public let MIN_TOKEN_INDEX: Int = 0
    
    // Define the rewrite operation hierarchy

    
    public class RewriteOperation: CustomStringConvertible {
        /** What index into rewrites List are we? */
        internal var instructionIndex: Int = 0
        /** Token buffer index. */
        internal var index: Int
        internal var text: AnyObject?
        weak var  tokens: TokenStream!
        init(_ index: Int, _ tokens: TokenStream) {
            self.index = index
            self.tokens = tokens
        }
        //_ tokens : TokenStream  ,_ tokens : TokenStream
        init(_ index: Int, _ text: AnyObject?, _ tokens: TokenStream) {
            self.index = index
            self.text = text
            self.tokens = tokens
        }
        /** Execute the rewrite operation by possibly adding to the buffer.
         *  Return the index of the next token to operate on.
         */
        public func execute(buf: StringBuilder) throws -> Int {
            return index
        }
        
        public var description: String {
            let opName: String = NSStringFromClass(RewriteOperation.self)
            //  var index : Int = opName.indexOf("$");
            //  opName =    opName.substring(   index+1);
            return "<\(opName) @ \(try? tokens.get(index)):\\(text as! String)\">"
        }
        
    }
    
    public final class InsertBeforeOp: RewriteOperation {
        public override init(_ index: Int, _ text: AnyObject?, _ tokens: TokenStream) {
            super.init(index, text, tokens)
        }
        
        override
        public func execute(buf: StringBuilder) throws -> Int {
            buf.append(text as! String)
            if try tokens.get(index).getType() != CommonToken.EOF {
                buf.append(try tokens.get(index).getText()!)
            }
            return index + 1
        }
    }
    
    /** I'm going to try replacing range from x..y with (y-x)+1 ReplaceOp
     *  instructions.
     */
    
    public final class ReplaceOp: RewriteOperation {
        internal var lastIndex: Int
        public init(_ from: Int, _ to: Int, _ text: AnyObject?, _ tokens: TokenStream) {
            
            lastIndex = to
            super.init(from, text, tokens)
        }
        
        override
        public func execute(buf: StringBuilder) -> Int {
            if text != nil {
                buf.append(text as! String)
            }
            return lastIndex + 1
        }
        override
        public var description: String {
            if text == nil {
                return "<DeleteOp@\(try? tokens.get(index))..\(try? tokens.get(lastIndex))>"
            }
            return "<ReplaceOp@\(try? tokens.get(index))..\(try? tokens.get(lastIndex)):\\(text)>"
        }
        
    }
    
    
    
    
    public final class RewriteOperationArray{
        public var array: Array<RewriteOperation?> =  Array<RewriteOperation?>()
        public init(){
            array.reserveCapacity(TokenStreamRewriter.PROGRAM_INIT_SIZE)
        }
    }
    
    /** Our source stream */
    internal var tokens: TokenStream
    
    /** You may have multiple, named streams of rewrite operations.
     *  I'm calling these things "programs."
     *  Maps String (name) &rarr; rewrite (List)
     */
    internal var programs: Dictionary<String, RewriteOperationArray> //Array<RewriteOperation>
    
    /** Map String (program name) &rarr; Integer index */
    internal final var lastRewriteTokenIndexes: Dictionary<String, Int>
    
    public init(_ tokens: TokenStream) {
        self.tokens = tokens
        programs = Dictionary<String, RewriteOperationArray>()
        programs[DEFAULT_PROGRAM_NAME] = RewriteOperationArray()
        lastRewriteTokenIndexes = Dictionary<String, Int>()
    }
    
    public final func getTokenStream() -> TokenStream {
        return tokens
    }
    
    public func rollback(instructionIndex: Int) {
        rollback(DEFAULT_PROGRAM_NAME, instructionIndex)
    }
    
    /** Rollback the instruction stream for a program so that
     *  the indicated instruction (via instructionIndex) is no
     *  longer in the stream. UNTESTED!
     */
    public func rollback(programName: String, _ instructionIndex: Int) {
        //Array<RewriteOperation>
        let program: RewriteOperationArray? = programs[programName]
        if program != nil {
            program!.array = Array( program!.array[MIN_TOKEN_INDEX ..< instructionIndex])
        }
    }
    
    public func deleteProgram() {
        deleteProgram(DEFAULT_PROGRAM_NAME)
    }
    
    /** Reset the program so that no instructions exist */
    public func deleteProgram(programName: String) {
        rollback(programName, MIN_TOKEN_INDEX)
    }
    
    public func insertAfter(t: Token, _ text: AnyObject) {
        insertAfter(DEFAULT_PROGRAM_NAME, t, text)
    }
    
    public func insertAfter(index: Int, _ text: AnyObject) {
        insertAfter(DEFAULT_PROGRAM_NAME, index, text)
    }
    
    public func insertAfter(programName: String, _ t: Token, _ text: AnyObject) {
        insertAfter(programName, t.getTokenIndex(), text)
    }
    
    public func insertAfter(programName: String, _ index: Int, _ text: AnyObject) {
        // to insert after, just insert before next index (even if past end)
        insertBefore(programName, index + 1, text)
    }
    
    public func insertBefore(t: Token, _ text: AnyObject) {
        insertBefore(DEFAULT_PROGRAM_NAME, t, text)
    }
    
    public func insertBefore(index: Int, _ text: AnyObject) {
        insertBefore(DEFAULT_PROGRAM_NAME, index, text)
    }
    
    public func insertBefore(programName: String, _ t: Token, _ text: AnyObject) {
        insertBefore(programName, t.getTokenIndex(), text)
    }
    
    public func insertBefore(programName: String, _ index: Int, _ text: AnyObject) {
        let op: RewriteOperation = InsertBeforeOp(index, text, tokens)
        //var rewrites: Array<RewriteOperation> = getProgram(programName)
        let rewrites: RewriteOperationArray = getProgram(programName)
        op.instructionIndex = rewrites.array.count
        rewrites.array.append(op)
    }
    
    public func replace(index: Int, _ text: AnyObject) throws {
        try replace(DEFAULT_PROGRAM_NAME, index, index, text)
    }
    
    public func replace(from: Int, _ to: Int, _ text: AnyObject) throws {
        try replace(DEFAULT_PROGRAM_NAME, from, to, text)
    }
    
    public func replace(indexT: Token, _ text: AnyObject) throws {
        try replace(DEFAULT_PROGRAM_NAME, indexT, indexT, text)
    }
    
    public func replace(from: Token, _ to: Token, _ text: AnyObject) throws {
        try  replace(DEFAULT_PROGRAM_NAME, from, to, text)
    }
    
    public func replace(programName: String, _ from: Int, _ to: Int, _ text: AnyObject?) throws {
        if from > to || from < 0 || to < 0 || to >= tokens.size() {
            throw ANTLRError.IllegalArgument(msg: "replace: range invalid: \(from)..\(to)(size=\(tokens.size()))")
        }
        let op: RewriteOperation = ReplaceOp(from, to, text, tokens)
        //var rewrites: Array<RewriteOperation> = getProgram(programName)
        let rewrites: RewriteOperationArray = getProgram(programName)
        op.instructionIndex = rewrites.array.count
        rewrites.array.append(op)
    }
    
    public func replace(programName: String, _ from: Token, _ to: Token, _ text: AnyObject?) throws {
        try replace(programName,
            from.getTokenIndex(),
            to.getTokenIndex(),
            text)
    }
    
    public func delete(index: Int) throws {
        try delete(DEFAULT_PROGRAM_NAME, index, index)
    }
    
    public func delete(from: Int, _ to: Int) throws {
        try delete(DEFAULT_PROGRAM_NAME, from, to)
    }
    
    public func delete(indexT: Token) throws {
        try delete(DEFAULT_PROGRAM_NAME, indexT, indexT)
    }
    
    public func delete(from: Token, _ to: Token) throws {
        try delete(DEFAULT_PROGRAM_NAME, from, to)
    }
    
    public func delete(programName: String, _ from: Int, _ to: Int) throws {
        try replace(programName, from, to, nil)
    }
    
    public func delete(programName: String, _ from: Token, _ to: Token) throws {
        try replace(programName, from, to, nil)
    }
    
    public func getLastRewriteTokenIndex() -> Int {
        return getLastRewriteTokenIndex(DEFAULT_PROGRAM_NAME)
    }
    
    internal func getLastRewriteTokenIndex(programName: String) -> Int {
        let I: Int? = lastRewriteTokenIndexes[programName]
        if I == nil {
            return -1
        }
        return I!
    }
    
    internal func setLastRewriteTokenIndex(programName: String, _ i: Int) {
        lastRewriteTokenIndexes[programName] = i
    }
    
    internal func getProgram(name: String) -> RewriteOperationArray
    {
        //Array<RewriteOperation>?
        var program: RewriteOperationArray? = programs[name]
        if program == nil {
            program = initializeProgram(name)
        }
        return program!
    }
    
    private func initializeProgram(name: String) -> RewriteOperationArray
    {
        //Array<RewriteOperation>
        let program: RewriteOperationArray = RewriteOperationArray()
        
        programs[name] = program
        return program
    }
    
    /** Return the text from the original tokens altered per the
     *  instructions given to this rewriter.
     */
    public func getText() throws -> String {
        return try getText(DEFAULT_PROGRAM_NAME, Interval.of(0, tokens.size() - 1))
    }
    
    /** Return the text from the original tokens altered per the
     *  instructions given to this rewriter in programName.
     */
    public func getText(programName: String) throws -> String {
        return try getText(programName, Interval.of(0, tokens.size() - 1))
    }
    
    /** Return the text associated with the tokens in the interval from the
     *  original token stream but with the alterations given to this rewriter.
     *  The interval refers to the indexes in the original token stream.
     *  We do not alter the token stream in any way, so the indexes
     *  and intervals are still consistent. Includes any operations done
     *  to the first and last token in the interval. So, if you did an
     *  insertBefore on the first token, you would get that insertion.
     *  The same is true if you do an insertAfter the stop token.
     */
    public func getText(interval: Interval) throws -> String {
        return try getText(DEFAULT_PROGRAM_NAME, interval)
    }
    
    public func getText(programName: String, _ interval: Interval) throws -> String {
        // var rewrites: Array<RewriteOperation?>? = programs[programName]
        let rewrites: RewriteOperationArray?  = programs[programName]
        var start: Int = interval.a
        var stop: Int = interval.b
        
        // ensure start/end are in range
        if stop > tokens.size() - 1 {
            stop = tokens.size() - 1
        }
        if start < 0 {
            start = 0
        }
        
        if rewrites == nil || rewrites!.array.isEmpty {
            return try tokens.getText(interval) // no instructions to execute
        }
        let buf: StringBuilder = StringBuilder()
        
        // First, optimize instruction stream
        var indexToOp: Dictionary<Int, RewriteOperation> = try  TokenStreamRewriter.reduceToSingleOperationPerIndex(&rewrites!.array)
        
        // Walk buffer, executing instructions and emitting tokens
        var i: Int = start
        while i <= stop && i < tokens.size() {
            let op: RewriteOperation? = indexToOp[i]
            indexToOp.removeValueForKey(i)
            //indexToOp.remove(i); // remove so any left have index size-1
            let t: Token = try tokens.get(i)
            if op == nil {
                // no operation at that index, just dump token
                if t.getType() != CommonToken.EOF {
                    buf.append(t.getText()!)
                }
                i++ // move to next token
            } else {
                i = try op!.execute(buf) // execute operation and skip
            }
        }
        
        // include stuff after end if it's last index in buffer
        // So, if they did an insertAfter(lastValidIndex, "foo"), include
        // foo if end==lastValidIndex.
        if stop == tokens.size() - 1 {
            // Scan any remaining operations after last token
            // should be included (they will be inserts).
            for op: RewriteOperation in indexToOp.values {
                if op.index >= tokens.size() - 1 {
                    buf.append(op.text as! String)
                }
            }
        }
        return buf.toString()
    }
    
    /** We need to combine operations and report invalid operations (like
     *  overlapping replaces that are not completed nested). Inserts to
     *  same index need to be combined etc...  Here are the cases:
     *
     *  I.i.u I.j.v                             leave alone, nonoverlapping
     *  I.i.u I.i.v                             combine: Iivu
     *
     *  R.i-j.u R.x-y.v | i-j in x-y            delete first R
     *  R.i-j.u R.i-j.v                         delete first R
     *  R.i-j.u R.x-y.v | x-y in i-j            ERROR
     *  R.i-j.u R.x-y.v | boundaries overlap    ERROR
     *
     *  Delete special case of replace (text==null):
     *  D.i-j.u D.x-y.v | boundaries overlap    combine to max(min)..max(right)
     *
     *  I.i.u R.x-y.v | i in (x+1)-y            delete I (since insert before
     *                                          we're not deleting i)
     *  I.i.u R.x-y.v | i not in (x+1)-y        leave alone, nonoverlapping
     *  R.x-y.v I.i.u | i in x-y                ERROR
     *  R.x-y.v I.x.u                           R.x-y.uv (combine, delete I)
     *  R.x-y.v I.i.u | i not in x-y            leave alone, nonoverlapping
     *
     *  I.i.u = insert u before op @ index i
     *  R.x-y.u = replace x-y indexed tokens with u
     *
     *  First we need to examine replaces. For any replace op:
     *
     *      1. wipe out any insertions before op within that range.
     *      2. Drop any replace op before that is contained completely within
     *   that range.
     *      3. Throw exception upon boundary overlap with any previous replace.
     *
     *  Then we can deal with inserts:
     *
     *      1. for any inserts to same index, combine even if not adjacent.
     *      2. for any prior replace with same left boundary, combine this
     *   insert with replace and delete this replace.
     *      3. throw exception if index in same range as previous replace
     *
     *  Don't actually delete; make op null in list. Easier to walk list.
     *  Later we can throw as we add to index &rarr; op map.
     *
     *  Note that I.2 R.2-2 will wipe out I.2 even though, technically, the
     *  inserted stuff would be before the replace range. But, if you
     *  add tokens in front of a method body '{' and then delete the method
     *  body, I think the stuff before the '{' you added should disappear too.
     *
     *  Return a map from token index to operation.
     */
    static func reduceToSingleOperationPerIndex(inout rewrites: Array<RewriteOperation?>) throws -> Dictionary<Int, RewriteOperation> {
        
        let rewritesCount = rewrites.count
        // WALK REPLACES
        for i in 0..<rewritesCount {
            if let rop: ReplaceOp = rewrites[i] as? ReplaceOp {
                // Wipe prior inserts within range
                let inserts: Array<InsertBeforeOp> = getKindOfOps(rewrites, InsertBeforeOp.self, i)
                for iop: InsertBeforeOp in inserts {
                    if iop.index == rop.index {
                        // E.g., insert before 2, delete 2..2; update replace
                        // text to include insert before, kill insert
                        rewrites[iop.instructionIndex] = nil
                        rop.text = (iop.text as! CustomStringConvertible).description + (rop.text != nil ? (rop.text as! CustomStringConvertible).description : "")
                    } else {
                        if iop.index > rop.index && iop.index <= rop.lastIndex {
                            // delete insert as it's a no-op.
                            rewrites[iop.instructionIndex] = nil
                        }
                    }
                }
                // Drop any prior replaces contained within
                let prevReplaces: Array<ReplaceOp> = getKindOfOps(rewrites, ReplaceOp.self, i)
                for prevRop: ReplaceOp in prevReplaces {
                    if prevRop.index >= rop.index && prevRop.lastIndex <= rop.lastIndex {
                        // delete replace as it's a no-op.
                        rewrites[prevRop.instructionIndex] = nil
                        continue
                    }
                    // throw exception unless disjoint or identical
                    let disjoint: Bool =
                    prevRop.lastIndex < rop.index || prevRop.index > rop.lastIndex
                    let same: Bool =
                    prevRop.index == rop.index && prevRop.lastIndex == rop.lastIndex
                    // Delete special case of replace (text==null):
                    // D.i-j.u D.x-y.v  | boundaries overlap    combine to max(min)..max(right)
                    if prevRop.text == nil && rop.text == nil && !disjoint {
                        //System.out.println("overlapping deletes: "+prevRop+", "+rop);
                        rewrites[prevRop.instructionIndex] = nil // kill first delete
                        rop.index = min(prevRop.index, rop.index)
                        rop.lastIndex = max(prevRop.lastIndex, rop.lastIndex)
                        print("new rop " + rop.description)
                    } else {
                        if !disjoint && !same {
                            throw ANTLRError.IllegalArgument(msg: "replace op boundaries of " + rop.description + " overlap with previous " + prevRop.description)
                            // RuntimeException("replace op boundaries of " + rop.description + " overlap with previous "+prevRop.description)
                            //throwException() /* throw IllegalArgumentException("replace op boundaries of "+rop+" overlap with previous "+prevRop); */
                        }
                    }
                }
            }
        }
        
        // WALK INSERTS
        for i in 0..<rewritesCount {
            if let iop: InsertBeforeOp = rewrites[i] as? InsertBeforeOp {
                // combine current insert with prior if any at same index
                let prevInserts: Array<InsertBeforeOp> = getKindOfOps(rewrites, InsertBeforeOp.self, i)
                for prevIop: InsertBeforeOp in prevInserts {
                    if prevIop.index == iop.index {
                        // combine objects
                        // convert to strings...we're in process of toString'ing
                        // whole token buffer so no lazy eval issue with any templates
                        iop.text = catOpText(iop.text!, prevIop.text!)
                        // delete redundant prior insert
                        rewrites[prevIop.instructionIndex] = nil
                    }
                }
                // look for replaces where iop.index is in range; error
                let prevReplaces: Array<ReplaceOp> = getKindOfOps(rewrites, ReplaceOp.self, i)
                for rop: ReplaceOp in prevReplaces {
                    if iop.index == rop.index {
                        rop.text = catOpText(iop.text, rop.text)
                        rewrites[i] = nil    // delete current insert
                        continue
                    }
                    if iop.index >= rop.index && iop.index <= rop.lastIndex {
                        throw ANTLRError.IllegalArgument(msg: "insert op " + iop.description + " within boundaries of previous " + rop.description)
                        
                    }
                }
            }
        }
        
        var m: Dictionary<Int, RewriteOperation> = Dictionary<Int, RewriteOperation>()
        for i in 0..<rewritesCount {
            if let op: RewriteOperation = rewrites[i] {
                if m[op.index] != nil {
                    throw ANTLRError.IllegalArgument(msg: "should only be one op per index")
                }
                m[op.index] = op
            }
        }
        
        return m
    }
    
    static func catOpText(a: AnyObject?, _ b: AnyObject?) -> String {
        let x: String = a?.description ?? ""
        let y: String = b?.description ?? ""

        return x + y
    }
    
    /** Get all operations before an index of a particular kind */
    static  func getKindOfOps<T: RewriteOperation>(rewrites: Array<RewriteOperation?>, _ kind: T.Type, _ before: Int) ->  Array<T> {
        var ops: Array<T> = Array<T>()
        let length =  min(before,rewrites.count)
        ops.reserveCapacity(length)
        
        for i in 0..<length {
            if let op: RewriteOperation = rewrites[i] {
                if op is T {
                    ops.append(op as! T)
                }
            }
        }
        
        return ops
    }
}
