module test_common;

auto toString(E)(E e)
{
	import std : text, repeat, max;
	enum minWidth = 16;
	auto prefix = ' '.repeat(max(minWidth, 2*(e.nestingLevel-1)));
	auto sn = e.name.length ? e.name : e.type.name;
	return text(e.path.value[], prefix, sn);
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
