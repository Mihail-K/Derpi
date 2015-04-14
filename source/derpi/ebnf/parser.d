
module derpi.ebnf.parser;

import derpi.helper;
import derpi.ebnf.lexer;

class DerpiParser
{

	private
	{

		/++
		 + The input queue of tagged tokens.
		 ++/
		Queue!LexerToken input;

		/++
		 + The element the parser is currently at.
		 ++/
		LexerToken current;

		/++
		 + The element last consumed by the parser.
		 ++/
		LexerToken last;

	}

	this(LexerToken[] tokens...)
	{
		input = new Queue!LexerToken(tokens);
	}

	void advance()
	{
		last = current;
		current = input.empty ? null : input.next;
	}

	bool match(string type)
	{
		return current && current.match(type);
	}

	bool accept(string type)
	{
		if(match(type))
		{
			advance;
			return true;
		}

		return false;
	}

	void expect(string type)
	{
		if(!accept(type))
		{
			assert(0, "Expected " ~ type);
		}
	}

	void parse()
	{
		// Advance to initial symbol.
		advance;

		// grammar <name> .
		expect("KeyGrammar");
		if(!accept("GrammarName"))
		{
			expect("ParserRuleName");
		}
		expect("OpTerminate");

		while(true)
		{
			if(match("LexerRuleName"))
			{
				lexerRule;
			}
			else if(match("ParserRuleName"))
			{
				parserRule;
			}
			else
			{
				break;
			}
		}

		expect("EOF");
	}
	
	void lexerRule()
	{
		lexerRuleDeclaration;
		
		expect("OpDefine");

		lexerRuleBody;

		expect("OpTerminate");
	}

	void parserRule()
	{
		parserRuleDeclaration;

		expect("OpDefine");

		parserRuleBody;

		expect("OpTerminate");
	}

	void lexerRuleDeclaration()
	{
		expect("LexerRuleName");

		if(accept("OpMeta"))
		{
			// TODO
			expect("ParserRuleName");
		}
	}

	void parserRuleDeclaration()
	{
		expect("ParserRuleName");

		if(accept("OpMeta"))
		{
			// TODO
			expect("ParserRuleName");
		}
	}

	void lexerRuleBody()
	{
		lexerRuleComma;
	}

	void lexerRuleComma()
	{
		lexerRuleAlter;

		while(accept("OpConcat"))
		{
			lexerRuleAlter;
		}
	}

	void lexerRuleAlter()
	{
		lexerRuleMain;

		while(accept("OpAlter"))
		{
			lexerRuleMain;
		}
	}

	void lexerRuleMain()
	{
		if(accept("OpRepeatOpen"))
		{
			lexerRuleBody;
			expect("OpRepeatClose");
			accept("OpRepeatOnce");
		}
		else if(accept("OpOptionOpen"))
		{
			lexerRuleBody;
			expect("OpOptionClose");
		}
		else if(accept("OpGroupOpen"))
		{
			lexerRuleBody;
			expect("OpGroupClose");
		}
		else if(accept("OpComplement"))
		{
			lexerRuleBody;
		}
		else if(accept("LexerRuleName"))
		{
			// TODO
		}
		else if(accept("Terminal"))
		{
			// TODO
		}
		else if(accept("Pattern"))
		{
			// TODO
		}
		else
		{
			assert(0, "Syntax error.");
		}
	}

	void parserRuleBody()
	{
		parserRuleComma;
	}

	void parserRuleComma()
	{
		parserRuleAlter;

		while(accept("OpConcat"))
		{
			parserRuleAlter;
		}
	}

	void parserRuleAlter()
	{
		parserRuleMain;

		while(accept("OpAlter"))
		{
			parserRuleMain;
		}
	}

	void parserRuleMain()
	{
		if(accept("OpRepeatOpen"))
		{
			parserRuleBody;
			expect("OpRepeatClose");
			accept("OpRepeatOnce");
		}
		else if(accept("OpOptionOpen"))
		{
			parserRuleBody;
			expect("OpOptionClose");
		}
		else if(accept("OpGroupOpen"))
		{
			parserRuleBody;
			expect("OpGroupClose");
		}
		else if(accept("ParserRuleName"))
		{
			// TODO
		}
		else if(accept("LexerRuleName"))
		{
			// TODO
		}
		else if(accept("Terminal"))
		{
			// TODO
		}
		else
		{
			assert(0, "Syntax error : " ~ current.text);
		}
	}

}
