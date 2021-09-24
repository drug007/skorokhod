module skorokhod.test1;

import std.algorithm : map;
import std.stdio;

import skorokhod.skorokhod;

struct One
{
	string str = "str";
	int i;
}

struct Two
{
	float f;
	One one;
	string str;
	double d;
}

struct Three
{
	short sh;
	ubyte[2] ub2;
	One[3] one;
	Two[] two;
}

bool equal(S, E)(S sample, E etalon)
{
	import std.range : front, popFront, empty;
	foreach(i; 0..etalon.length)
	{
		import std.conv : text;
		assert(sample.front == etalon[0], text(i, ": ", *sample.front, "\n", i, ": ", *etalon.front));
		sample.popFront;
		etalon.popFront;
	}
	assert(sample.empty);
	assert(etalon.empty);

	return true;
}

@("mbi-One")
unittest
{
	One one;
	one.i = 100;

	mixin skorokhodHelper!(One);

	assert(*mbi(one, 0) == "str");
	assert( mbi(one, 0) == &one.str);

	assert(*mbi(one, 1) == 100);
	assert( mbi(one, 1) == &one.i);
}

@("mbi-Three")
unittest
{
	auto three = Three(
		1, 
		[2, 3], 
		[ One("str1", 1), One("str2", 2), One("str3", 3), ],
		[]
	);

	mixin skorokhodHelper!(Three);

	assert(*mbi(three, 0) == 1);
	assert( mbi(three, 0) == &three.sh);

	import std.array : staticArray;
	assert(*mbi(three, 1) == [ubyte(2), ubyte(3)].staticArray);
	assert( mbi(three, 1) == &three.ub2);

	assert(*mbi(three, 2) == [ One("str1", 1), One("str2", 2), One("str3", 3), ].staticArray);
	assert( mbi(three, 2) == &three.one);

	assert(*mbi(three, 3) == [Two()].init);
	assert( mbi(three, 3) == &three.two);
}

@("Model")
unittest
{
	import skorokhod.model;

	One one;
	Two two;
	Three three;

	static assert(is(typeof(model(one))));
	static assert(is(typeof(model(two))));
	static assert(is(typeof(model(three))));
}

@("One")
version(none) unittest
{
	mixin skorokhodHelper!(One);

	One one;
	auto r = rangeOver(one);
	version(none)
	{
		import std;
		r.save.map!"*a".each!writeln;
		writeln("===");
	}

	auto etalon = [Reference(&one)];
	assert(r.equal(etalon));
}

@("Three0")
unittest
{
	mixin skorokhodHelper!(Three);

	auto three = Three(0, [1, 2], [One("str3", 4), One("str5", 6), One("str7", 8)]);
	auto r = rangeOver(three);
	version(none) 
	{
		import std;
		r.save.map!"*a".each!writeln;
		writeln("===");
	}

	auto etalon = [
		Reference(&three),
		Reference(&three.sh),
		Reference(&three.ub2),
		Reference(&three.ub2[0]),
		Reference(&three.ub2[1]),
		Reference(&three.one),
		Reference(&three.one[0]),
		Reference(&three.one[0].str),
		Reference(&three.one[0].i),
		Reference(&three.one[1]),
		Reference(&three.one[1].str),
		Reference(&three.one[1].i),
		Reference(&three.one[2]),
		Reference(&three.one[2].str),
		Reference(&three.one[2].i),
		Reference(&three.two)
	];

	r.equal(etalon);
}

@("isParent")
unittest
{
	mixin skorokhodHelper!(Three);

	Three three;
	auto r = rangeOver(three);

	assert( isParent(r.front)); r.popFront; // three
	assert(!isParent(r.front)); r.popFront; // three.sh
	assert( isParent(r.front)); r.popFront; // three.ub2
	assert(!isParent(r.front)); r.popFront; // three.ub2[0]
	assert(!isParent(r.front)); r.popFront; // three.ub2[1]
	assert( isParent(r.front)); r.popFront; // three.one
	assert( isParent(r.front)); r.popFront; // three.one[0]
	assert(!isParent(r.front)); r.popFront; // three.one[0].str
	assert(!isParent(r.front)); r.popFront; // three.one[0].i
	assert( isParent(r.front)); r.popFront; // three.one[1]
	assert(!isParent(r.front)); r.popFront; // three.one[1].str
	assert(!isParent(r.front)); r.popFront; // three.one[1].i
	assert( isParent(r.front)); r.popFront; // three.one[2]
	assert(!isParent(r.front)); r.popFront; // three.one[2].str
	assert(!isParent(r.front)); r.popFront; // three.one[2].i
	assert( isParent(r.front)); r.popFront; // three.two
}

@("childrenCount")
unittest
{
	mixin skorokhodHelper!(Three);

	Three three;
	auto r = rangeOver(three);

	assert(childrenCount(r.front) == 4); r.popFront; // three
	assert(childrenCount(r.front) == 0); r.popFront; // three.sh
	assert(childrenCount(r.front) == 2); r.popFront; // three.ub2
	assert(childrenCount(r.front) == 0); r.popFront; // three.ub2[0]
	assert(childrenCount(r.front) == 0); r.popFront; // three.ub2[1]
	assert(childrenCount(r.front) == 3); r.popFront; // three.one
	assert(childrenCount(r.front) == 2); r.popFront; // three.one[0]
	assert(childrenCount(r.front) == 0); r.popFront; // three.one[0].str
	assert(childrenCount(r.front) == 0); r.popFront; // three.one[0].i
	assert(childrenCount(r.front) == 2); r.popFront; // three.one[1]
	assert(childrenCount(r.front) == 0); r.popFront; // three.one[1].str
	assert(childrenCount(r.front) == 0); r.popFront; // three.one[1].i
	assert(childrenCount(r.front) == 2); r.popFront; // three.one[2]
	assert(childrenCount(r.front) == 0); r.popFront; // three.one[2].str
	assert(childrenCount(r.front) == 0); r.popFront; // three.one[2].i
	assert(childrenCount(r.front) == 0); r.popFront; // three.two
}

// In this test one field of target data structure is skipped
// using describing data structure
@("Two, skipping a field")
unittest
{
	/// Describing data structure
	/// contains fields that should be
	/// processed in target data structure
	struct DescList
	{
		bool f;
		bool one;
		bool str;
		version(none) bool d; // disable the field
	}

	mixin skorokhodHelper!(Three, DescList);

	auto two = Two(1., One(), "str", 3.);
	auto r = rangeOver(two);
	version(none) 
	{
		import std;
		r.save.map!"*a".each!writeln;
		writeln("===");
	}

	auto etalon = [
		Reference(&two), 
		Reference(&two.f), 
		Reference(&two.one), 
		Reference(&two.one.str), 
		Reference(&two.one.i), 
		Reference(&two.str),
		// Reference(&two.d), - disabled
	];

	assert(r.equal(etalon));
}

@("Two, using Model as description")
unittest
{
	import skorokhod.model;

	mixin skorokhodHelper!(Three, Model!Two);

	auto two = Two(1., One(), "str", 3.);
	auto r = rangeOver(two);
	version(none) 
	{
		import std;
		r.save.map!"*a".each!writeln;
		writeln("===");
	}

	auto etalon = [
		Reference(&two.f), 
		Reference(&two.one), 
		Reference(&two.str),
		Reference(&two.d),
	];

	assert(r.equal(etalon));
}

@("parents")
unittest
{
	mixin skorokhodHelper!(Three);

	import std.meta : AliasSeq;
	static assert(is(ParentTypes!Three == AliasSeq!(ubyte[2], One[3], Two[])));
}
