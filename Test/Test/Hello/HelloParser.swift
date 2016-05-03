// Generated from Hello.g4 by ANTLR 4.5.1
import Antlr4

public class HelloParser: Parser {

	internal static var _decisionToDFA: [DFA] = {
          var decisionToDFA = [DFA]()
          let length = HelloParser._ATN.getNumberOfDecisions()
          for i in 0..<length {
            decisionToDFA.append(DFA(HelloParser._ATN.getDecisionState(i)!, i))
           }
           return decisionToDFA
     }()
	internal static let _sharedContextCache: PredictionContextCache = PredictionContextCache()
	public static let T__0=1, ID=2, WS=3
	public static let RULE_r = 0
	public static let ruleNames: [String] = [
		"r"
	]

	private static let _LITERAL_NAMES: [String?] = [
		nil, "'hello'"
	]
	private static let _SYMBOLIC_NAMES: [String?] = [
		nil, nil, "ID", "WS"
	]
	public static let VOCABULARY: Vocabulary = Vocabulary(_LITERAL_NAMES, _SYMBOLIC_NAMES)

	/**
	 * @deprecated Use {@link #VOCABULARY} instead.
	 */
	//@Deprecated
	public let tokenNames: [String?]? = {
	    let length = _SYMBOLIC_NAMES.count
	    var tokenNames = [String?](count: length, repeatedValue: nil)
		for i in 0..<length {
			var name = VOCABULARY.getLiteralName(i)
			if name == nil {
				name = VOCABULARY.getSymbolicName(i)
			}
			if name == nil {
				name = "<INVALID>"
			}
			tokenNames[i] = name
		}
		return tokenNames
	}()

	override
	public func getTokenNames() -> [String?]? {
		return tokenNames
	}

	override
	public func getGrammarFileName() -> String { return "Hello.g4" }

	override
	public func getRuleNames() -> [String] { return HelloParser.ruleNames }

	override
	public func getSerializedATN() -> String { return HelloParser._serializedATN }

	override
	public func getATN() -> ATN { return HelloParser._ATN }

	public override func getVocabulary() -> Vocabulary {
	    return HelloParser.VOCABULARY
	}

	public override  init(_ input:TokenStream)throws {
	    RuntimeMetaData.checkVersion("4.5.1", RuntimeMetaData.VERSION)
		try super.init(input)
		_interp = ParserATNSimulator(self,HelloParser._ATN,HelloParser._decisionToDFA, HelloParser._sharedContextCache)
	}
	public  class RContext: ParserRuleContext {
		public func ID() -> TerminalNode? { return getToken(HelloParser.ID, 0) }
		public override func getRuleIndex() -> Int { return HelloParser.RULE_r }
		override
		public func enterRule(listener: ParseTreeListener) {
			if listener is HelloListener {
			 	(listener as! HelloListener).enterR(self)
			}
		}
		override
		public func exitRule(listener: ParseTreeListener) {
			if listener is HelloListener {
			 	(listener as! HelloListener).exitR(self)
			}
		}
		override
		public func accept<T>(visitor: ParseTreeVisitor<T>) -> T? {
			if visitor is HelloVisitor {
			     return (visitor as! HelloVisitor<T>).visitR(self)
			}else if visitor is HelloBaseVisitor {
		    	 return (visitor as! HelloBaseVisitor<T>).visitR(self)
		    }
			else {
			     return visitor.visitChildren(self)
			}
		}
	}
	public func r() throws -> RContext {
		var _localctx: RContext = RContext(_ctx, getState())
		try enterRule(_localctx, 0, HelloParser.RULE_r)
		do {
		 	try enterOuterAlt(_localctx, 1)
		 	setState(2)
		 	try match(HelloParser.T__0)
		 	setState(3)
		 	try match(HelloParser.ID)

		}
		catch ANTLRException.Recognition(let re) {
			_localctx.exception = re
			_errHandler.reportError(self, re)
			try _errHandler.recover(self, re)
		}
		defer {
			try! exitRule()
		 }
		return _localctx
	}

   public static let _serializedATN : String = HelloParserATN().jsonString
   public static let _ATN: ATN = ATNDeserializer().deserializeFromJson(_serializedATN)
}