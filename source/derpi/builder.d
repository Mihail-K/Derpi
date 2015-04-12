
module derpi.builder;

import std.array;
import std.algorithm;

import derpi.table;
import derpi.helper;

class Production
{

	/++
	 + The left hand side of the rule.
	 ++/
	NonTerminal lhs;

	/++
	 + The right hand side of the rule.
	 ++/
	Token[][] rhs;

	/++
	 + A table mapping rule ids to rhs indexes.
	 ++/
	Rule[int] rule;

	/++
	 + Contructs a new production ruleset.
	 +
	 + Params:
	 +     lhs = The left hand side of the rules.
	 +     rhs = The right hand sides of the rules.
	 ++/
	this(NonTerminal lhs, Token[][] rhs = []...)
	{
		this.lhs = lhs;
		this.rhs = rhs;
	}

	/++
	 + Tests if the ruleset is left recursive.
	 ++/
	bool isLeftRecursive()
	{
		// REQUIRED : DMD 2.067 CTFE delegate bug.
		NonTerminal lhs = this.lhs;

		return rhs.filter!(r => r[0] == lhs).any;
	}

	/++
	 + Returns the alpha fragments of left recursive rules in this production set.
	 ++/
	Token[][] getAlphaSets()
	{
		if(isLeftRecursive)
		{
			// REQUIRED : DMD 2.067 CTFE delegate bug.
			NonTerminal lhs = this.lhs;

			return rhs
				.filter!(r => r[0] == lhs)
				.filter!(r => r != [epsilon])
				.filter!(r => r.length > 1)
				.map!(r => r[1 .. $])
				.array;
		}
		else
		{
			// No alpha sets.
			return [[]];
		}
	}

	/++
	 + Returns the beta fragments of non left recursive rules in this production set.
	 ++/
	Token[][] getBetaSets()
	{
		if(isLeftRecursive)
		{
			// REQUIRED : DMD 2.067 CTFE delegate bug.
			NonTerminal lhs = this.lhs;

			return rhs
				.filter!(r => r.length > 0)
				.filter!(r => r[0] != lhs)
				.array;
		}
		else
		{
			// No beta sets.
			return [[]];
		}
	}

	/++
	 + Returns the gamma fragments of FIRST/FIRST colliding rules in this production set.
	 ++/
	Token[][] getGammaSets(Token leftmost)
	{
		return rhs
			.filter!(r => r.length > 0)
			.filter!(r => r[0] == leftmost)
			.array;
	}

	/++
	 + Compares this production set to another.
	 ++/
	override int opCmp(Object o)
	{
		// Compare lhs values.
		Production p = cast(Production)o;
		return lhs - p.lhs;
	}

	/++
	 + Tests for equality against another production set.
	 ++/
	override bool opEquals(Object o)
	{
		Production p = cast(Production)o;
		return o ? lhs == p.lhs && rhs == p.rhs : false;
	}

	/++
	 + Returns a string representation of the rule.
	 ++/
	override string toString()
	{
		import std.string : format;

		return format("[%d : %(%s, %)]", lhs, rhs);
	}

}

class GrammarBuilder
{

	private
	{

		/++
		 + The name of the grammar produced.
		 ++/
		string name;


		/++
		 + The eof token defined by the grammar.
		 ++/
		Terminal eofToken = eof;

		/++
		 + The starting rule for the grammar.
		 ++/
		NonTerminal startRule = start;

		/++
		 + The set of terminals in the grammar.
		 ++/
		OrderedSet!Terminal terminals;

		/++
		 + The set of nonterminals in the grammar.
		 ++/
		OrderedSet!NonTerminal nonterminals;

		/++
		 + The table of names of terminals.
		 ++/
		string[Terminal] terminalNames;

		/++
		 + The table of names of nonterminals.
		 ++/
		string[NonTerminal] nonterminalNames;


		/++
		 + The set of production rules in the grammar.
		 ++/
		OrderedSet!Production productions;

		/++
		 + The table of transformations applied to the grammar.
		 ++/
		NonTerminal[NonTerminal] transformations;

		
		/++
		 + The computed FIRST sets for the grammar.
		 ++/
		OrderedSet!Terminal[NonTerminal] firstSets;

		/++
		 + The computed FOLLOW sets for the grammar.
		 ++/
		OrderedSet!Terminal[NonTerminal] followSets;

		/++
		 + The computed PREDICT sets for the grammar.
		 ++/
		OrderedSet!Terminal[Rule] predictSets;


		/++
		 + A cached reference to the constructed parse table.
		 ++/
		ParseTable parseTable;

	}

