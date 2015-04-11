
module derpi.parser;

import std.container;

import derpi.table;
import derpi.helper;

/++
 + Represents a token consumed by the parser.
 ++/
class ParserToken
{

	/++
	 + The terminal matched by the token.
	 ++/
	Terminal type;

	/++
	 + The string repsented by the token.
	 ++/
	string text;

	/++
	 + Constructs a new parser token.
	 ++/
	this(Terminal type, string text)
	{
		this.type = type;
		this.text = text;
	}

	/++
	 + Returns a string representation of this token.
	 ++/
	override string toString()
	{
		import std.conv : text;
		return "[" ~ type.text ~ ": " ~ this.text ~ "]";
	}

}

abstract class Parser
{

	protected
	{

		/++
		 + The input queue of parser tokens.
		 ++/
		DList!ParserToken input;

		/++
		 + The next token to consume.
		 ++/
		ParserToken current;

		/++
		 + The last token consumed.
		 ++/
		ParserToken last;

	}

	/++
	 + Constructs a new parser from a list of tokens.
	 ++/
	this(ParserToken[] tokens)
	{
		input = DList!ParserToken(tokens);

		// Advance to initial token.
		advance;
	}

	/++
	 + Consumes a token from the input queue, advancing the parser.
	 ++/
	void advance()
	{
		if(!input.empty)
		{
			last = current;
			current = input.front;
			input.removeFront;
		}
		else
		{
			last = current;
			current = null;
		}
	}

	/++
	 + Tries to match the current token.
	 ++/
	bool match(Terminal t)
	{
		return current && current.type == t;
	}

	/++
	 + Tries to match the current token, advancing on success.
	 ++/
	bool accept(Terminal t)
	{
		if(match(t))
		{
			advance;
			return true;
		}

		return false;
	}

	/++
	 + Tries to match the current token, throwing an error on failure.
	 ++/
	void expect(Terminal t)
	{
		if(!accept(t))
		{
			assert(0);
		}
	}

}

/+
 + Grammar 4:
 +
 + E → E + E
 +   | E - E
 +   | P
 +
 + P → 1
 +   | 2
 +
 +/
unittest
{
	/++
	 + Define grammar tokens.
	 ++/
	enum : Token
	{

		// Terminals

		Two = -5,
		One = -4,
		Minus = -3,
		Plus = -2,

		// Non Terminals

		E = 1,
		P = 2,
		F = 3,
		G = 4

	}

	/++
	 + CTFE helper function.
	 ++/
	string createParser()
	{
		import derpi.builder;
		auto builder = new GrammarBuilder;

		builder
			// Terminals
			.addTerminal("One", One)
			.addTerminal("Two", Two)
			.addTerminal("Plus", Plus)
			.addTerminal("Minus", Minus)

			// Nonterminals
			.addNonTerminal("E", E)
			.addNonTerminal("P", P)

			// Productions
			.addRule(E, [E, Plus, E])
			.addRule(E, [E, Minus, E])
			.addRule(E, [P])
			.addRule(P, [One])
			.addRule(P, [Two]);

		return builder.build;
	}

	// Include the parser.
	mixin(createParser);

	// Create and initialize the parser.
	// - Input : 1 + 2 - 1 <EOF>
	auto parser = new SomeParser([
		new ParserToken(One, "1"),
		new ParserToken(Plus, "+"),
		new ParserToken(Two, "2"),
		new ParserToken(Minus, "-"),
		new ParserToken(One, "1"),
		new ParserToken(eof, "$")
	]);

	try
	{
		// Parse input!
		parser.E;
	}
	catch(Throwable t)
	{
		// Parsing failed.
		assert(0, t.toString);
	}

}
