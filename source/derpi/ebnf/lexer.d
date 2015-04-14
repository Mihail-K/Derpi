
module derpi.ebnf.lexer;

import derpi.pattern;

private struct LexerRule
{

	string name;

	Pattern pattern;

	bool discard;

	string match(string input)
	{
		return pattern.match(input);
	}

}

private enum LexerRules : LexerRule
{

	/+ - Internal Rules - +/

	Error = LexerRule("Error"),

	EOF = LexerRule("EOF"),

	/+ - Fragment Rules - +/

	_EOL = LexerRule("_EOL",
		new Selection(
			new Primitive("\r\n"),
			new Primitive("\n\r"),
			new Primitive("\n"),
			new Primitive("\r")
		)
	),

	_IdentTail = LexerRule("_IdentTail",
		new Optional(
			new Repetition(
				new Selection(
					new Primitive("_"),
					new Bracket('a', 'z'),
					new Bracket('A', 'Z'),
					new Bracket('0', '9')
				)
			)
		)
	),

	_EscapeCharacter = LexerRule("_EscapeCharacter",
		new Sequence(
			new Primitive("\\"),
			new Selection(
				new Primitive("\\"),
				new Primitive("0"),
				new Primitive("b"),
				new Primitive("f"),
				new Primitive("n"),
				new Primitive("r"),
				new Primitive("t"),
				new Primitive("'"),
				new Primitive(`"`)
			)
		)
	),

	_PatternSegment = LexerRule("_PatternSegment",
		new Selection(
			_EscapeCharacter.pattern,
			new Primitive("\\-"),
			new Primitive("\\/"),
			new Complement(
				new Primitive("/")
			)
		)
	),

	_PatternElement = LexerRule("_PatternElement",
		new Sequence(
			_PatternSegment.pattern,
			new Optional(
				new Sequence(
					new Primitive("-"),
					_PatternSegment.pattern
				)
			)
		)
	),

	/+ - Discarded Rules - +/

	WhiteSpace = LexerRule("WhiteSpace",
		new Repetition(
			new Selection(
				new Primitive(" "),
				new Primitive("\b"),
				new Primitive("\f"),
				new Primitive("\n"),
				new Primitive("\r"),
				new Primitive("\t")
			)
		),
		true
	),

	LineComment = LexerRule("LineComment",
		new Sequence(
			new Primitive("//"),
			new Optional(
				new Repetition(
					new Selection(
						new Sequence(
							new Primitive("\\"),
							_EOL.pattern
						),
						new Complement(
							_EOL.pattern
						)
					)
				)
			)
		),
		true
	),

	BlockComment = LexerRule("BlockComment",
		new Sequence(
			new Primitive("/*"),
			new Optional(
				new Repetition(
					new Complement(
						new Primitive("*/")
					)
				)
			),
			new Primitive("*/")
		),
		true
	),

	/+ - Keyword Rules - +/

	KeyGrammar = LexerRule("KeyGrammar",
		new Primitive("grammar")
	),

	/+ - Syntax Rules - +/

	OpAlter = LexerRule("OpAlter",
		new Primitive("|")
	),

	OpConcat = LexerRule("OpConcat",
		new Primitive(",")
	),

	OpComplement = LexerRule("OpComplement",
		new Primitive("~")
	),

	OpDefine = LexerRule("OpDefine",
		new Primitive("=")
	),

	OpGroupOpen = LexerRule("OpGroupOpen",
		new Primitive("(")
	),

	OpGroupClose = LexerRule("OpGroupClose",
		new Primitive(")")
	),

	OpMeta = LexerRule("OpMeta",
		new Primitive("::")
	),

	OpOptionOpen = LexerRule("OpOptionOpen",
		new Primitive("[")
	),

	OpOptionClose = LexerRule("OpOptionClose",
		new Primitive("]")
	),

	OpRepeatOpen = LexerRule("OpRepeatOpen",
		new Primitive("{")
	),

	OpRepeatClose = LexerRule("OpRepeatClose",
		new Primitive("}")
	),

	OpRepeatOnce = LexerRule("OpRepeatOnce",
		new Primitive("+")
	),

	OpTerminate = LexerRule("OpTerminate",
		new Primitive(".")
	),

	/+ - Terminal Rules - +/

	Terminal = LexerRule("Terminal",
		new Selection(
			new Sequence(
				new Primitive("'"),
				new Repetition(
					new Selection(
						_EscapeCharacter.pattern,
						new Complement(
							new Primitive("'")
						)
					)
				),
				new Primitive("'")
			),
			new Sequence(
				new Primitive(`"`),
				new Repetition(
					new Selection(
						_EscapeCharacter.pattern,
						new Complement(
							new Primitive(`"`)
						)
					)
				),
				new Primitive(`"`)
			)
		)
	),

	Pattern = LexerRule("Pattern",
		new Sequence(
			new Primitive("/"),
			new Repetition(
				_PatternElement.pattern
			),
			new Primitive("/")
		)
	),

	/+ - Naming Rules - +/

	LexerRuleName = LexerRule("LexerRuleName",
		new Sequence(
			new Optional(
				new Primitive("_")
			),
			new Bracket('A', 'Z'),
			_IdentTail.pattern
		)
	),

	ParserRuleName = LexerRule("ParserRuleName",
		new Sequence(
			new Optional(
				new Primitive("_")
			),
			new Bracket('a', 'z'),
			_IdentTail.pattern
		)
	),

	GrammarName = LexerRule("GrammarName",
		new Sequence(
			new Selection(
				new Primitive("_"),
				new Bracket('a', 'z'),
				new Bracket('A', 'Z')
			),
			_IdentTail.pattern
		)
	),

}

class LexerToken
{

	string text;
	string type;

	this(string text, string type)
	{
		this.text = text;
		this.type = type;
	}

	bool match(string type)
	{
		return this.type == type;
	}

	override string toString()
	{
		import std.string : format;
		return format("[%s : %s]", type, text);
	}

}

alias Alias(alias A) = A;

LexerToken[] tokenize(string input)
{
	LexerRule rule;
	string result, token;
	LexerToken[] output;

	while(input.length > 0)
	{
		foreach(name; __traits(allMembers, LexerRules))
		{
			// Skip fragment rules.
			static if(name[0] != '_')
			{
				alias member = Alias!(__traits(getMember, LexerRules, name));

				// Skip internal and fragment rules.
				static if(member.pattern !is null && member.name[0] != '_')
				{
					// Check for a match against the rule.
					if((result = member.match(input)) !is null)
					{
						// Check if we've found a better match.
						if(token is null || result.length > token.length)
						{
							token = result;
							rule = member;
						}
					}
				}
			}
		}

		if(token !is null)
		{
			// Discard token as necessary.
			if(!rule.discard)
			{
				output ~= new LexerToken(token, rule.name);
			}

			// Advance the input buffer.
			input = input[token.length .. $];
			token = null;
		}
		else
		{
			// Append error token.
			output ~= new LexerToken(input, "Error");
			return output;
		}
	}

	// Append EOF token.
	output ~= new LexerToken("$", "EOF");
	return output;
}
