
module derpi.helper;

alias Rule = int;

alias Terminal = int;

alias NonTerminal = int;

/++
 + Constant epsilon.
 ++/
enum int epsilon = 0;

/++
 + A type representing an ordered set of unique values.
 ++/
class OrderedSet(T)
{

	import std.array;
	import std.container;

	/++
	 + The list of elements that make up this set.
	 ++/
	private RedBlackTree!T elements;

	/++
	 + Constructs a new empty ordered set.
	 ++/
	this()
	{
		elements = new RedBlackTree!T;
	}

	/++
	 + Constructs a new ordered set, with the given elements.
	 +
	 + Params:
	 +     values = The initial contents of the set.
	 ++/
	this(T[] values...)
	{
		elements = new RedBlackTree!T(values);
	}

	/++
	 + Checks if there are any elements in the set.
	 +
	 + See_Also:
	 +     length
	 ++/
	@property
	bool empty()
	{
		return elements.empty;
	}

	/++
	 + Returns the number of elements in the set.
	 +
	 + Complexity:
	 +     O(1)
	 ++/
	@property
	size_t length()
	{
		return elements.length;
	}

	/++
	 + Creates a shallow copy of this set.
	 +
	 + Complexity:
	 +     O(n)
	 ++/
	@property
	OrderedSet!T dup()
	{
		auto set = new OrderedSet!T;
		set.elements = elements.dup;
		return set;
	}

	/++
	 + Returns the element at the front of the set.
	 +
	 + Complexity:
	 +     O(1)
	 ++/
	T front()
	{
		return elements.front;
	}

	/++
	 + Returns the element at the back of the set.
	 +
	 + Complexity:
	 +     O(log(n))
	 ++/
	T back()
	{
		return elements.back;
	}

	/++
	 + Removes all elements from the set.
	 +
	 + Complexity:
	 +     O(1)
	 ++/
	void clear()
	{
		elements.clear;
	}

	/++
	 + Produces a array from the elements in the set.
	 +
	 + Complexity:
	 +     O(n)
	 ++/
	T[] opIndex()
	{
		return elements[].array;
	}

	/++
	 + Replaces the values in the set with the supplied operands.
	 +
	 + Params:
	 +     values = The new values for this set.
	 +
	 + Complexity:
	 +     O(m * log(n))
	 ++/
	void opAssign(T[] values)
	{
		elements.clear;
		elements.insert(values);
	}

	/++
	 + Checks for the presence of an element in the set.
	 +
	 + Params:
	 +     value = The element to look for.
	 ++/
	bool opBinary(string op)(T value)
	if(op == "in")
	{
		return value in elements;
	}
	
	/++
	 + Checks for the presence of an element in the set.
	 +
	 + Params:
	 +     value = The element to look for.
	 ++/
	bool opBinaryRight(string op)(T value)
	if(op == "in")
	{
		return value in elements;
	}

	OrderedSet!T opBinary(string op)(T value)
	if(op == "~")
	{
		OrderedSet!T set = dup;
		set ~= value;
		return set;
	}

	OrderedSet!T opBinary(string op)(T value)
	if(op == "-")
	{
		OrderedSet!T set = dup;
		set -= value;
		return set;
	}

	T opOpAssign(string op)(T value)
	if(op == "~")
	{
		elements.insert(value);
		return value;
	}

	T[] opOpAssign(string op)(T[] values)
	if(op == "~")
	{
		elements.insert(values);
		return values;
	}

	auto opOpAssign(string op)(OrderedSet!T set)
	if(op == "~")
	{
		elements.insert(set.elements[]);
		return set;
	}

	T opOpAssign(string op)(T value)
	if(op == "-")
	{
		elements.remove(elements.equalRange(value));
		return value;
	}

	T[] opOpAssign(string op)(T[] values)
	if(op == "-")
	{
		elements.remove(elements.equalRange(value));
		return values;
	}

	auto opOpAssign(string op)(OrderedSet!T set)
	if(op == "-")
	{
		elements.remove(set.elements[]);
		return set;
	}

	int opApply(int delegate(ref T) func)
	{
		int result = 0;

		foreach(element; elements[])
		{
			result = func(element);
			if(result) break;
		}

		return result;
	}

	/++
	 + Compares two sets for equality.
	 ++/
	override bool opEquals(Object other)
	{
		auto set = cast(OrderedSet!T)other;
		return set ? elements == set.elements : false;
	}

	/++
	 + Returns a string representing the elements in the set.
	 ++/
	override string toString()
	{
		import std.conv : text;
		return elements[].text;
	}

}
