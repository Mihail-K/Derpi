
module derpi.ebnf.visitors;

import std.algorithm;
import std.string;

import derpi.helper;
import derpi.pattern;
import derpi.ebnf.lexer;
import derpi.ebnf.tree;

/++
 + Returns an unescaped character from an escape sequence.
 ++/
char unescape(string input)
{
	switch(input)
	{
		case "\\0":  return '\0';
		case "\\\\": return '\\';
		case "\\b":  return '\b';
		case "\\f":  return '\f';
		case "\\n":  return '\n';
		case "\\r":  return '\r';
		case "\\t":  return '\t';
		case "\\'":  return '\'';
		case "\\\"": return '"';
		case "\\/":  return '/';
		case "\\-":  return '-';
		default:     return input[0];
	}
}

class LexerNodeVisitor : TreeNodeVisitor
{

	/++
	 + A serial id of the next terminal.
	 ++/
	Terminal nextTerminal = -2;

	/++
	 + The table of patterns.
	 ++/
	Pattern[string] patterns;

	/++
	 + A table of terminals, indexed by rule names.
	 ++/
	Terminal[string] ruleTable;

	/++
	 + A table of terminals, indexed by patterns.
	 ++/
	Terminal[string] patternTable;

	/++
	 + Creates a Primitive pattern from a Terminal.
	 ++/
	Pattern visit(TerminalNode node)
	{
		// String enclosing quotes.
		string text = node.value[1 .. $ - 1];
		return new Primitive(text);
	}

	/++
	 + Creates a pattern from a pattern rule.
	 ++/
	Pattern visit(PatternNode node)
	{
		Pattern[] patterns;

		// Strip enclosing slashes.
		string input = node.value[1 .. $ - 1];

		while(input.length > 0)
		{
			string element = LexerRules._PatternElement.match(input);
			if(element is null) assert(0, "Malformed pattern.");
			input = input[element.length .. $];

			if(element == "\\-")
			{
				// Add the escaped dash.
				patterns ~= new Primitive("-");
			}
			else
			{
				// Check if we're defining a range.
				int dash = element.countUntil('-');

				// Check if we're at an escaped dash.
				if(dash > 0 && element.startsWith("\\-"))
				{
					dash++;
				}

				if(dash != -1)
				{
					// Create a bracket.
					string min = element[0 .. dash];
					string max = element[dash + 1 .. $];
					patterns ~= new Bracket(
						min.unescape,
						max.unescape
					);
				}
				else
				{
					patterns ~= new Primitive(
						[element.unescape]
					);
				}
			}
		}

		return new Selection(patterns);
	}

	Pattern visit(LexerRuleRefNode node)
	{
		// TODO : Reference rule.
		return null;
	}

	/++
	 + Parser rules references don't appear in lexer rules.
	 ++/
	Pattern visit(ParserRuleRefNode node)
	{
		// Do nothing.
		return null;
	}

	Pattern visit(GroupNode node)
	{
		return cast(Pattern)node.inner.accept(this);
	}

	Pattern visit(OptionNode node)
	{
		return new Optional(
			cast(Pattern)node.inner.accept(this)
		);
	}

	Pattern visit(RepeatNode node)
	{
		if(node.oneOrMore)
		{
			return new Repetition(
				cast(Pattern)node.inner.accept(this)
			);
		}
		else
		{
			return new Optional(
				new Repetition(
					cast(Pattern)node.inner.accept(this)
				)
			);
		}
	}

	Pattern visit(ComplementNode node)
	{
		return new Complement(
			cast(Pattern)node.inner.accept(this)
		);
	}

	Pattern visit(AlterNode node)
	{
		Pattern[] patterns;

		foreach(child; node.nodes)
		{
			patterns ~= cast(Pattern)child.accept(this);
		}

		if(patterns.length > 1)
		{
			return new Selection(patterns);
		}
		else
		{
			return patterns[0];
		}
	}

	Pattern visit(ConcatNode node)
	{
		Pattern[] patterns;

		foreach(child; node.nodes)
		{
			patterns ~= cast(Pattern)child.accept(this);
		}

		if(patterns.length > 1)
		{
			return new Sequence(patterns);
		}
		else
		{
			return patterns[0];
		}
	}

	Pattern visit(ParserRuleDeclarationNode node)
	{
		// Do nothing.
		return null;
	}

	Pattern visit(LexerRuleDeclarationNode node)
	{
		// Do nothing.
		return null;
	}

	Pattern visit(ParserRuleNode node)
	{
		// Do nothing.
		return null;
	}

