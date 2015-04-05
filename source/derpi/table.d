
module derpi.table;

import derpi.helper;

/++
 + An LL parse table.
 ++/
class ParseTable
{

	private
	{

		/++
		 + The LL parser rule table.
		 ++/
		Rule[Terminal][NonTerminal] table;

		/++
		 + The list of RHS values for parser rules.
		 ++/
		Token[][Rule] rhs;
	
	}

	/++
	 + Returns the RHS value for a given parser rule.
	 ++/
	Token[] opIndex(Rule rule)
	{
		return rhs[rule];
	}

	/++
	 + Returns a parser rule that matches an input state.
	 +
	 + Returns:
	 +     The matching parser rule, or 0.
	 ++/
	Rule opIndex(NonTerminal n, Terminal t)
	{
		if(t in table[n])
		{
			return table[n][t];
		}
		else if(epsilon in table[n])
		{
			return table[n][epsilon];
		}
		else
		{
			return 0; // Error
		}
	}

	/++
	 + Assigns an RHS value to a parser rule.
	 ++/
	void opIndexAssign(Token[] rhs, Rule rule)
	in
	{
		assert(rule !in this.rhs);
	}
	body
	{
		this.rhs[rule] = rhs;
	}

	/++
	 + Assigns a parser rule to an input state.
	 ++/
	void opIndexAssign(Rule rule, NonTerminal n, Terminal t)
	in
	{
		assert(n !in table || t !in table[n]);
	}
	body
	{
		table[n][t] = rule;
	}

}
