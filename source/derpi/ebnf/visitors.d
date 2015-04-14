
module derpi.ebnf.visitors;

import std.algorithm;

import derpi.pattern;
import derpi.ebnf.tree;

class LexerNodeVisitor : TreeNodeVisitor
{

	Pattern[string] patterns;

	Pattern visit(TerminalNode node)
	{
		return new Primitive(node.value);
	}

	Pattern visit(PatternNode node)
	{
		 // TODO : Parse pattern.
		return null;
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
