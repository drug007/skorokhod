module skorokhod.description;

@safe:

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
			return _name == o._name;
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

	Children children() { return _children; }

	override bool opEquals(Object other) @trusted
	{
		if (!super.opEquals(other))
			return false;

		if (auto o = cast(typeof(this)) other)
		{
			if (this is o)
				return true;
			// TODO dynamic arrays and pointers will be compared by their own value,
			// not by their payload
			return this.tupleof == o.tupleof;
		}

		return false;
	}

private:
	Children _children;
}

class ScalarType : Type
{
	this(string name)
	{
		super(name);
	}
}

interface Children
{
	Node opIndex(size_t idx);
	size_t length() const;
}

class HomogeneousChildren : Children
{
	this(Type type, size_t length)
	{
		_type = type;
		_length = length;
	}

	Node opIndex(size_t idx)
	{
		assert(idx < length);
		return _type;
	}

	size_t length() const
	{
		return _length;
	}

private:
	Type   _type;
	size_t _length;
}

class HeterogeneousChildren : Children
{
	this(Node[] children)
	{
		_children = children;
	}

	Node opIndex(size_t idx)
	{
		return _children[idx];
	}

	size_t length() const
	{
		return _children.length;
	}

private:
	Node[] _children;
}

class AggregateType : ParentType
{
	this(string name, Var[] children = null)
	{
		import std.algorithm : map;
		import std.array : array;

		super(name);
		_children = new HeterogeneousChildren(children.map!((Node n)=>n).array);
	}
}

private class Array : ParentType
{
	this(Type type, size_t length)
	{
		import std.format : format;

		super(format("%s[%s]", type.name, length));
		_children = new HomogeneousChildren(type, length);
	}

	size_t length() const
	{
		return _children.length;
	}
}

final class StaticArray : Array
{
	this(Type type, size_t length)
	{
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
		if (auto hc = cast(HomogeneousChildren) _children)
			hc._length = length;
		else
			assert(0);
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

private:
	Type   _type;
}
