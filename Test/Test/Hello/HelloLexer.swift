// Generated from Hello.g4 by ANTLR 4.5.1
import Antlr4

public class HelloLexer: Lexer {
	internal static var _decisionToDFA: [DFA] = {
          var decisionToDFA = [DFA]()
          let length = HelloLexer._ATN.getNumberOfDecisions()
          for i in 0..<length {
          	    decisionToDFA.append(DFA(HelloLexer._ATN.getDecisionState(i)!, i))
          }
           return decisionToDFA
     }()

	internal static let _sharedContextCache:PredictionContextCache = PredictionContextCache()
	public static let T__0=1, ID=2, WS=3
	public static let modeNames: [String] = [
		"DEFAULT_MODE"
	]

	public static let ruleNames: [String] = [
		"T__0", "ID", "WS"
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

    public override func getVocabulary() -> Vocabulary {
        return HelloLexer.VOCABULARY
    }

	public override init(_ input: CharStream) {
	    RuntimeMetaData.checkVersion("4.5.1", RuntimeMetaData.VERSION)
		super.init(input)
		_interp = LexerATNSimulator(self, HelloLexer._ATN, HelloLexer._decisionToDFA, HelloLexer._sharedContextCache)
	}

	override
	public func getGrammarFileName() -> String { return "Hello.g4" }

    override
	public func getRuleNames() -> [String] { return HelloLexer.ruleNames }

	override
	public func getSerializedATN() -> String { return HelloLexer._serializedATN }

	override
	public func getModeNames() -> [String] { return HelloLexer.modeNames }

	override
	public func getATN() -> ATN { return HelloLexer._ATN }

    public static let _serializedATN: String = HelloLexerATN().jsonString
	public static let _ATN: ATN = ATNDeserializer().deserializeFromJson(_serializedATN)

}