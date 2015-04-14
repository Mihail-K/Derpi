
module derpi.helper;

/++
 + Type alias for parser rules.
 ++/
alias Rule = int;

/++
 + Type alias for terminals and nonterminals.
 ++/
alias Token = int;

/++
 + Type alias for terminals.
 ++/
alias Terminal = int;

/++
 + Type alias for nonterminals.
 ++/
alias NonTerminal = int;

/++
 + Constant start.
 ++/
enum NonTerminal start = 1;

/++
 + Constant epsilon.
 ++/
enum Token epsilon = 0;

/++
 + Constant eof.
 ++/
enum Terminal eof = -1;

/++
 + A simple read-only FIFO data type.
 ++/
class Queue(T)
{

	private
	{

		/++
		 + The elements in the queue.
		 ++/
		T[] elements;

		/++
		 + The current position in the queue.
		 ++/
		size_t position;

	}

	/++
	 + Constructs a new queue with an initial set of elements.
	 ++/
	this(T[] elements...)
	{
		this.elements = elements;
	}

	/++
	 + Tests if the queue is empty.
	 ++/
	@property
	bool empty()
	{
		return position >= elements.length;
	}

	/++
	 + Returns the element at the front of the queue.
	 ++/
	T front()
	{
		if(empty) assert(0, "Empty queue!");
		return elements[position];
	}

	/++
	 + Returns the element at the front of the queue,
	 + and advances position of the queue forward.
	 ++/
	T next()
	{
		T elem = front;
		position++;
		return elem;
	}

}

/++
 + A simple implementation of the LIFO data type.
 ++/
class Stack(T)
{
	import std.array;

	/++
	 + The list of elements on the stack.
	 ++/
	private T[] elements;

	/++
	 + Constructs a new empty stack.
	 ++/
	this()
	{
	}
	
	/++
	 + Constructs a new stack with an initial set of elements.
	 ++/
	this(T[] elements...)
	{
		this.elements = elements;
	}

	/++
	 + Tests if the stack is empty.
	 ++/
	@property
	bool empty()
	{
		return elements.length == 0;
	}

	/++
	 + Returns the top element on the stack.
	 ++/
	T top()
	{
		return elements.back;
	}

	/++
	 + Pops an element off the stack.
	 ++/
	T pop()
	{
		T old = elements.back;
		elements.popBack;
		return old;
	}

	/++
	 + Pushes an element onto the stack.
	 ++/
	void push(T element)
	{
		elements ~= element;
	}

}

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

	/++
	 + Compares two sets for equality.
	 ++/
	override bool opEquals(Object other)
	{
		auto set = cast(OrderedSet!T)other;
		return set ? elements == set.elements : false;
	}

	bool opEquals(T[] other)
	{
		import std.algorithm;

		return elements[].cmp(other) == 0;
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

/++
 + A type representing an unordered set of unique values.
 ++/
class UnorderedSet(T)
{

	private
	{

		T[] elements;

		bool[T] present;

	}

	/++
	 + Constructs a new empty ordered set.
	 ++/
	this()
	{
	}

	/++
	 + Constructs a new ordered set, with the given elements.
	 +
	 + Params:
	 +     values = The initial contents of the set.
	 ++/
	this(T[] values...)
	{
		foreach(value; values)
		{
			if(value !in present)
			{
				elements ~= value;
				present[value] = true;
			}
		}
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
		return elements.length == 0;
	}

	/++
	 + Returns the number of elements in the set.
	 ++/
	@property
	size_t length()
	{
		return elements.length;
	}

	/++
	 + Creates a shallow copy of this set.
	 ++/
	@property
	UnorderedSet!T dup()
	{
		auto set = new UnorderedSet!T;
		set.elements = elements.dup;
		set.present = present.dup;
		return set;
	}

	/++
	 + Returns the element at the front of the set.
	 ++/
	T front()
	{
		return elements[0];
	}

	/++
	 + Returns the element at the back of the set.
	 ++/
	T back()
	{
		return elements[$ - 1];
	}

	/++
	 + Removes all elements from the set.
	 ++/
	void clear()
	{
		elements = [];
		foreach(key; present.keys)
		{
			present.remove(key);
		}
	}

	/++
	 + Produces a array from the elements in the set.
	 ++/
	T[] opIndex()
	{
		return elements[];
	}

	/++
	 + Replaces the values in the set with the supplied operands.
	 +
	 + Params:
	 +     values = The new values for this set.
	 ++/
	void opAssign(T[] values)
	{
		this.clear;
		foreach(value; values)
		{
			if(value !in present)
			{
				elements ~= value;
				present[value] = true;
			}
		}
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
		return value in present;
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
		return value in present;
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
		if(value !in present)
		{
			elements ~= value;
			present[value] = true;
		}

		return value;
	}

	T[] opOpAssign(string op)(T[] values)
	if(op == "~")
	{
		foreach(value; values)
		{
			opOpAssign!"~"(value);
		}

		return values;
	}

	auto opOpAssign(string op)(OrderedSet!T set)
	if(op == "~")
	{
		foreach(value; set.elements)
		{
			opOpAssign!"~"(value);
		}

		return set;
	}

	T opOpAssign(string op)(T value)
	if(op == "-")
	{
		if(value is present)
		{
			elements = elements.remove(value);
			present.remove(value);
		}

		return value;
	}

	T[] opOpAssign(string op)(T[] values)
	if(op == "-")
	{
		foreach(value; values)
		{
			opOpAssign!"-"(value);
		}

		return values;
	}

	auto opOpAssign(string op)(OrderedSet!T set)
	if(op == "-")
	{
		foreach(value; set.elements)
		{
			opOpAssign!"-"(value);
		}

		return set;
	}

	/++
	 + Compares two sets for equality.
	 ++/
	override bool opEquals(Object other)
	{
		auto set = cast(UnorderedSet!T)other;
		return set ? elements == set.elements : false;
	}

	bool opEquals(T[] other)
	{
		return elements == other;
	}

	/++
	 + Returns a string representing the elements in the set.
	 ++/
	override string toString()
	{
		import std.conv : text;
		return elements.text;
	}

}
