// Generated from Hello.g4 by ANTLR 4.5.1
import Antlr4

public class HelloLexer: Lexer {
	internal static var _decisionToDFA: [DFA] = {
          var decisionToDFA = [DFA]()
          for var i: Int = 0; i < HelloLexer._ATN.getNumberOfDecisions(); i++ {
          	    decisionToDFA.append(DFA(HelloLexer._ATN.getDecisionState(i)!, i))
          }
           return decisionToDFA
     }()

	internal let _sharedContextCache:PredictionContextCache = PredictionContextCache()
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
	    var tokenNames = [String?]()

		for  var i : Int = 0; i < _SYMBOLIC_NAMES.count; i++ {
			var name = VOCABULARY.getLiteralName(i)
			if name == nil {
				name = VOCABULARY.getSymbolicName(i)
			}

			if name == nil {
				name = "<INVALID>"
			}
			 tokenNames.append(name)
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
		_interp = LexerATNSimulator(self, HelloLexer._ATN, HelloLexer._decisionToDFA,_sharedContextCache)
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

    public static let _serializedATN: String = Utils.readFile2String("HelloLexerATN.json")
	public static let _ATN: ATN = ATNDeserializer().deserializeFromJson(_serializedATN)

}