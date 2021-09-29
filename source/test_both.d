module test_both;

/************************************
	Test for both compile time and
	run time features altogether
************************************/

@("both")
unittest
{
	import skorokhod.skorokhod;
	import skorokhod.description;

	import test_ct, test_rt;

	mixin skorokhodHelperRT!Node;
	mixin skorokhodHelperCT!(Three);

	Three three;
	three.two ~= Two();
	auto ctr = rangeOver(three);
	auto rtr = rangeOver(threeDesc);

	{
		import std : writeln, repeat;
		import std.range : front, popFront, empty;

		while(!ctr.empty && !rtr.empty)
		{
			auto prefix = ' '.repeat(2*(rtr.nestingLevel-1));
			writeln(prefix, rtr.front.name, " ", *ctr.front);
			ctr.popFront;
			rtr.popFront;
		}
	}
}