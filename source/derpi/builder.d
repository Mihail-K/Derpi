
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

			if(diff == 0)
			{
				// Compare rhs lengths.
				diff = p.rhs.length - rhs.length;

				if(diff == 0)
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

		
		/++
		 + The computed FIRST sets for the grammar.
		 ++/
		OrderedSet!Terminal[int] firstSets;

		/++
		 + The computed FOLLOW sets for the grammar.
		 ++/
		OrderedSet!Terminal[int] followSets;

		/++
		 + The computed PREDICT sets for the grammar.
		 ++/
		OrderedSet!Terminal[int] predictSets;

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

		// Compute FIRST sets.
		computeFirstSets;

		// Compute FOLLOW sets.
		computeFollowSets;

		// TODO
		return null;
	}

	private
	{
	
		/++
		 + Let α be a nonterminal.
		 + FIRST(α) is the set of terminals that can appear in the first position
		 + of any string derived from α.
		 +
		 + Params:
		 +     alpha = A nonterminal.
		 +
		 + Returns:
		 +     An ordered set of terminals.
		 ++/
		OrderedSet!Terminal first(int[] alpha...)
		{
			int count = 0;
			auto sets = new OrderedSet!int;

			// For each α → X₁, X₂, ..., Xₖ
			foreach(i, X; alpha)
			{
				// If ε ∈ FIRST(Xᵢ)
				if(epsilon in firstSets[X])
				{
					count++;
				}

				if(i == 0)
				{
					// FIRST(α) ∪ { FIRST(Xᵢ) - ε } 
					sets ~= firstSets[X] - epsilon;
				}
				else
				{
					// If ε ∈ FIRST(Xᵢ₋₁) when 1 < i ≤ k
					if(epsilon in firstSets[alpha[i - 1]])
					{
						// FIRST(α) ∪ { FIRST(Xᵢ) - ε }
						sets ~= firstSets[X] - epsilon;
					}
				}
			}
		
			// If ε ∈ FIRST(Yᵢ) for 1 ≤ i ≤ k
			if(count == alpha.length)
			{
				sets ~= epsilon;
			}

			return sets;
		}

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
		int[][] getAlphaSets(NonTerminal lhs)
		{
			return getFromCache(lhs)
				.filter!(p => p.rhs[0] == lhs)
				.filter!(p => p.rhs[1 .. $] != [epsilon])
				.map!(p => p.rhs[1 .. $])
				.array;
		}

		/++
		 + Returns a list of non-left-recursive rules.
		 ++/
		int[][] getBetaSets(NonTerminal lhs)
		{
			return getFromCache(lhs)
				.filter!(p => p.rhs[0] != lhs)
				.map!(p => p.rhs)
				.array;
		}

		/++
		 + Replaces ambiguous references to A in α with β.
		 ++/
		int[][] expandAmbiguous(NonTerminal lhs, int[][] alpha, int[][] beta)
		{
			int[][] result;

			foreach(alphaRule; alpha)
			{
				if(alphaRule.canFind(lhs))
				{
					foreach(betaRule; beta)
					{
						int[] rhs;

						foreach(token; alphaRule)
						{
							if(token == lhs)
							{
								rhs ~= betaRule;
							}
							else
							{
								rhs ~= token;
							}
						}

						result ~= rhs;
					}
				}
			}

			return result;
		}
		
		void removeLeftRecursion()
		{
			// Loop until equilibrium.
			for(bool changed = true; changed;)
			{
				changed = false;

				foreach(production; productions)
				{
					// A → Aα₁ | ... | Aαₙ | β₁ | ... | βₘ
					if(production.isLeftRecursive)
					{
						int lhs = production.lhs;

						// A' := max(A) + 1
						int tail = nonterminals.reduce!max + 1;
					
						// α → α₁, α₂, ..., αₙ
						int[][] alpha = getAlphaSets(lhs);
					
						// β → β₁, β₂, ..., βₘ
						int[][] beta = getBetaSets(lhs);
						
						// Expand ambiguous references to A in α.
						alpha = expandAmbiguous(lhs, alpha, beta);

						// Remove left recursive rules from grammar and cache.
						productions = productions[].filter!(p => p.lhs != lhs).array;
						productionCache.remove(lhs);

						foreach(rhs; beta)
						{
							// A → β₁A' | β₂A' | ... | βₘA'
							productions ~= Production(
								productions.length, lhs, rhs ~ tail
							);
						}

						foreach(rhs; alpha)
						{
							// A' → α₁A' | α₂A' | ... | αₙA'
							productions ~= Production(
								productions.length, tail, rhs ~ tail
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

		void computeFirstSets()
		{
			// Build sets of terminals.
			foreach(t; terminals)
			{
				firstSets[t] = new OrderedSet!Terminal(t);
			}

			// Include epsilon in the FIRST sets.
			firstSets[epsilon] = new OrderedSet!Terminal(epsilon);

			// Initialize sets of nonterminals.
			foreach(n; nonterminals)
			{
				firstSets[n] = new OrderedSet!Terminal;
			}

			// Loop until equilibrium.
			for(bool changed = true; changed;)
			{
				changed = false;

				foreach(production; productions)
				{
					int count = 0;
					int X = production.lhs;

					// Save the old value of the FIRST set.
					auto initial = firstSets[X].dup;

					// For each X → Y₁, Y₂, ..., Yₖ
					foreach(i, Y; production.rhs)
					{
						// If ε ∈ FIRST(Yᵢ)
						if(epsilon in firstSets[Y])
						{
							count++;
						}

						if(i == 0)
						{
							// FIRST(X) ∪ { FIRST(Yᵢ) - ε } 
							firstSets[X] ~= firstSets[Y] - epsilon;
						}
						else
						{
							// If ε in FIRST(Yᵢ₋₁) when 1 < i ≤ k
							if(epsilon in firstSets[production.rhs[i - 1]])
							{
								// FIRST(X) ∪ { FIRST(Yᵢ) - ε }
								firstSets[X] ~= firstSets[Y] - epsilon;
							}
						}
					}

					// If ε ∈ FIRST(Yᵢ) for 1 ≤ i ≤ k
					if(count == production.rhs.length)
					{
						firstSets[X] ~= epsilon;
					}

					// Check if the FIRST set was changed.
					changed |= initial != firstSets[X];
				}
			}
		}

		void computeFollowSets()
		{
			// FOLLOWS(...) := { }
			foreach(n; nonterminals)
			{
				followSets[n] = new OrderedSet!int;
			}

			// FOLLOW(S) := EOF
			followSets[start] = new OrderedSet!int(eof);

			// Loop until equilibrium.
			for(bool changed = true; changed;)
			{
				changed = false;

				foreach(production; productions)
				{
					int A = production.lhs;

					foreach(i, B; production.rhs)
					{
						if(B > epsilon)
						{
							// Save the old value of the FOLLOW set.
							auto initial = followSets[B].dup;

							int[] beta = production.rhs[i + 1 .. $];

							followSets[B] ~= first(beta) - epsilon;
							if(beta.length == 0 || epsilon in first(beta))
							{
								followSets[B] ~= followSets[A];
							}
							
							// Check if the FOLLOW set was changed.
							changed |= initial != followSets[B];
						}
					}
				}
			}
		}

	}

}
