
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
		 + The left hand side of the rule.
		 ++/
		NonTerminal lhs;

		/++
		 + The right hand side of the rule.
		 ++/
		int[] rhs;

		this(NonTerminal lhs, int[] rhs)
		{
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
			int diff = lhs - p.lhs;

			if(diff == 0)
			{
				// Compare rhs lengths.
				diff = rhs.length - p.rhs.length;

				if(diff == 0)
				{
					// Compare rhs values.
					foreach(i, v; rhs)
					{
						diff += v - p.rhs[i];
					}
				}
			}

			return diff;
		}

		bool opEquals(const ref Production p) const
		{
			return lhs == p.lhs && rhs == p.rhs;
		}

		string toString()
		{
			import std.string : format;

			return format("[%d : %(%d, %)]", lhs, rhs);
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
		UnorderedSet!Production productions;

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

	/++
	 + Constructs an empty parse table builder.
	 ++/
	this()
	{
		terminals = new OrderedSet!Terminal;
		nonterminals = new OrderedSet!NonTerminal;
		productions = new UnorderedSet!Production;
	}

	/++
	 + Adds a production rule to the grammar.
	 ++/
	TableBuilder addRule(NonTerminal lhs, int[] rhs)
	{
		// Create a production rule.
		productions ~= Production(lhs, rhs);

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

		// Remove FIRST/FIRST conflicts.
		removeFirstFirstConflicts;

		// Compute FIRST sets.
		computeFirstSets;

		// Compute FOLLOW sets.
		computeFollowSets;

		// Compute PREDICT sets.
		computePredictSets;

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
		OrderedSet!Terminal first(NonTerminal[] alpha...)
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

		/++
		 + Let α be a nonterminal.
		 + FOLLOW(α) is the union over FIRST(β) where β is any nonterminal that
		 + immidiately follows α in the right hand side of a production rule.
		 +
		 + Params:
		 +     alpha = A nonterminal.
		 +
		 + Returns:
		 +     An ordered set of terminals.
		 ++/
		OrderedSet!Terminal follow(NonTerminal alpha)
		{
			return followSets[alpha];
		}

		/++
		 + Let A be a production rule.
		 + PREDICT(A) is the set of all FIRST tokens that can be derived from A.
		 +
		 + Params:
		 +     production = A production rule in the grammar.
		 +
		 + Returns:
		 +     An ordered set of terminals.
		 ++/
		OrderedSet!Terminal predict(Rule rule)
		{
			return predictSets[rule];
		}

	}

	private
	{
	
		/++
		 + Returns a list of production rules with the given lhs.
		 ++/
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

			// α → α₁, α₂, ..., αₙ
			foreach(alphaRule; alpha)
			{
				// If ε ∈ αᵢ
				if(alphaRule.canFind(lhs))
				{
					// β → β₁, β₂, ..., βₘ
					foreach(betaRule; beta)
					{
						int[] rhs;

						// Substitute A with β.
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
							productions ~= Production(lhs, rhs ~ tail);
						}

						foreach(rhs; alpha)
						{
							// A' → α₁A' | α₂A' | ... | αₙA'
							productions ~= Production(tail, rhs ~ tail);
						}
						
						// A' → ε
						productions ~= Production(tail, [epsilon]);

						// Add tail to nonterminals.
						nonterminals ~= tail;
						changed = true;
						break;
					}
				}
			}
		}

		int[][] getGammaSets(Production production)
		{
			return getFromCache(production.lhs)
				.filter!(p => p.rhs[0] == production.rhs[0])
				.map!(p => p.rhs)
				.array;
		}

		void removeFirstFirstConflicts()
		{
			// Loop until equilibrium.
			for(bool changed = true; changed;)
			{
				changed = false;
				
				// A → αɣ₁ | αɣ₂ | ... | Aɣₙ
				foreach(production; productions)
				{
					int[][] gamma = getGammaSets(production);

					if(gamma.length > 1)
					{
						// A' := max(A) + 1
						int tail = nonterminals.reduce!max + 1;

						// Remove FIRST/FIRST conflicting rules from grammar and cache.
						productions = productions[].filter!(p =>
							 p.lhs != production.lhs || p.rhs[0] != production.rhs[0]).array;
						productionCache.remove(production.lhs);

						// A → αA'
						productions ~= Production(production.lhs, [production.rhs[0], tail]);

						import std.stdio;
						foreach(rhs; gamma)
						{
							// A' → ɣ₁ | ɣ₂ | ... | ɣₙ
							productions ~= Production(tail, rhs[1 .. $]);
						}

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
		
		void computePredictSets()
		{
			int nextRule = 1;
			foreach(production; productions)
			{
				int rule = nextRule++;
				auto falpha = first(production.rhs);

				// PREDICT(A → α) := FIRST(α)
				predictSets[rule] = falpha - epsilon;

				// If ε ∈ FIRST(α)
				if(epsilon in falpha)
				{
					// PREDICT(A → α) ∪ FOLLOW(A)
					predictSets[rule] ~= follow(production.lhs);
				}
			}
		}

	}

}


/+
 + Grammar 1:
 +
 + A → B C Ω
 + 
 + B → bB
 +   | ε
 +
 + C → c
 +   | ε
 +
 +/
unittest
{
	/++
	 + Define grammar tokens.
	 ++/
	enum : int
	{

		// Terminals

		c = -4,
		b = -3,
		Ω = -2,

		// Non Terminals
		
		A = 1,
		B = 2,
		C = 3

	}

	auto builder = new TableBuilder;

	builder
		.addRule(A, [B, C, Ω])
		.addRule(B, [b, B])
		.addRule(B, [epsilon])
		.addRule(C, [c])
		.addRule(C, [epsilon]);

	// Validate token sets.
	assert(builder.terminals == [c, b, Ω]);
	assert(builder.nonterminals == [A, B, C]);

	// Validate rules and ordering.
	assert(builder.productions == [
		builder.Production(A, [B, C, Ω]),
		builder.Production(B, [b, B]),
		builder.Production(B, [epsilon]),
		builder.Production(C, [c]),
		builder.Production(C, [epsilon]),
	]);

	builder.build;

	// Validate rule factoring and resolution.
	assert(builder.productions == [
		builder.Production(A, [B, C, Ω]),
		builder.Production(B, [b, B]),
		builder.Production(B, [epsilon]),
		builder.Production(C, [c]),
		builder.Production(C, [epsilon]),
	]);

	// Validate FIRST sets.
	assert(builder.first(A) == [c, b, Ω]);
	assert(builder.first(B) == [b, epsilon]);
	assert(builder.first(C) == [c, epsilon]);

	// Validate FOLLOW sets.
	assert(builder.follow(A) == [eof]);
	assert(builder.follow(B) == [c, Ω]);
	assert(builder.follow(C) == [Ω]);

	// Validate PREDICT sets.
	assert(builder.predict(1) == [c, b, Ω]);
	assert(builder.predict(2) == [b]);
	assert(builder.predict(3) == [c, Ω]);
	assert(builder.predict(4) == [c]);
	assert(builder.predict(5) == [Ω]);
}
