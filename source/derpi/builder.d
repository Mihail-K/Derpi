
module derpi.builder;

import derpi.table;
import derpi.helper;

class TableBuilder
{

	import std.array;
	import std.algorithm;

	struct Production
	{

		/++
		 + The number of the production rule.
		 ++/
		Rule rule;

		/++
		 + The left hand side of the rule.
		 ++/
		NonTerminal lhs;

		/++
		 + The right hand side of the rule.
		 ++/
		int[] rhs;

		this(NonTerminal hls, int[] rhs)
		{
			this.lhs = lhs;
			this.rhs = rhs;
		}

		this(Rule rule, NonTerminal lhs, int[] rhs)
		{
			this.rule = rule;
			this.lhs = lhs;
			this.rhs = rhs;
		}

		bool isLeftRecursive()
		{
			return lhs == rhs[0];
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

		/++
		 + An lhs-indexed cache for production rules.
		 ++/
		Production[][NonTerminal] productionCache;

	}

	this()
	{
		terminals = new OrderedSet!Terminal;
		nonterminals = new OrderedSet!NonTerminal;
		productions = new OrderedSet!Production;
	}

	/++
	 + Adds a production rule to the grammar.
	 ++/
	TableBuilder addRule(NonTerminal lhs, int[] rhs)
	{
		// Create a production rule.
		productions ~= Production(
			productions.length, lhs, rhs
		);

		// Register tokens.
		nonterminals ~= lhs;
		foreach(token; rhs)
		{
			// Check for terminal.
			if(token < epsilon)
			{
				terminals ~= token;
			}
			// Check for nonterminal.
			else if(token > epsilon)
			{
				nonterminals ~= token;
			}
		}

		return this;
	}

	ParseTable build()
	{
		// Remove left recursion.
		removeLeftRecursion;

		// TODO
		return null;
	}

	private
	{
	
		Production[] getFromCache(NonTerminal lhs)
		{
			// Check for cached rules.
			auto rules = lhs in productionCache;

			if(rules is null)
			{
				// Filter matching rules.
				auto matches = productions[]
					.filter!(p => p.lhs == lhs)
					.array;

				// Cache the matching rules.
				productionCache[lhs] = matches;
				return matches;
			}
			else
			{
				return *rules;
			}
		}

		/++
		 + Returns a list of non-empty left-recursive rules.
		 ++/
		Production[] getAlphaSets(NonTerminal lhs)
		{
			return getFromCache(lhs)
				.filter!(p => p.rhs[0] == lhs)
				.filter!(p => p.rhs[1 .. $] != [epsilon])
				.array;
		}

		/++
		 + Returns a list of non-left-recursive rules.
		 ++/
		Production[] getBetaSets(NonTerminal lhs)
		{
			return getFromCache(lhs)
				.filter!(p => p.rhs[0] != lhs)
				.array;
		}
		
		void removeLeftRecursion()
		{
			// Loop until equilibrium.
			for(bool changed; changed;)
			{
				changed = false;

				foreach(production; productions)
				{
					// A → Aα₁ | ... | Aαₙ | β₁ | ... | βₘ
					if(production.isLeftRecursive)
					{
						// A' := max(A) + 1
						int tail = productions.length + 1;
					
						// α → α₁, α₂, ..., αₙ
						Production[] alpha = getAlphaSets(production.lhs);
					
						// β → β₁, β₂, ..., βₘ
						Production[] beta = getBetaSets(production.lhs);

						// Remove left recursive rules from grammar and cache.
						productions = productions[].filter!"!a.isLeftRecursive".array;
						productionCache.remove(production.lhs);

						foreach(rule; beta)
						{
							// A → β₁A' | β₂A' | ... | βₘA'
							productions ~= Production(
								productions.length, rule.lhs, rule.rhs ~ tail
							);
						}

						foreach(rule; alpha)
						{
							// A' → α₁A' | α₂A' | ... | αₙA'
							productions ~= Production(
								productions.length, tail, rule.rhs ~ tail
							);
						}
						
						// A' → ε
						productions ~= Production(
							productions.length, tail, [epsilon]
						);

						// Add tail to nonterminals.
						nonterminals ~= tail;
						changed = true;
						break;
					}
				}
			}
		}

	}

}
