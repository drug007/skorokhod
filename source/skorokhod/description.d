module skorokhod.description;

@safe:

mixin template opEqualsMixin()
{
	override bool opEquals(Object other) @trusted
	{
		if (this is other)
			return true;

		if (!super.opEquals(other))
			return false;

		if (auto o = cast(typeof(this)) other)
		{
			// TODO dynamic arrays and pointers will be compared by their own value,
			// not by their payload
			static foreach(i; 0..this.tupleof.length)
				if (this.tupleof[i] != o.tupleof[i])
					return false;

			return true;
		}

		return false;
	}
}

class Node
{
	this(string name)
	{
		_name = name;
	}

	string name()
	{
		return _name;
	}

	override bool opEquals(Object other)
	{
		if (auto o = cast(typeof(this)) other)
			return this.tupleof == o.tupleof;
		else
			return false;
	}

private:
	string _name;
}

class Type : Node
{
	this(string name)
	{
		super(name);
	}
}

class ParentType : Type
{
	this(string name)
	{
		super(name);
	}

	mixin opEqualsMixin;

private:
	bool _collapsed;
}

class ScalarType : Type
{
	this(string name)
	{
		super(name);
	}
}

class AggregateType : ParentType
{
	this(string name, Var[] fields)
	{
		super(name);
		_fields = fields;
	}

	auto fields()
	{
		return _fields;
	}

private:
	Var[] _fields;
}

private class Array : ParentType
{
	this(Type type, size_t length)
	{
		import std.format : format;

		assert(type);
		super(format("%s[%s]", type.name, length));
		_type   = type;
		_length = length;
	}

	size_t length() const
	{
		return _length;
	}

	Type type()
	{
		return _type;
	}

private:
	Type   _type;
	size_t _length;
}

final class StaticArray : Array
{
	this(Type type, size_t length)
	{
		assert(type);
		super(type, length);
	}
}

final class DynamicArray : Array
{
	this(Type type, size_t length)
	{
		super(type, length);
	}

	void length(size_t length)
	{
		_length = length;
	}
}

class Var : Node
{
	this(string name, Type type)
	{
		super(name);
		_type = type;
	}

	Type type()
	{
		return _type;
	}

	abstract Var clone();

	auto as(T)()
	{
		return cast(T) this;
	}

private:
	Type _type;
}

class ScalarVar : Var
{
	this(string name, Type type)
	{
		super(name, type);
	}

	override ScalarVar clone()
	{
		return new ScalarVar(name, type);
	}
}

class AggregateVar : Var
{
	this(string name, AggregateType type)
	{
		super(name, type);
		foreach(e; type.fields)
			_fields ~= e.clone;
	}

	auto fields()
	{
		return _fields;
	}

	override AggregateVar clone()
	{
		return new AggregateVar(name, cast(AggregateType) type);
	}

	Var field(string field)
	{
		foreach(f; fields)
			if (f.name == field)
				return f;
		
		return null;
	}

	bool collapsed()
	{
		if (auto parent = cast(ParentType) type)
			return _collapsed;
		else
			return false;
	}

	void collapsed(bool value)
	{  
		if (auto parent = cast(ParentType) type)
			_collapsed = value;
	}

private:
	Var[] _fields;
	bool _collapsed;
}

class ArrayVar : Var
{
	this(string name, Array type)
	{
		super(name, type);
		foreach(_; 0..type.length)
			_elements ~= var("", type.type);
	}

	auto elements()
	{
		return _elements;
	}

	override ArrayVar clone()
	{
		return new ArrayVar(name, cast(Array) type);
	}

	bool collapsed()
	{
		if (auto parent = cast(ParentType) type)
			return _collapsed;
		else
			return false;
	}

	void collapsed(bool value)
	{  
		if (auto parent = cast(ParentType) type)
			_collapsed = value;
	}

private:
	Var[] _elements;
	bool _collapsed;
}

Var var(string name, Type type)
{
	if (auto at = cast(AggregateType) type)
		return new AggregateVar(name, at);
	if (auto a = cast(Array) type)
		return new ArrayVar(name, a);
	return new ScalarVar(name, type);
}
