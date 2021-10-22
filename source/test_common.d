module test_common;

auto toString(E)(E e)
{
	import std : text, repeat, max;
	enum minWidth = 16;
	static if (is(typeof(e.nestingLevel)))
		auto prefix = ' '.repeat(max(minWidth, 2*(e.nestingLevel-1)));
	else
		string prefix;
	static if (is(typeof(e.path.value[])))
		auto path = e.path.value[];
	else
		string path;
	auto sn = e.name.length ? e.name : e.type.name;
	return text(path, prefix, sn);
}

auto toPath(E)(E e)
{
	static if (is(typeof(e.path.value)))
		return e.path.value;
	else
		return "";
}

bool equal(S, E)(S sample, E etalon)
{
	import std.range : front, popFront, empty, walkLength;
	import std.stdio : stderr;

	size_t i;
	foreach(_; 0..etalon.length)
	{
		if (sample.empty)
			break;

		if (sample.front != etalon[0])
		{
			stderr.writeln(i, ": ", sample.front[], "\n", i, ": ", etalon.front[]);
			return false;
		}
		sample.popFront;
		etalon.popFront;
		i++;
	}

	if (!sample.empty || !etalon.empty)
	{
		stderr.writefln("Different length: %s (sample) and %s (etalon)", sample.walkLength + i, etalon.walkLength + i);
		return false;
	}

	return true;
}

/// Randomly traverse the given array forming
/// random sequence of its elements
struct RandomWalker
{
	import std.random : Random, uniform, unpredictableSeed;

	private Random _rng;
	private int _step;
	private size_t _epoch, _length, _target, _value;

	invariant
	{
		assert(_target < _length || !_length);
	}

	/// epoch - amount of passes
	/// length - length of the array
	this(size_t epoch, size_t length)
	{
		if (!length)
		{
			_epoch = 0;
			return;
		}
		_epoch = epoch;
		_length = length;
		_step = 1;
		newTarget;
		_rng = Random();
	}

	void makeUnpredictable()
	{
		_rng = Random(unpredictableSeed);
	}

	bool empty() const
	{
		return _epoch == 0;
	}

	auto front() const
	{
		import std.typecons : tuple;

		return tuple(_value, _step);
	}

	void popFront()
	{
		_value += _step;
		if (_target == _value)
		{
			_epoch--;
			if (!empty)
				newTarget;
		}
	}

	private void newTarget()
	{
		assert(_length > 1);
		while(_target == _value)
		{
			if (uniform!"[]"(0, 1, _rng) && _value > 0 || _value == _length - 1)
			{
				_target = uniform!"[)"(0, _value, _rng);
			}
			else
			{
				assert(_value < _length - 1);
				_target = uniform!"[)"(_value, _length, _rng);
			}
		}
		_step = _target > _value ? +1 : -1;
	}
}
