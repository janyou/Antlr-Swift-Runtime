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


/** A rule invocation record for parsing.
 *
 *  Contains all of the information about the current rule not stored in the
 *  RuleContext. It handles parse tree children list, Any ATN state
 *  tracing, and the default values available for rule invocations:
 *  start, stop, rule index, current alt number.
 *
 *  Subclasses made for each rule and grammar track the parameters,
 *  return values, locals, and labels specific to that rule. These
 *  are the objects that are returned from rules.
 *
 *  Note text is not an actual field of a rule return value; it is computed
 *  from start and stop using the input stream's toString() method.  I
 *  could add a ctor to this so that we can pass in and store the input
 *  stream, but I'm not sure we want to do that.  It would seem to be undefined
 *  to get the .text property anyway if the rule matches tokens from multiple
 *  input streams.
 *
 *  I do not use getters for fields of objects that are used simply to
 *  group values such as this aggregate.  The getters/setters are there to
 *  satisfy the superclass interface.
 */

public class ParserRuleContext: RuleContext {
    public var visited = false
    /** If we are debugging or building a parse tree for a visitor,
     *  we need to track all of the tokens and rule invocations associated
     *  with this rule's context. This is empty for parsing w/o tree constr.
     *  operation because we don't the need to track the details about
     *  how we parse this rule.
     */
    public var children: Array<ParseTree>?

    /** For debugging/tracing purposes, we want to track all of the nodes in
     *  the ATN traversed by the parser for a particular rule.
     *  This list indicates the sequence of ATN nodes used to match
     *  the elements of the children list. This list does not include
     *  ATN nodes and other rules used to match rule invocations. It
     *  traces the rule invocation node itself but nothing inside that
     *  other rule's ATN submachine.
     *
     *  There is NOT a one-to-one correspondence between the children and
     *  states list. There are typically many nodes in the ATN traversed
     *  for each element in the children list. For example, for a rule
     *  invocation there is the invoking state and the following state.
     *
     *  The parser setState() method updates field s and adds it to this list
     *  if we are debugging/tracing.
     *
     *  This does not trace states visited during prediction.
     */
//	public List<Integer> states;

    public var start: Token?, stop: Token?

    /**
     * The exception that forced this rule to return. If the rule successfully
     * completed, this is {@code null}.
     */
    public var exception: AnyObject!
    //RecognitionException<ATNSimulator>!;

    public override init() {
        super.init()
    }

    /** COPY a ctx (I'm deliberately not using copy constructor) to avoid
     *  confusion with creating node with parent. Does not copy children.
     */
    public func copyFrom(ctx: ParserRuleContext) {
        self.parent = ctx.parent
        self.invokingState = ctx.invokingState

        self.start = ctx.start
        self.stop = ctx.stop
    }

    public init(_ parent: ParserRuleContext?, _ invokingStateNumber: Int) {
        super.init(parent, invokingStateNumber)
    }

    // Double dispatch methods for listeners

    public func enterRule(listener: ParseTreeListener) {
    }

    public func exitRule(listener: ParseTreeListener) {
    }

    /** Does not set parent link; other add methods do that */
    public func addChild(t: TerminalNode) -> TerminalNode {
        if children == nil {
            children = Array<ParseTree>()
        }
        children!.append(t)
        return t
    }

    public func addChild(ruleInvocation: RuleContext) -> RuleContext {
        if children == nil {
            children = Array<ParseTree>()
        }
        children!.append(ruleInvocation)
        return ruleInvocation
    }

    /** Used by enterOuterAlt to toss out a RuleContext previously added as
     *  we entered a rule. If we have # label, we will need to remove
     *  generic ruleContext object.
      */
    public func removeLastChild() {
        if children != nil {
            children!.removeLast()

            //children.remove(children.size()-1);
        }
    }

//	public void trace(int s) {
//		if ( states==null ) states = new ArrayList<Integer>();
//		states.add(s);
//	}

    public func addChild(matchedToken: Token) -> TerminalNode {
        let t: TerminalNodeImpl = TerminalNodeImpl(matchedToken)
        addChild(t)
        t.parent = self
        return t
    }

