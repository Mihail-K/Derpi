
module derpi.table;

import derpi.helper;

class ParseTable
{

	private
	{

		Rule[Terminal][NonTerminal] table;

		int[][Rule] rhs;
	
	}

	int[] opIndex(Rule rule)
	{
		return rhs[rule];
	}

	Rule opIndex(NonTerminal n, Terminal t)
	{
		return table[n][t];
	}

	void opIndexAssign(int[] rhs, Rule rule)
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
