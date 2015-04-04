
module derpi.builder;

import derpi.helper;

class TableBuilder
{

	struct Production
	{

		/++
		 + The number of the production rule.
		 ++/
		Rule rule;

		/++
		 + The left hand side of the rule.
		 ++/
		int lhs;

		/++
		 + The right hand side of the rule.
		 ++/
		int[] rhs;

		this(int hls, int[] rhs)
		{
			this.lhs = lhs;
			this.rhs = rhs;
		}

		this(Rule rule, int lhs, int[] rhs)
		{
			this.rule = rule;
			this.lhs = lhs;
			this.rhs = rhs;
		}

		int opCmp(Production p)
		{
			// Compare lhs values.
			int diff = p.lhs - lhs;

			if(diff != 0)
			{
				// Compare rhs lengths.
				diff = p.rhs.length - rhs.length;

				if(diff != 0)
				{
					// Compare rhs values.
					foreach(i, v; rhs)
					{
						diff += p.rhs[i] - v;
					}
				}
			}

			return diff;
		}

		bool opEquals(const ref Production p) const
		{
			return lhs == p.lhs && rhs == p.rhs;
		}

	}

	private
	{

		/++
		 + The set of terminals in the grammar.
		 ++/
		OrderedSet!Terminal terminals;

		/++
		 + The set of nonterminals in the grammar.
		 ++/
		OrderedSet!NonTerminal nonterminals;

		/++
		 + The set of production rules in the grammar.
		 ++/
		OrderedSet!Production productions;

	}

	this()
	{
		terminals = new OrderedSet!Terminal;
		nonterminals = new OrderedSet!NonTerminal;
	}

	TableBuilder addRule(int left, int[] rhs)
	{
		return this;
	}

}