    public func addErrorNode(badToken: Token) -> ErrorNode {
        let t: ErrorNode = ErrorNode(badToken)
        addChild(t)
        t.parent = self
        return t
    }

    override
    /** Override to make type more specific */
    public func getParent() -> Tree? {
        return super.getParent()
    }

    override
    public func getChild(i: Int) -> Tree? {
        return (children != nil && i >= 0 && i < children!.count) ? children![i] : nil
    }

    public func getChild<T:ParseTree>(ctxType: T.Type, i: Int) -> T? {
        if children == nil || i < 0 || i >= children!.count {
            return nil
        }

        var j: Int = -1 // what element have we found with ctxType?
        for o: ParseTree in children! {
            //if ( ctxType.isInstance(o) ) {
            if o is T {
                j += 1
                if j == i {
                    return o as? T//ctxType.cast(o);
                }
            }
        }
        return nil
    }

    public func getToken(ttype: Int, _ i: Int) -> TerminalNode? {
        if children == nil || i < 0 || i >= children!.count {
            return nil
        }

        var j: Int = -1 // what token with ttype have we found?
        for o: ParseTree in children! {
            if o is TerminalNode {
                let tnode: TerminalNode = o as! TerminalNode
                let symbol: Token = tnode.getSymbol()!
                if symbol.getType() == ttype {
                    j += 1
                    if j == i {
                        return tnode
                    }
                }
            }
        }

        return nil
    }

    public func getTokens(ttype: Int) -> Array<TerminalNode> {
        if children == nil {
            return Array<TerminalNode>()
        }

        var tokens: Array<TerminalNode>? = nil
        for o: ParseTree in children! {
            if o is TerminalNode {
                let tnode: TerminalNode = o as! TerminalNode
                let symbol: Token = tnode.getSymbol()!
                if symbol.getType() == ttype {
                    if tokens == nil {
                        tokens = Array<TerminalNode>()
                    }
                    tokens?.append(tnode)
                }
            }
        }

        if tokens == nil {
            return Array<TerminalNode>()
        }

        return tokens!
    }

    public func getRuleContext<T:ParserRuleContext>(ctxType: T.Type, _ i: Int) -> T? {

        return getChild(ctxType, i: i)
    }

    public func getRuleContexts<T:ParserRuleContext>(ctxType: T.Type) -> Array<T> {

        if children == nil {
            return Array<T>()//Collections.emptyList();
        }

        var contexts: Array<T>? = nil
        for o: ParseTree in children! {
            if o is T {
                if contexts == nil {
                    contexts = Array<T>()
                }
                contexts!.append(o as! T)
                //contexts.(ctxType.cast(o));
            }
        }

        if contexts == nil {
            return Array<T>() //Collections.emptyList();
        }

        return contexts!
    }

    override
    public func getChildCount() -> Int {
        return children != nil ? children!.count : 0
    }

    override
    public func getSourceInterval() -> Interval {
        if start == nil || stop == nil {
            return Interval.INVALID
        }
        return Interval.of(start!.getTokenIndex(), stop!.getTokenIndex())
    }

    /**
     * Get the initial token in this context.
     * Note that the range from start to stop is inclusive, so for rules that do not consume anything
     * (for example, zero length or error productions) this token may exceed stop.
     */
    public func getStart() -> Token? {
        return start
    }
    /**
     * Get the final token in this context.
     * Note that the range from start to stop is inclusive, so for rules that do not consume anything
     * (for example, zero length or error productions) this token may precede start.
     */
    public func getStop() -> Token? {
        return stop
    }

    /** Used for rule context info debugging during parse-time, not so much for ATN debugging */
    public func toInfoString(recognizer: Parser) -> String {
        var rules: Array<String> = recognizer.getRuleInvocationStack(self)
        // Collections.reverse(rules);
        rules = rules.reverse()
        return "ParserRuleContext\(rules){start= + \(start), stop=\(stop)}"

    }
}
