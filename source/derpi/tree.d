
module derpi.tree;

/++
 + Represents a tree node produced by the parser.
 ++/
abstract class TreeNode
{

	/++
	 + A raw list of this node's children.
	 ++/
	TreeNode[] children;

	abstract void build();

	override string toString()
	{
		import std.algorithm, std.conv : text;
		return "(" ~ children.map!(c => c.toString).joiner(" ").text ~ ")";
	}

}

/++
 + Represents a terminal tree node.
 ++/
class TerminalNode : TreeNode
{

	/++
	 + The value of this terminal node.
	 ++/
	string value;

	this(string value)
	{
		this.value = value;
	}

	override void build()
	{
		// Do nothing.
	}

	override string toString()
	{
		return value;
	}

}
