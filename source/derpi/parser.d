
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

		last = current;
		current = null;
	}

	/++
	 + Tries to match the current token, advancing on success.
	 ++/
	bool accept(Terminal t)
	{
		if(current && current.type == t)
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
