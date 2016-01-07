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


/** A lexer is recognizer that draws input symbols from a character stream.
 *  lexer grammars result in a subclass of this object. A Lexer object
 *  uses simplified match() and error recovery mechanisms in the interest
 *  of speed.
 */

import Foundation

//public  class Lexer  :  Recognizer<Int, LexerATNSimulator>

public class Lexer: Recognizer<LexerATNSimulator>
        , TokenSource {
    public static let EOF: Int = -1
    public static let DEFAULT_MODE: Int = 0
    public static let MORE: Int = -2
    public static let SKIP: Int = -3

    public static let DEFAULT_TOKEN_CHANNEL: Int = CommonToken.DEFAULT_CHANNEL
    public static let HIDDEN: Int = CommonToken.HIDDEN_CHANNEL
    public static let MIN_CHAR_VALUE: Int = Character("\u{0000}").unicodeValue
    public static let MAX_CHAR_VALUE: Int = Character("\u{FFFE}").unicodeValue

    public var _input: CharStream?
    internal var _tokenFactorySourcePair: (TokenSource?, CharStream?)

    /** How to create token objects */
    internal var _factory: TokenFactory = CommonTokenFactory.DEFAULT

    /** The goal of all lexer rules/methods is to create a token object.
     *  This is an instance variable as multiple rules may collaborate to
     *  create a single token.  nextToken will return this object after
     *  matching lexer rule(s).  If you subclass to allow multiple token
     *  emissions, then set this to the last token to be matched or
     *  something nonnull so that the auto token emit mechanism will not
     *  emit another token.
     */
    public var _token: Token?

    /** What character index in the stream did the current token start at?
     *  Needed, for example, to get the text for current token.  Set at
     *  the start of nextToken.
     */
    public var _tokenStartCharIndex: Int = -1

    /** The line on which the first character of the token resides */
    public var _tokenStartLine: Int = 0

    /** The character position of first character within the line */
    public var _tokenStartCharPositionInLine: Int = 0

    /** Once we see EOF on char stream, next token will be EOF.
     *  If you have DONE : EOF ; then you see DONE EOF.
     */
    public var _hitEOF: Bool = false

    /** The channel number for the current token */
    public var _channel: Int = 0

    /** The token type for the current token */
    public var _type: Int = 0

    public final var _modeStack: Stack<Int> = Stack<Int>()
    public var _mode: Int = Lexer.DEFAULT_MODE

    /** You can set the text for the current token to override what is in
     *  the input char buffer.  Use setText() or can set this instance var.
     */
    public var _text: String?

    public override init() {
    }

    public init(_ input: CharStream) {

        super.init()
        self._input = input
        self._tokenFactorySourcePair = (self, input)
    }

    public func reset() throws {
        // wack Lexer state variables
        if _input != nil {
            try  _input!.seek(0) // rewind the input
        }
        _token = nil
        _type = CommonToken.INVALID_TYPE
        _channel = CommonToken.DEFAULT_CHANNEL
        _tokenStartCharIndex = -1
        _tokenStartCharPositionInLine = -1
        _tokenStartLine = -1
        _text = nil

        _hitEOF = false
        _mode = Lexer.DEFAULT_MODE
        _modeStack.clear()

        getInterpreter().reset()
    }

    /** Return a token from this source; i.e., match a token on the char
     *  stream.
     */

    public func nextToken() throws -> Token {
        if _input == nil {
            throw ANTLRError.IllegalState(msg: "nextToken requires a non-null input stream.")
        }

        // Mark start location in char stream so unbuffered streams are
        // guaranteed at least have text of current token
        var tokenStartMarker: Int = _input!.mark()

        do {
            outer:
            while true {
                if _hitEOF {
                    emitEOF()
                    return _token!
                }

                _token = nil
                _channel = CommonToken.DEFAULT_CHANNEL
                _tokenStartCharIndex = _input!.index()
                _tokenStartCharPositionInLine = getInterpreter().getCharPositionInLine()
                _tokenStartLine = getInterpreter().getLine()
                _text = nil
                repeat {
                    _type = CommonToken.INVALID_TYPE
                    // print("nextToken line \(_tokenStartLine)" + " at \(try _input!.LA(1))" +
                    //   " in mode \(mode)"  +
                    //   " at index \(_input!.index())" );
                    var ttype: Int
                    do {
                        ttype = try getInterpreter().match(_input!, _mode)
                    }
                    catch  ANTLRException.Recognition(let e) {
                        notifyListeners(e as! LexerNoViableAltException, recognizer: self)
                        try recover(e as! LexerNoViableAltException)
                        ttype = Lexer.SKIP
                    }
                    if try _input!.LA(1) == BufferedTokenStream.EOF {
                        _hitEOF = true
                    }
                    if _type == CommonToken.INVALID_TYPE {
                        _type = ttype
                    }
                    if _type == Lexer.SKIP {
                        continue outer
                    }
                } while _type == Lexer.MORE
            
                if _token == nil {
                    emit()
                }
                return _token!
            }
        }
        defer {
            // make sure we release marker after match or
            // unbuffered char stream will keep buffering
            try! _input!.release(tokenStartMarker)
        }
    }

    /** Instruct the lexer to skip creating a token for current lexer rule
     *  and look for another token.  nextToken() knows to keep looking when
     *  a lexer rule finishes with token set to SKIP_TOKEN.  Recall that
     *  if token==null at end of any token rule, it creates one for you
     *  and emits it.
     */
    public func skip() {
        _type = Lexer.SKIP
    }

    public func more() {
        _type = Lexer.MORE
    }

    public func mode(m: Int) {
        _mode = m
    }

    public func pushMode(m: Int) {
        if LexerATNSimulator.debug {
            print("pushMode \(m)")
        }
        _modeStack.push(_mode)
        mode(m)
    }

    public func popMode() throws -> Int {
        if _modeStack.isEmpty {
            throw ANTLRError.UnsupportedOperation(msg: " EmptyStackException")
            //RuntimeException(" EmptyStackException")
            //throwException() /* throw EmptyStackException(); } */
        }

        if LexerATNSimulator.debug {
            print("popMode back to \(_modeStack.peek())")
        }
        mode(_modeStack.pop())
        return _mode
    }


    public override func setTokenFactory(factory: TokenFactory) {
        self._factory = factory
    }


    public override func getTokenFactory() -> TokenFactory {
        return _factory
    }

    /** Set the char stream and reset the lexer */

    public override func setInputStream(input: IntStream) throws {
        self._input = nil
        self._tokenFactorySourcePair = (self, _input!)
        try reset()
        self._input = input as? CharStream
        self._tokenFactorySourcePair = (self, _input!)
    }


    public func getSourceName() -> String {
        return _input!.getSourceName()
    }


    public func getInputStream() -> CharStream? {
        return _input
    }

    /** By default does not support multiple emits per nextToken invocation
     *  for efficiency reasons.  Subclass and override this method, nextToken,
     *  and getToken (to push tokens into a list and pull from that list
     *  rather than a single variable as this implementation does).
     */
    public func emit(token: Token) {
        //System.err.println("emit "+token);
        self._token = token
    }

    /** The standard method called to automatically emit a token at the
     *  outermost lexical rule.  The token object should point into the
     *  char buffer start..stop.  If there is a text override in 'text',
     *  use that to set the token's text.  Override this method to emit
     *  custom Token objects or provide a new factory.
     */
    public func emit() -> Token {
        let t: Token = _factory.create(_tokenFactorySourcePair, _type, _text, _channel, _tokenStartCharIndex, getCharIndex() - 1,
                _tokenStartLine, _tokenStartCharPositionInLine)
        emit(t)
        return t
    }

    public func emitEOF() -> Token {
        let cpos: Int = getCharPositionInLine()
        let line: Int = getLine()
        let eof: Token = _factory.create(
        _tokenFactorySourcePair,
                CommonToken.EOF,
                nil,
                CommonToken.DEFAULT_CHANNEL,
                _input!.index(),
                _input!.index() - 1,
                line,
                cpos)
        emit(eof)
        return eof
    }


    public func getLine() -> Int {
        return getInterpreter().getLine()
    }


    public func getCharPositionInLine() -> Int {
        return getInterpreter().getCharPositionInLine()
    }

    public func setLine(line: Int) {
        getInterpreter().setLine(line)
    }

    public func setCharPositionInLine(charPositionInLine: Int) {
        getInterpreter().setCharPositionInLine(charPositionInLine)
    }

    /** What is the index of the current character of lookahead? */
    public func getCharIndex() -> Int {
        return _input!.index()
    }

    /** Return the text matched so far for the current token or any
     *  text override.
     */
    public func getText() -> String {
        if _text != nil {
            return _text!
        }
        return getInterpreter().getText(_input!)
    }

    /** Set the complete text of this token; it wipes any previous
     *  changes to the text.
     */
    public func setText(text: String) {
        self._text = text
    }

    /** Override if emitting multiple tokens. */
    public func getToken() -> Token {
        return _token!
    }

    public func setToken(_token: Token) {
        self._token = _token
    }

    public func setType(ttype: Int) {
        _type = ttype
    }

    public func getType() -> Int {
        return _type
    }

    public func setChannel(channel: Int) {
        _channel = channel
    }

    public func getChannel() -> Int {
        return _channel
    }

    public func getModeNames() -> [String]? {
        return nil
    }

    /** Used to print out token names like ID during debugging and
     *  error reporting.  The generated parsers implement a method
     *  that overrides this to point to their String[] tokenNames.
     */
    override
    public func getTokenNames() -> [String?]? {
        return nil
    }

    /** Return a list of all Token objects in input char stream.
     *  Forces load of all tokens. Does not include EOF token.
     */
    public func getAllTokens() throws -> Array<Token> {
        var tokens: Array<Token> = Array<Token>()
        var t: Token = try nextToken()
        while t.getType() != CommonToken.EOF {
            tokens.append(t)
            t = try nextToken()
        }
        return tokens
    }

    public func recover(e: LexerNoViableAltException) throws {
        if try _input!.LA(1) != BufferedTokenStream.EOF {
            // skip a char and try again
            try getInterpreter().consume(_input!)
        }
    }

    public func notifyListeners<T:ATNSimulator>(e: LexerNoViableAltException, recognizer: Recognizer<T>) {

        let text: String = _input!.getText(Interval.of(_tokenStartCharIndex, _input!.index()))
        let msg: String = "token recognition error at: '\(getErrorDisplay(text))'"

        let listener: ANTLRErrorListener = getErrorListenerDispatch()
        listener.syntaxError(recognizer, nil, _tokenStartLine, _tokenStartCharPositionInLine, msg, e)
    }

    public func getErrorDisplay(s: String) -> String {
        let buf: StringBuilder = StringBuilder()
        for c: Character in s.characters {
            buf.append(getErrorDisplay(c))
        }
        return buf.toString()
    }

    public func getErrorDisplay(c: Character) -> String {
        var s: String = String(c)  // String.valueOf(c as Character);
        if c.integerValue == CommonToken.EOF {
            s = "<EOF>"
        }
        switch s {
//			case CommonToken.EOF :
//				s = "<EOF>";
//				break;
        case "\n":
            s = "\\n"
        case "\t":
            s = "\\t"
        case "\r":
            s = "\\r"
        default:
            break
        }
        return s
    }

    public func getCharErrorDisplay(c: Character) -> String {
        let s: String = getErrorDisplay(c)
        return "'\(s)'"
    }

    /** Lexers can normally match any char in it's vocabulary after matching
     *  a token, so do the easy thing and just kill a character and hope
     *  it all works out.  You can instead use the rule invocation stack
     *  to do sophisticated error recovery if you are in a fragment rule.
     */
    //public func recover(re : RecognitionException) {

    public func recover(re: AnyObject) throws {
        //System.out.println("consuming char "+(char)input.LA(1)+" during recovery");
        //re.printStackTrace();
        // TODO: Do we lose character or line position information?
        try _input!.consume()
    }
}
