
module derpi.ebnf.parser;

import derpi.helper;
import derpi.ebnf.lexer;
import derpi.ebnf.tree;

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

	RootNode parse()
	{
		RootNode node;

		// Advance to initial symbol.
		advance;

		// grammar <name> .
		expect("KeyGrammar");
		if(!accept("GrammarName") &&
				!accept("LexerRuleName") &&
				!accept("ParserRuleName"))
		{
			assert(0, "Missing grammar name.");
		}
		else
		{
			node = new RootNode(last.text);
		}
		expect("OpTerminate");

		while(true)
		{
			if(match("LexerRuleName"))
			{
				node.lexerRules ~= lexerRule;
			}
			else if(match("ParserRuleName"))
			{
				node.parserRules ~= parserRule;
			}
			else
			{
				break;
			}
		}

		expect("EOF");
		return node;
	}
	
	LexerRuleNode lexerRule()
	{
		auto decl = lexerRuleDeclaration;
		expect("OpDefine");

		auto node = new LexerRuleNode(decl);

		node.node = lexerRuleBody;
		expect("OpTerminate");

		return node;
	}

	ParserRuleNode parserRule()
	{
		auto decl = parserRuleDeclaration;
		expect("OpDefine");

		auto node = new ParserRuleNode(decl);

		node.node = parserRuleBody;
		expect("OpTerminate");

		return node;
	}

	LexerRuleDeclarationNode lexerRuleDeclaration()
	{
		expect("LexerRuleName");
		auto node = new LexerRuleDeclarationNode(last.text);

		if(accept("OpMeta"))
		{
			// TODO
			expect("ParserRuleName");
			node.meta = last.text;
		}

		return node;
	}

	ParserRuleDeclarationNode parserRuleDeclaration()
	{
		expect("ParserRuleName");
		auto node = new ParserRuleDeclarationNode(last.text);

		if(accept("OpMeta"))
		{
			// TODO
			expect("ParserRuleName");
			node.meta = last.text;
		}

		return node;
	}

	TreeNode lexerRuleBody()
	{
		return lexerRuleComma;
	}

	ConcatNode lexerRuleComma()
	{
		auto node = new ConcatNode;
		node.nodes ~= lexerRuleAlter;

		while(accept("OpConcat"))
		{
			node.nodes ~= lexerRuleAlter;
		}

		return node;
	}

	AlterNode lexerRuleAlter()
	{
		auto node = new AlterNode;
		node.nodes ~= lexerRuleMain;

		while(accept("OpAlter"))
		{
			node.nodes ~= lexerRuleMain;
		}

		return node;
	}

	TreeNode lexerRuleMain()
	{
		if(accept("OpRepeatOpen"))
		{
			auto inner = lexerRuleBody;
			expect("OpRepeatClose");
			bool once = accept("OpRepeatOnce");

			return new RepeatNode(inner, once);
		}
		else if(accept("OpOptionOpen"))
		{
			auto inner = lexerRuleBody;
			expect("OpOptionClose");

			return new OptionNode(inner);
		}
		else if(accept("OpGroupOpen"))
		{
			auto inner = lexerRuleBody;
			expect("OpGroupClose");

			return new GroupNode(inner);
		}
		else if(accept("OpComplement"))
		{
			auto inner = lexerRuleBody;
			return new ComplementNode(inner);
		}
		else if(accept("LexerRuleName"))
		{
			return new LexerRuleRefNode(last.text);
		}
		else if(accept("Terminal"))
		{
			return new TerminalNode(last.text);
		}
		else if(accept("Pattern"))
		{
			return new PatternNode(last.text);
		}
		else
		{
			assert(0, "Syntax error.");
		}
	}

	TreeNode parserRuleBody()
	{
		return parserRuleComma;
	}

	ConcatNode parserRuleComma()
	{
		auto node = new ConcatNode;
		node.nodes ~= parserRuleAlter;

		while(accept("OpConcat"))
		{
			node.nodes ~= parserRuleAlter;
		}

		return node;
	}

	AlterNode parserRuleAlter()
	{
		auto node = new AlterNode;
		node.nodes ~= parserRuleMain;

		while(accept("OpAlter"))
		{
			node.nodes ~= parserRuleMain;
		}
		
		return node;
	}

	TreeNode parserRuleMain()
	{
		if(accept("OpRepeatOpen"))
		{
			auto inner = parserRuleBody;
			expect("OpRepeatClose");
			bool once = accept("OpRepeatOnce");

			return new RepeatNode(inner, once);
		}
		else if(accept("OpOptionOpen"))
		{
			auto inner = parserRuleBody;
			expect("OpOptionClose");

			return new OptionNode(inner);
		}
		else if(accept("OpGroupOpen"))
		{
			auto inner = parserRuleBody;
			expect("OpGroupClose");

			return new GroupNode(inner);
		}
		else if(accept("ParserRuleName"))
		{
			return new ParserRuleRefNode(last.text);
		}
		else if(accept("LexerRuleName"))
		{
			return new LexerRuleRefNode(last.text);
		}
		else if(accept("Terminal"))
		{
			return new TerminalNode(last.text);
		}
		else
		{
			assert(0, "Syntax error : " ~ current.text);
		}
	}

}
