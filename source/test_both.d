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

	Three three;
	three.two ~= Two();
	auto ctr = rangeOver(three);
	auto rtr = rangeOver(threeDesc);

	// set properties of the description
	// (we can change these properties on the fly)
	threeDesc.field("one").as!ArrayVar.collapsed = true;
	threeDesc.field("two").as!ArrayVar.elements[0].as!AggregateVar.field("one").as!AggregateVar.collapsed = true;

	{
		import std.algorithm : each, map;
		import std.stdio : writeln;
		import std.conv : text;

		skipper(rtr, ctr).map!(t=>text(toString(t[0]), "  ",  *t[1])).each!writeln;
	}
}