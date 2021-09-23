module skorokhod.test1;

import std.algorithm : map, equal;
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

@("mbi-One")
unittest
{
	One one;
	one.i = 100;

	mixin skorokhodHelper!(One);

	assert(*mbi(one, 0) == "str");
	assert( tbi(one, 0) == "string*");
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
	assert( tbi(three, 0) == "short*");
	assert( mbi(three, 0) == &three.sh);

	import std.array : staticArray;
	assert(*mbi(three, 1) == [ubyte(2), ubyte(3)].staticArray);
	assert( mbi(three, 1) == &three.ub2);

	assert(*mbi(three, 2) == [ One("str1", 1), One("str2", 2), One("str3", 3), ].staticArray);
	assert( tbi(three, 2) == "One[3]*");
	assert( mbi(three, 2) == &three.one);

	assert(*mbi(three, 3) == [Two()].init);
	assert( tbi(three, 3) == "Two[]*");
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
		auto r1 = r;
		while(!r1.empty)
		{
			writeln(*r1.front);
			r1.popFront;
		}
		writeln("===");
	}

	auto etalon = [Reference(&one)];
	assert(r.equal(etalon));
}

@("Three")
unittest
{
	mixin skorokhodHelper!(Three);

	Three three;
	auto r = rangeOver(three);
	version(none) 
	{
		auto r1 = r;
		while(!r1.empty)
		{
			writeln(*r1.front);
			r1.popFront;
		}
		writeln("===");
	}

	auto etalon = [
		Reference(&three.sh), 
		Reference(&three.ub2), 
		Reference(&three.one), 
		Reference(&three.two)
	];

	assert(r.equal(etalon));
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
		auto r1 = r;
		while(!r1.empty)
		{
			writeln(*r1.front);
			r1.popFront;
		}
		writeln("===");
	}

	auto etalon = [
		Reference(&two.f), 
		Reference(&two.one), 
		Reference(&two.str),
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
		auto r1 = r;
		while(!r1.empty)
		{
			writeln(*r1.front);
			r1.popFront;
		}
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

	static assert(Skor.parentsNumbers!Three[].equal([1, 2, 3]));

	import std.meta : AliasSeq;
	static assert(is(Skor.parentsTypes!Three == AliasSeq!(ubyte[2], One[3], Two[])));
}
