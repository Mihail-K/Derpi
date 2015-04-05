
module derpi.parser;

import derpi.table;
import derpi.helper;

class Parser
{

	import std.container;

	private
	{

		/++
		 + The computed LL parse table.
		 ++/
		ParseTable table;

		/++
		 + The parser state stack.
		 ++/
		Stack!Token stack;

		/++
		 + The parser token input queue.
		 ++/
		DList!Token input;

	}

	/++
	 + Constructs a new parser with the given parse table.
	 ++/
	this(ParseTable table)
	{
		this.table = table;
	}

	/++
	 + Parses an input string of tokens.
	 +
	 + Returns:
	 +     The list of parser rule that were matched.
	 ++/
	Rule[] parse(Token[] tokens)
	{
		Rule[] output;
		
		stack = new Stack!Token;
		input = DList!Token(tokens);

		// Prepare stack.
		stack.push(eof);
		stack.push(start);

		while(!stack.empty)
		{
			if(stack.top > epsilon)
			{
				// Look up parser rule.
				Rule rule = table[stack.pop, input.front];

				// Push rule RHS to stack.
				import std.range : retro;
				foreach(token; table[rule].retro)
				{
					stack.push(token);
				}

				// Save rule.
				output ~= rule;
			}
			else if(stack.top == input.front)
			{
				// Match input token.
				input.removeFront;
				stack.pop;
			}
			else if(stack.top == epsilon)
			{
				// Match nothing.
				stack.pop;
			}
			else
			{
				assert(0, "Syntax error.");
			}
		}

		return output;
	}

}

/+
 + Grammar 2:
 +
 + E → E + E
 +   | P
 +
 + P → 1
 +
 +/
unittest
{
	import derpi.builder;

	/++
	 + Define grammar tokens.
	 ++/
	enum : Token
	{

		// Terminals

		One = -3,
		Plus = -2,

		// Non Terminals

		E = 1,
		P = 2,
		F = 3

	}

	auto builder = new TableBuilder;

	builder
		.addRule(E, [E, Plus, E])
		.addRule(E, [P])
		.addRule(P, [One]);

	auto table = builder.build;
	auto parser = new Parser(table);

	// Parse input: 1 + 1 + 1 $
	auto output = parser.parse(
		[One, Plus, One, Plus, One, eof]
	);

	// Validate parser output.
	assert(output == [
		1, 2, 3, 2, 3, 2, 4
	]);
}