	Pattern visit(LexerRuleNode node)
	{
		auto pattern = cast(Pattern)node.node.accept(this);

		// Check if the pattern can match ε.
		if(pattern.isNullable)
		{
			assert(0, "Pattern can match an empty string.");
		}

		// Check if an equivalent pattern exists.
		if(patterns.values.countUntil(pattern) == -1)
		{
			// Check if this is a primitive.
			if(cast(Primitive)pattern)
			{
				patternTable[pattern.toString] = nextTerminal;
			}

			// Register the new terminal rule and pattern.
			ruleTable[node.declaration.name] = nextTerminal--;
			patterns[node.declaration.name] = pattern;
			return pattern;
		}
		else
		{
			assert(0, "Duplicate lexer rule.");
		}
	}

	Pattern visit(RootNode node)
	{
		// Visit lexer rules.
		foreach(rule; node.lexerRules)
		{
			rule.accept(this);
		}

		return null;
	}

}

class Ruleset
{

	Token[][] rules;

	this()
	{
	}

	this(Token rule)
	{
		rules = [[rule]];
	}

	this(Token[][] rules)
	{
		this.rules = rules;
	}

	void opOpAssign(string op)(Ruleset other)
	if(op == "+")
	{
		foreach(a; other.rules)
		{
			rules ~= a;
		}
	}

	void opOpAssign(string op)(Ruleset other)
	if(op == "~")
	{
		int[][] temp;

		foreach(a; rules)
		{
			foreach(b; other.rules)
			{
				temp ~= a ~ b;
			}
		}

		rules = temp;
	}

}

class ParserNodeVisitor : TreeNodeVisitor
{

	/++
	 + A table of terminals, indexed by names.
	 ++/
	Terminal[string] terminals;

	/++
	 + A table of terminals, indexed by patterns.
	 ++/
	Terminal[string] patternTable;

	/++ 
	 + A table of nonterminals, indexed by names.
	 ++/
	NonTerminal[string] nonterminals;

	Ruleset visit(TerminalNode node)
	{
		// Strip enclosing quotes.
		string text = node.value[1 .. $];

		// Check that the pattern exists.
		auto value = node.value in patternTable;

		if(value !is null)
		{
			return new Ruleset(*value);
		}
		else
		{
			assert(0, "Undefined terminal " ~ node.value);
		}
	}

	Ruleset visit(PatternNode node)
	{
		// Do nothing.
		return null;
	}

	Ruleset visit(LexerRuleRefNode node)
	{
		// Check that the lexer rule exists.
		auto value = node.name in terminals;

		if(value !is null)
		{
			return new Ruleset(*value);
		}
		else
		{
			assert(0, "Undefined rule " ~ node.name);
		}
	}

	Ruleset visit(ParserRuleRefNode node)
	{
		// Check that the lexer rule exists.
		auto value = node.name in nonterminals;

		if(value !is null)
		{
			return new Ruleset(*value);
		}
		else
		{
			assert(0, "Undefined rule " ~ node.name);
		}
	}

	Ruleset visit(GroupNode node)
	{
		// TODO : Create new rule.
		return null;
	}

	Ruleset visit(OptionNode node)
	{
		// Create an alternative, empty rule.
		Ruleset ruleset = cast(Ruleset)node.accept(this);
		ruleset.rules ~= [];
		return ruleset;
	}

	Ruleset visit(RepeatNode node)
	{
		// TODO : Create new rule.
		return null;
	}

	Ruleset visit(ComplementNode node)
	{
		// Do nothing.
		return null;
	}

	Ruleset visit(AlterNode node)
	{
		Ruleset ruleset = new Ruleset;

		foreach(child; node.nodes)
		{
			ruleset += cast(Ruleset)child.accept(this);
		}

		return ruleset;
	}

	Ruleset visit(ConcatNode node)
	{
		Ruleset ruleset = new Ruleset;

		foreach(child; node.nodes)
		{
			ruleset ~= cast(Ruleset)child.accept(this);
		}

		return ruleset;
	}

	Ruleset visit(ParserRuleDeclarationNode node)
	{
		// Do nothing.
		return null;
	}

	Ruleset visit(LexerRuleDeclarationNode node)
	{
		// Do nothing.
		return null;
	}

	Ruleset visit(ParserRuleNode node)
	{
		// TODO
		node.node.accept(this);
		return null;
	}

	Ruleset visit(LexerRuleNode node)
	{
		// Do nothing.
		return null;
	}

	Ruleset visit(RootNode node)
	{
		foreach(rule; node.parserRules)
		{
			rule.accept(this);
		}
		
		return null;
	}

}
