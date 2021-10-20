module test_both;

/************************************
	Test for both compile time and
	run time features altogether
************************************/

@("both_skip")
unittest
{
	import skorokhod.skorokhod;
	import skorokhod.description;

	import test_ct, test_rt, test_common;

	mixin skorokhodHelperRT!Var;
	mixin skorokhodHelperCT!(Three);

	auto three = Three(
		1, 
		[2, 3], 
		[One("4", 5), One("6", 7), One("8", 9)],
		[Two(10, One("11", 12), "13", 14)]
	);
	auto ctr = rangeOver(three);
	auto rtr = rangeOver(threeDesc);

	// set properties of the description
	// (we can change these properties on the fly)
	threeDesc.field("one").as!ArrayVar.collapsed = true;
	threeDesc.field("two").as!ArrayVar.elements[0].as!AggregateVar.field("one").as!AggregateVar.collapsed = true;

	{
		import std.algorithm : each, equal, map;
		import std.typecons : tuple;
		import std.stdio : writeln;
		import std.conv : text;

		skipper(rtr, ctr).map!(t=>text(toString(t[0]), "  ",  *t[1])).equal([
			"three  Three(1, [2, 3], [One(\"4\", 5), One(\"6\", 7), One(\"8\", 9)], [Two(10, One(\"11\", 12), \"13\", 14)])",
			"sh  1",
			"ub  [2, 3]",
			"ubyte  2",
			"ubyte  3",
			"one  [One(\"4\", 5), One(\"6\", 7), One(\"8\", 9)]",
			"two  [Two(10, One(\"11\", 12), \"13\", 14)]",
			"TwoT  Two(10, One(\"11\", 12), \"13\", 14)",
			"f  10",
			"one  One(\"11\", 12)",
			"str  13",
			"d  14",
		]);
	}
}