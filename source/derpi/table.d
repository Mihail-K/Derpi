
module derpi.table;

import derpi.helper;

class ParseTable
{

	private
	{

		Rule[Terminal][NonTerminal] table;

		Token[][Rule] rhs;
	
	}

	Token[] opIndex(Rule rule)
	{
		return rhs[rule];
	}

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

	void opIndexAssign(Token[] rhs, Rule rule)
	in
	{
		assert(rule !in this.rhs);
	}
	body
	{
		this.rhs[rule] = rhs;
	}

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
