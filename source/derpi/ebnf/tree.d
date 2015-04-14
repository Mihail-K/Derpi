
module derpi.ebnf.tree;

import std.string;

abstract class TreeNodeVisitor
{

	Object visit(TerminalNode node)
	{
		return null;
	}

	Object visit(PatternNode node)
	{
		return null;
	}

	Object visit(LexerRuleRefNode node)
	{
		return null;
	}

	Object visit(ParserRuleRefNode node)
	{
		return null;
	}

	Object visit(GroupNode node)
	{
		return null;
	}

	Object visit(OptionNode node)
	{
		return null;
	}

	Object visit(RepeatNode node)
	{
		return null;
	}

	Object visit(ComplementNode node)
	{
		return null;
	}

	Object visit(AlterNode node)
	{
		return null;
	}

	Object visit(ConcatNode node)
	{
		return null;
	}

	Object visit(ParserRuleDeclarationNode node)
	{
		return null;
	}

	Object visit(LexerRuleDeclarationNode node)
	{
		return null;
	}

	Object visit(ParserRuleNode node)
	{
		return null;
	}

	Object visit(LexerRuleNode node)
	{
		return null;
	}

	Object visit(RootNode node)
	{
		return null;
	}

}

mixin template VisitorImpl()
{

	override Object accept(TreeNodeVisitor visitor)
	{
		return visitor.visit(this);
	}

}

abstract class TreeNode
{

	abstract Object accept(TreeNodeVisitor visitor);

	abstract override string toString();

}

class TerminalNode : TreeNode
{

	string value;

	this(string value)
	{
		this.value = value;
	}

	mixin VisitorImpl;

	override string toString()
	{
		return value;
	}

}

class PatternNode : TreeNode
{

	string value;

	this(string value)
	{
		this.value = value;
	}

	mixin VisitorImpl;

	override string toString()
	{
		return value;
	}

}

class LexerRuleRefNode : TreeNode
{

	string name;

	this(string name)
	{
		this.name = name;
	}

	mixin VisitorImpl;

	override string toString()
	{
		return name;
	}

}

class ParserRuleRefNode : TreeNode
{

	string name;

	this(string name)
	{
		this.name = name;
	}

	mixin VisitorImpl;

	override string toString()
	{
		return name;
	}

}

class GroupNode : TreeNode
{

	TreeNode inner;

	this(TreeNode inner)
	{
		this.inner = inner;
	}

	mixin VisitorImpl;

	override string toString()
	{
		return format("( %s )", inner);
	}

}

class OptionNode : TreeNode
{

	TreeNode inner;

	this(TreeNode inner)
	{
		this.inner = inner;
	}

	mixin VisitorImpl;

	override string toString()
	{
		return format("[ %s ]", inner);
	}

}

class RepeatNode : TreeNode
{

	TreeNode inner;
	bool oneOrMore;

	this(TreeNode inner, bool oneOrMore)
	{
		this.inner = inner;
		this.oneOrMore = oneOrMore;
	}

	mixin VisitorImpl;

	override string toString()
	{
		return format("{ %s }", inner) ~ (oneOrMore ? "+" : "");
	}

}

class ComplementNode : TreeNode
{

	TreeNode inner;

	this(TreeNode inner)
	{
		this.inner = inner;
	}

	mixin VisitorImpl;

	override string toString()
	{
		return format("~%s", inner);
	}

}

class AlterNode : TreeNode
{

	TreeNode[] nodes;

	mixin VisitorImpl;

	override string toString()
	{
		return format("%(%s%| | %)", nodes);
	}

}

class ConcatNode : TreeNode
{

	TreeNode[] nodes;

	mixin VisitorImpl;

	override string toString()
	{
		return format("%(%s%| , %)", nodes);
	}

}

class ParserRuleDeclarationNode : TreeNode
{

	string name;
	string meta;

	this(string name)
	{
		this.name = name;
	}

	mixin VisitorImpl;

	override string toString()
	{
		return name;
	}

}

class ParserRuleNode : TreeNode
{

	ParserRuleDeclarationNode declaration;
	TreeNode node;

	this(ParserRuleDeclarationNode declaration)
	{
		this.declaration = declaration;
	}

	mixin VisitorImpl;

	override string toString()
	{
		return format(
			"%s = %s",
			declaration, node
		);
	}

}

class LexerRuleDeclarationNode : TreeNode
{

	string name;
	string meta;

	this(string name)
	{
		this.name = name;
	}

	mixin VisitorImpl;

	override string toString()
	{
		return name;
	}

}

class LexerRuleNode : TreeNode
{

	LexerRuleDeclarationNode declaration;
	TreeNode node;

	this(LexerRuleDeclarationNode declaration)
	{
		this.declaration = declaration;
	}

	mixin VisitorImpl;

	override string toString()
	{
		return format(
			"%s = %s",
			declaration, node
		);
	}

}

class RootNode : TreeNode
{

	string name;
	LexerRuleNode[] lexerRules;
	ParserRuleNode[] parserRules;

	this(string name)
	{
		this.name = name;
	}

	mixin VisitorImpl;
	
	override string toString()
	{
		return format(
			"Grammar %s.\n" ~
			"LexerRules:\n%(%s%|\n%)\n" ~
			"ParserRules:\n%(%s%|\n%)",
			name, lexerRules, parserRules
		);
	}

}
