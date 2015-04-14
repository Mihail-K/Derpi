
module derpi.pattern;

import std.array;
import std.string;

abstract class Pattern
{

	abstract bool isNullable();

	abstract string match(string input);

	abstract override bool opEquals(Object o);

}

class Empty : Pattern
{

	override bool isNullable()
	{
		return true;
	}

	override string match(string)
	{
		return "";
	}

	override bool opEquals(Object o)
	{
		return cast(Empty)o !is null;
	}

}

class Wildcard : Pattern
{

	override bool isNullable()
	{
		return true;
	}

	override string match(string input)
	{
		return input.length ? [input[0]] : "";
	}

	override bool opEquals(Object o)
	{
		return cast(Wildcard)o !is null;
	}

}

class Primitive : Pattern
{

	private string value;

	this(string value)
	{
		this.value = value;
	}

	override bool isNullable()
	{
		return false;
	}

	override string match(string input)
	{
		return input.startsWith(value) ? value : null;
	}

	override bool opEquals(Object o)
	{
		auto other = cast(Primitive)o;
		return other ? value == other.value : false;
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

	override bool isNullable()
	{
		return false;
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

	override bool opEquals(Object o)
	{
		auto other = cast(Bracket)o;
		return other ? min == other.min && max == other.max : false;
	}

}

class Sequence : Pattern
{

	private Pattern[] patterns;

	this(Pattern[] patterns...)
	{
		this.patterns = patterns;
	}

	override bool isNullable()
	{
		foreach(pattern; patterns)
		{
			if(!pattern.isNullable)
			{
				return false;
			}
		}

		return true;
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

	override bool opEquals(Object o)
	{
		auto other = cast(Sequence)o;
		return other ? patterns == other.patterns : false;
	}

}

class Selection : Pattern
{

	private Pattern[] patterns;

	this(Pattern[] patterns...)
	{
		this.patterns = patterns;
	}

	override bool isNullable()
	{
		foreach(pattern; patterns)
		{
			if(pattern.isNullable)
			{
				return true;
			}
		}

		return false;
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

	override bool opEquals(Object o)
	{
		auto other = cast(Selection)o;
		return other ? patterns == other.patterns : false;
	}

}

class Repetition : Pattern
{

	private Pattern pattern;

	this(Pattern pattern)
	{
		this.pattern = pattern;
	}

	override bool isNullable()
	{
		return pattern.isNullable;
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

	override bool opEquals(Object o)
	{
		auto other = cast(Repetition)o;
		return other ? pattern == other.pattern : false;
	}

}

class Complement : Pattern
{

	private Pattern pattern;

	this(Pattern pattern)
	{
		this.pattern = pattern;
	}

	override bool isNullable()
	{
		return !pattern.isNullable;
	}

	override string match(string input)
	{
		if(pattern.match(input) is null)
		{
			return input.length ? [input[0]] : "";
		}

		return null;
	}

	override bool opEquals(Object o)
	{
		auto other = cast(Complement)o;
		return other ? pattern == other.pattern : false;
	}

}

class Optional : Pattern
{

	private Pattern pattern;

	this(Pattern pattern)
	{
		this.pattern = pattern;
	}

	override bool isNullable()
	{
		return true;
	}

	override string match(string input)
	{
		string result = pattern.match(input);
		return result ? result : "";
	}

	override bool opEquals(Object o)
	{
		auto other = cast(Optional)o;
		return other ? pattern == other.pattern : false;
	}

}