	/++
	 + Constructs an empty grammar builder.
	 ++/
	this(string name)
	{
		this.name = name;
		terminals = new OrderedSet!Terminal;
		nonterminals = new OrderedSet!NonTerminal;
		productions = new OrderedSet!Production;
	}

	/++
	 + Sets the EOF terminal for the grammar.
	 ++/
	GrammarBuilder setEOFToken(Terminal eofToken)
	{
		this.eofToken = eofToken;
		return this;
	}

	/++
	 + Sets the starting rule, for the grammar.
	 ++/
	GrammarBuilder setStartRule(NonTerminal startRule)
	{
		this.startRule = startRule;
		return this;
	}

	/++
	 + Adds a terminal to the grammar.
	 ++/
	GrammarBuilder addTerminal(string name, Terminal t)
	in
	{
		assert(t !in terminals);
	}
	body
	{
		terminalNames[t] = name;
		terminals ~= t;
		return this;
	}

	/++
	 + Adds a nonterminal to the grammar.
	 ++/
	GrammarBuilder addNonTerminal(string name, NonTerminal n)
	in
	{
		assert(n !in nonterminals);
	}
	body
	{
		nonterminalNames[n] = name;
		nonterminals ~= n;
		return this;
	}

	/++
	 + Adds a production rule to the grammar.
	 ++/
	GrammarBuilder addRule(NonTerminal lhs, Token[] rhs)
	{
		// Fetch the production rule.
		auto production = getProduction(lhs);

		// Create it if necessary.
		if(production is null)
		{
			production = new Production(lhs);
			productions ~= production;
		}

		// Append the new rhs value.
		production.rhs ~= rhs;

		// Validate tokens.
		foreach(token; lhs ~ rhs)
		{
			// Check for terminal.
			if(token < epsilon)
			{
				if(token !in terminals)
				{
					assert(0);
				}
			}
			// Check for nonterminal.
			else if(token > epsilon)
			{
				if(token !in nonterminals)
				{
					assert(0);
				}
			}
		}

		return this;
	}

