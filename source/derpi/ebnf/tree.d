
module derpi.ebnf.tree;

import std.string;

interface TreeNodeVisitor
{

	void visit(TerminalNode node);

	void visit(PatternNode node);

	void visit(LexerRuleRefNode node);

	void visit(ParserRuleRefNode node);

	void visit(GroupNode node);

	void visit(OptionNode node);

	void visit(RepeatNode node);

	void visit(ComplementNode node);

	void visit(AlterNode node);

	void visit(ConcatNode node);

	void visit(ParserRuleDeclarationNode node);

	void visit(LexerRuleDeclarationNode node);

	void visit(ParserRuleNode node);

	void visit(LexerRuleNode node);

	void visit(RootNode node);

}

mixin template VisitorImpl()
{

	override void accept(TreeNodeVisitor visitor)
	{
		return visitor.visit(this);
	}

}

abstract class TreeNode
{

	abstract void accept(TreeNodeVisitor visitor);

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
