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

	if (sample.walkLength != etalon.walkLength)
	{
		stderr.writeln("sample length: ", sample.walkLength, "\n", "etalon length: ", etalon.walkLength);
		return false;
	}

	foreach(i; 0..etalon.length)
	{
		if (sample.front != etalon[0])
		{
			stderr.writeln(i, ": ", sample.front, "\n", i, ": ", etalon.front);
			return false;
		}
		sample.popFront;
		etalon.popFront;
	}

	return true;
}