	string build()
	{
		// TODO
		return buildParser;
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
			auto sets = new OrderedSet!Terminal;

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
		 + Records a transformation, and creates the new nonterminal.
		 ++/
		void addTransformation(NonTerminal initial, NonTerminal tail)
		in
		{
			assert(initial in nonterminals);
			assert(tail !in nonterminals);
		}
		body
		{
			// Create the new nonterminal.
			nonterminalNames[tail] = nonterminalNames[initial] ~ "Prime";
			transformations[tail] = initial;
			nonterminals ~= tail;
		}
	
		/++
		 + Returns a list of production rules with the given lhs.
		 ++/
		Production getProduction(NonTerminal lhs)
		{
			auto result = productions[].filter!(p => p.lhs == lhs).array;
			return result.length > 0 ? result[0] : null;
		}

		/++
		 + Returns a list of non-empty left-recursive rules.
		 ++/
		Token[][] getAlphaSets(NonTerminal lhs)
		{
			return getProduction(lhs).getAlphaSets();
		}

		/++
		 + Returns a list of non-left-recursive rules.
		 ++/
		Token[][] getBetaSets(NonTerminal lhs)
		{
			return getProduction(lhs).getBetaSets();
		}

		/++
		 + Replaces ambiguous references to A in α with β.
		 ++/
		Token[][] expandAmbiguous(NonTerminal lhs, Token[][] alpha, Token[][] beta)
		{
			Token[][] result;

			// α → α₁, α₂, ..., αₙ
			foreach(alphaRule; alpha)
			{
				// If ε ∈ αᵢ
				if(alphaRule.canFind(lhs))
				{
					// β → β₁, β₂, ..., βₘ
					foreach(betaRule; beta)
					{
						Token[] rhs;

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

				foreach(production; productions[])
				{
					// A → Aα₁ | ... | Aαₙ | β₁ | ... | βₘ
					if(production.isLeftRecursive)
					{
						Token[][] result;
						NonTerminal lhs = production.lhs;
						
						// β → β₁, β₂, ..., βₘ
						foreach(b; getBetaSets(lhs))
						{
							// α → α₁, α₂, ..., αₙ
							foreach(a; getAlphaSets(lhs))
							{
								// A → β₁α₁, β₁α₂, ..., βₘαₙ
								result ~= b ~ a;
							}

							// A → ... | β₁, β₂, ..., βₘ
							result ~= b;
						}

						// Update the rule's rhs.
						production.rhs = result;
						changed = true;
						break;
					}
				}
			}
		}

		/++
		 + Returns a list of rules that needs to be factored.
		 ++/
		Token[][] getGammaSets(NonTerminal lhs, Token leftmost)
		{
			return getProduction(lhs).getGammaSets(leftmost);
		}

		void removeFirstFirstConflicts()
		{
			// Loop until equilibrium.
			for(bool changed = true; changed;)
			{
				changed = false;
				
				// A → αɣ₁ | αɣ₂ | ... | Aɣₙ
				foreach(production; productions[])
				{
					foreach(i, rhs; production.rhs)
					{
						NonTerminal lhs = production.lhs;
						Token[][] gamma = getGammaSets(lhs, rhs[0]);
						
						if(gamma.length > 1)
						{
							// A' := max(A) + 1
							NonTerminal tail = nonterminals[].reduce!max + 1;
							
							// Remove FIRST/FIRST conflicting rules from grammar.
							production.rhs = production.rhs
									.filter!(r => r[0] != rhs[0]).array;
							
							// A → αA'
							production.rhs ~= [rhs[0], tail];
							
							// Create a new production rule.
							productions ~= new Production(
								// A' → ɣ₁ | ɣ₂ | ... | ɣₙ
								tail, gamma.map!(r =>
									r.length > 1 ? r[1 .. $] : [epsilon]).array
							);
					
							// Add tail to nonterminals.
							addTransformation(lhs, tail);
							
							changed = true;
							break;
						}
					}

					// Restart after changes.
					if(changed) break;
				}
			}
		}

		void computeFirstSets()
		{
			// Build sets of terminals.
			foreach(t; terminals[])
			{
				firstSets[t] = new OrderedSet!Terminal(t);
			}

			// Include epsilon in the FIRST sets.
			firstSets[epsilon] = new OrderedSet!Terminal(epsilon);

			// Initialize sets of nonterminals.
			foreach(n; nonterminals[])
			{
				firstSets[n] = new OrderedSet!Terminal;
			}

			// Loop until equilibrium.
			for(bool changed = true; changed;)
			{
				changed = false;

				foreach(production; productions[])
				{
					NonTerminal X = production.lhs;

					// Save the old value of the FIRST set.
					auto initial = firstSets[X].dup;

					foreach(rhs; production.rhs)
					{
						int count = 0;

						// X → Y₁, Y₂, ..., Yₖ
						foreach(i, Y; rhs)
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
								if(epsilon in firstSets[rhs[i - 1]])
								{
									// FIRST(X) ∪ { FIRST(Yᵢ) - ε }
									firstSets[X] ~= firstSets[Y] - epsilon;
								}
							}
						}

						// If ε ∈ FIRST(Yᵢ) for 1 ≤ i ≤ k
						if(count == rhs.length)
						{
							firstSets[X] ~= epsilon;
						}
					}

					// Check if the FIRST set was changed.
					changed |= initial != firstSets[X];
				}
			}
		}

		void computeFollowSets()
		{
			// FOLLOWS(...) := { }
			foreach(n; nonterminals[])
			{
				followSets[n] = new OrderedSet!Terminal;
			}

			// FOLLOW(S) := EOF
			followSets[startRule] = new OrderedSet!Terminal(eofToken);

			// Loop until equilibrium.
			for(bool changed = true; changed;)
			{
				changed = false;

				foreach(production; productions[])
				{
					NonTerminal A = production.lhs;

					foreach(rhs; production.rhs)
					{
						foreach(i, B; rhs)
						{
							if(B > epsilon)
							{
								// Save the old value of the FOLLOW set.
								auto initial = followSets[B].dup;

								Token[] beta = rhs[i + 1 .. $];

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
		
		void computePredictSets()
		{
			Rule nextRule = 1;
			foreach(production; productions[])
			{
				foreach(rhs; production.rhs)
				{
					Rule rule = nextRule++;
					auto falpha = first(rhs);

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

	private
	{
		
		/++
		 + Constructs a parse table based on the input grammar.
		 +
		 + Returns:
		 +     The constructed parse table.
		 ++/
		ParseTable buildParseTable()
		{
			if(parseTable is null)
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

				Rule rule = 1;
				parseTable = new ParseTable;

				// Construct the parse table.
				foreach(production; productions[])
				{
					foreach(idx, rhs; production.rhs)
					{
						auto elements = predict(rule);

						foreach(token; elements[])
						{
							// Build the parse table rules.
							parseTable[production.lhs, token] = rule;
						}

						// Include the rhs for the rule.
						production.rule[idx] = rule;
						parseTable[rule++] = rhs;
					}
				}
			}
			
			return parseTable;
		}

	}

	private
	{

		import std.array;
		import std.string;

		string buildParserTypes()
		{
			auto buffer = appender!string;

			// Build tree node types.
			foreach(production; productions[])
			{
				buffer ~= buildParserType(production);
			}

			return buffer.data;
		}

		string buildParserType(Production production)
		{
			auto buffer = appender!string;

			// Generate tree node delcaration.
			string name = nonterminalNames[production.lhs];
			buffer ~= format("class %sNode : TreeNode", name);
			buffer ~= "{";

			// TODO : Implement body.
			buffer ~= "override void build() { }";

			// Close node declaration.
			buffer ~= "}";

			return buffer.data;
		}

		int[Token] getUsageMax(Production production)
		{
			int[Token] total;

			foreach(rhs; production.rhs)
			{
				int[Token] local;

				// Calculate local maximums.
				foreach(token; rhs)
				{
					if(token in local)
					{
						local[token]++;
					}
					else
					{
						local[token] = 1;
					}
				}

				// Merge result into global maximums.
				foreach(token, count; local)
				{
					if(token in total)
					{
						total[token] = max(total[token], count);
					}
					else
					{
						total[token] = count;
					}
				}
			}

			return total;
		}

	}

	private
	{

		import std.array;
		import std.string;

		string buildParser()
		{
			auto buffer = appender!string;
			auto table = buildParseTable;

			// Generate the parser declaration.
			buffer ~= format("class %sParser : Parser", name);
			buffer ~= "{";

			// Include tree node types.
			buffer ~= buildParserTypes;

			// Include a constructor.
			buffer ~= "this(ParserToken[] tokens)";
			buffer ~= "{ super(tokens); }";

			foreach(production; productions[])
			{
				buffer ~= buildParserRule(table, production);
			}

			// Close the declaration.
			buffer ~= "}";

			return buffer.data;
		}

		string buildParserRule(ParseTable table, Production production)
		{
			auto buffer = appender!string;

			// Generate the function declaration.
			string name = nonterminalNames[production.lhs];
			buffer ~= format("TreeNode %s()", name);
			buffer ~= "{";

			// Declare and initialize the tree node.
			buffer ~= format("auto node = new %sNode;", name);

			// Build parser rule body.
			foreach(idx, rhs; production.rhs)
			{
				// Fetch rule and predict set.
				Rule rule = production.rule[idx];
				foreach(element; predict(rule)[])
				{
					// Check against the predicted element.
					buffer ~= format("if(match(%d))", element);
					buffer ~= "{";

					// Generate rule body.
					foreach(token; rhs)
					{
						// Check for nonterminal.
						if(token > epsilon)
						{
							string func = nonterminalNames[token];
							buffer ~= format(`writeln("%s");`, func);
							buffer ~= format("node.children ~= %s();", func);
						}
						// Check for terminal.
						else if(token < epsilon)
						{
							buffer ~= format("expect(%d);", token);
							buffer ~= format(`writeln("%d");`, token);
							buffer ~= "node.children ~= new TerminalNode(last.text);";
						}
						// Epsilon.
						else
						{
							buffer ~= "/* epsilon */";
						}
					}

					// Close the rule body.
					buffer ~= "return node;";
					buffer ~= "}";
				}
			}

			// Rule failed to match.
			buffer ~= "import std.conv : text;";
			buffer ~= format(`assert(0, "%s" ~ current.type.text);`, name);

			// Close the declaration.
			buffer ~= "}";

			return buffer.data;
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
	enum : Token
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

	auto builder = new GrammarBuilder("Grammar1");

	builder
		// Terminals
		.addTerminal("c", c)
		.addTerminal("b", b)
		.addTerminal("Ω", Ω)

		// Nonterminals
		.addNonTerminal("A", A)
		.addNonTerminal("B", B)
		.addNonTerminal("C", C)

		// Productions
		.addRule(A, [B, C, Ω])
		.addRule(B, [b, B])
		.addRule(B, [epsilon])
		.addRule(C, [c])
		.addRule(C, [epsilon]);

	// Validate token sets.
	assert(builder.terminals[] == [c, b, Ω]);
	assert(builder.nonterminals[] == [A, B, C]);

	// Validate rules and ordering.
	assert(builder.productions[] == [
		new Production(A, [B, C, Ω]),
		new Production(B, [b, B], [epsilon]),
		new Production(C, [c], [epsilon])
	]);

	auto table = builder.buildParseTable;

	// Validate rules and ordering.
	assert(builder.productions[] == [
		new Production(A, [B, C, Ω]),
		new Production(B, [b, B], [epsilon]),
		new Production(C, [c], [epsilon])
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

	// Validate parse table.
	assert(table[A, Ω] == 1);
	assert(table[A, b] == 1);
	assert(table[A, c] == 1);

	assert(table[B, Ω] == 3);
	assert(table[B, b] == 2);
	assert(table[B, c] == 3);

	assert(table[C, b] == 0);
	assert(table[C, Ω] == 5);
	assert(table[C, c] == 4);
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

	auto builder = new GrammarBuilder("Grammar2");

	builder
		// Terminals
		.addTerminal("One", One)
		.addTerminal("Plus", Plus)

		// Nonterminals
		.addNonTerminal("E", E)
		.addNonTerminal("P", P)

		// Productions
		.addRule(E, [E, Plus, E])
		.addRule(E, [P])
		.addRule(P, [One]);

	// Validate token sets.
	assert(builder.terminals[] == [One, Plus]);
	assert(builder.nonterminals[] == [E, P]);

	// Validate rules and ordering.
	assert(builder.productions[] == [
		new Production(E, [E, Plus, E], [P]),
		new Production(P, [One])
	]);
	
	auto table = builder.buildParseTable;

	// Validate rules and ordering.
	assert(builder.productions[] == [
		new Production(E, [P, F]),
		new Production(P, [One]),
		new Production(F, [Plus, E], [epsilon])
	]);

	// Validate FIRST sets.
	assert(builder.first(P) == [One]);
	assert(builder.first(E) == [One]);
	assert(builder.first(F) == [Plus, epsilon]);

	// Validate FOLLOW sets.
	assert(builder.follow(P) == [Plus, eof]);
	assert(builder.follow(E) == [eof]);
	assert(builder.follow(F) == [eof]);

	// Validate PREDICT sets.
	assert(builder.predict(1) == [One]);
	assert(builder.predict(2) == [One]);
	assert(builder.predict(3) == [Plus]);
	assert(builder.predict(4) == [eof]);

	// Validate parse table.
	assert(table[E, One] == 1);
	assert(table[E, Plus] == 0);
	assert(table[E, eof] == 0);

	assert(table[P, One] == 2);
	assert(table[P, Plus] == 0);
	assert(table[P, eof] == 0);

	assert(table[F, One] == 0);
	assert(table[F, Plus] == 3);
	assert(table[F, eof] == 4);
}

/+
 + Grammar 3:
 +
 + E → E + E
 +   | E + + E
 +   | P
 +
 + P → 1
 +
 +/
unittest
{
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
		F = 3,
		G = 4

	}

	auto builder = new GrammarBuilder("Grammar3");

	builder
		// Terminals
		.addTerminal("One", One)
		.addTerminal("Plus", Plus)

		// Nonterminals
		.addNonTerminal("E", E)
		.addNonTerminal("P", P)

		// Productions
		.addRule(E, [E, Plus, E])
		.addRule(E, [E, Plus, Plus, E])
		.addRule(E, [P])
		.addRule(P, [One]);

	// Validate token sets.
	assert(builder.terminals[] == [One, Plus]);
	assert(builder.nonterminals[] == [E, P]);

	// Validate rules and ordering.
	assert(builder.productions[] == [
		new Production(E, [E, Plus, E], [E, Plus, Plus, E], [P]),
		new Production(P, [One])
	]);
	
	auto table = builder.buildParseTable;

	// Validate rules and ordering.
	assert(builder.productions[] == [
		new Production(E, [P, F]),
		new Production(P, [One]),
		new Production(F, [epsilon], [Plus, G]),
		new Production(G, [E], [Plus, E])
	]);

	// Validate FIRST sets.
	assert(builder.first(P) == [One]);
	assert(builder.first(E) == [One]);
	assert(builder.first(F) == [Plus, epsilon]);
	assert(builder.first(G) == [One, Plus]);
	
	// Validate FOLLOW sets.
	assert(builder.follow(P) == [Plus, eof]);
	assert(builder.follow(E) == [eof]);
	assert(builder.follow(F) == [eof]);
	assert(builder.follow(G) == [eof]);

	// Validate PREDICT sets.
	assert(builder.predict(1) == [One]);
	assert(builder.predict(2) == [One]);
	assert(builder.predict(3) == [eof]);
	assert(builder.predict(4) == [Plus]);
	assert(builder.predict(5) == [One]);
	assert(builder.predict(6) == [Plus]);

	// Validate parse table.
	assert(table[E, One] == 1);
	assert(table[E, Plus] == 0);
	assert(table[E, eof] == 0);

	assert(table[P, One] == 2);
	assert(table[P, Plus] == 0);
	assert(table[P, eof] == 0);

	assert(table[F, One] == 0);
	assert(table[F, Plus] == 4);
	assert(table[F, eof] == 3);

	assert(table[G, One] == 5);
	assert(table[G, Plus] == 6);
	assert(table[G, eof] == 0);
}

/+
 + Grammar 4:
 +
 + E → E + E
 +   | E - E
 +   | P
 +
 + P → 1
 +   | 2
 +
 +/
unittest
{
	/++
	 + Define grammar tokens.
	 ++/
	enum : Token
	{

		// Terminals

		Two = -5,
		One = -4,
		Minus = -3,
		Plus = -2,

		// Non Terminals

		E = 1,
		P = 2,
		F = 3,
		G = 4

	}

	auto builder = new GrammarBuilder("Grammar4");

	builder
		// Terminals
		.addTerminal("One", One)
		.addTerminal("Two", Two)
		.addTerminal("Plus", Plus)
		.addTerminal("Minus", Minus)

		// Nonterminals
		.addNonTerminal("E", E)
		.addNonTerminal("P", P)

		// Productions
		.addRule(E, [E, Plus, E])
		.addRule(E, [E, Minus, E])
		.addRule(E, [P])
		.addRule(P, [One])
		.addRule(P, [Two]);

	// Validate token sets.
	assert(builder.terminals[] == [Two, One, Minus, Plus]);
	assert(builder.nonterminals[] == [E, P]);

	// Validate rules and ordering.
	assert(builder.productions[] == [
		new Production(E, [E, Plus, E], [E, Minus, E], [P]),
		new Production(P, [One], [Two])
	]);

	auto table = builder.buildParseTable;

	// Validate rules and ordering.
	assert(builder.productions[] == [
		new Production(E, [P, F]),
		new Production(P, [One], [Two]),
		new Production(F, [Plus, E], [Minus, E], [epsilon])
	]);

	// TODO
}

/+
 + CTFE Test,
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

	/++
	 + CTFE helper function.
	 ++/
	bool testBuilder()
	{
		auto builder = new GrammarBuilder("Grammar2");

		builder
			// Terminals
			.addTerminal("One", One)
			.addTerminal("Plus", Plus)

			// Nonterminals
			.addNonTerminal("E", E)
			.addNonTerminal("P", P)

			// Productions
			.addRule(E, [E, Plus, E])
			.addRule(E, [P])
			.addRule(P, [One]);

		// Validate token sets.
		assert(builder.terminals[] == [One, Plus]);
		assert(builder.nonterminals[] == [E, P]);

		// Validate rules and ordering.
		assert(builder.productions == [
			new Production(E, [E, Plus, E], [P]),
			new Production(P, [One])
		]);
	
		auto table = builder.buildParseTable;

		// Validate rules and ordering.
		assert(builder.productions == [
			new Production(E, [P, F]),
			new Production(P, [One]),
			new Production(F, [Plus, E], [epsilon])
		]);

		// Validate FIRST sets.
		assert(builder.first(P) == [One]);
		assert(builder.first(E) == [One]);
		assert(builder.first(F) == [Plus, epsilon]);

		// Validate FOLLOW sets.
		assert(builder.follow(P) == [Plus, eof]);
		assert(builder.follow(E) == [eof]);
		assert(builder.follow(F) == [eof]);

		// Validate PREDICT sets.
		assert(builder.predict(1) == [One]);
		assert(builder.predict(2) == [One]);
		assert(builder.predict(3) == [Plus]);
		assert(builder.predict(4) == [eof]);

		// Validate parse table.
		assert(table[E, One] == 1);
		assert(table[E, Plus] == 0);
		assert(table[E, eof] == 0);

		assert(table[P, One] == 2);
		assert(table[P, Plus] == 0);
		assert(table[P, eof] == 0);

		assert(table[F, One] == 0);
		assert(table[F, Plus] == 3);
		assert(table[F, eof] == 4);

		return true;
	}

	// Compile time test.
	static assert(testBuilder);
}
