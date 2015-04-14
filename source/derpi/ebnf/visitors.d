
module derpi.ebnf.visitors;

import std.algorithm;
import std.string;

import derpi.pattern;
import derpi.ebnf.lexer;
import derpi.ebnf.tree;

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

	Pattern[string] patterns;

	Pattern visit(TerminalNode node)
	{
		return new Primitive(node.value);
	}

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
					string min = element[0 .. dash - 1];
					string max = element[dash + 1 .. $];
					patterns ~= new Bracket(
						min.unescape, max.unescape
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
			return patterns[node.declaration.name] = pattern;
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
