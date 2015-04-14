
module derpi.pattern;

import std.array;
import std.string;

abstract class Pattern
{

	abstract string match(string input);

}

class Empty : Pattern
{

	override string match(string)
	{
		return "";
	}

}

class Wildcard : Pattern
{

	override string match(string input)
	{
		return input.length ? [input[0]] : "";
	}

}

class Primitive : Pattern
{

	private string value;

	this(string value)
	{
		this.value = value;
	}

	override string match(string input)
	{
		return input.startsWith(value) ? value : null;
	}

}

class Bracket : Pattern
{

	private char min;
	private char max;

	this(char min, char max)
	{
		this.min = min;
		this.max = max;
	}

	override string match(string input)
	{
		if(input.length > 0)
		{
			char ch = input[0];
			return ch >= min && ch <= max ? [ch] : null;
		}

		return null;
	}

}

class Sequence : Pattern
{

	private Pattern[] patterns;

	this(Pattern[] patterns...)
	{
		this.patterns = patterns;
	}

	override string match(string input)
	{
		auto buffer = appender!string;

		foreach(pattern; patterns)
		{
			string result = pattern.match(input);

			if(result !is null)
			{
				input = input[result.length .. $];
				buffer ~= result;
			}
			else
			{
				return null;
			}
		}

		return buffer.data;
	}

}

class Selection : Pattern
{

	private Pattern[] patterns;

	this(Pattern[] patterns...)
	{
		this.patterns = patterns;
	}

	override string match(string input)
	{
		foreach(pattern; patterns)
		{
			string result = pattern.match(input);

			if(result !is null)
			{
				return result;
			}
		}

		return null;
	}

}

class Repetition : Pattern
{

	private Pattern pattern;

	this(Pattern pattern)
	{
		this.pattern = pattern;
	}

	override string match(string input)
	{
		auto buffer = appender!string;

		string result = pattern.match(input);

		if(result !is null)
		{
			input = input[result.length .. $];
			buffer ~= result;
		}
		else
		{
			return null;
		}

		while((result = pattern.match(input)) !is null)
		{
			input = input[result.length .. $];
			buffer ~= result;
		}

		return buffer.data;
	}

}

class Complement : Pattern
{

	private Pattern pattern;

	this(Pattern pattern)
	{
		this.pattern = pattern;
	}

	override string match(string input)
	{
		if(pattern.match(input) is null)
		{
			return input.length ? [input[0]] : "";
		}

		return null;
	}

}
