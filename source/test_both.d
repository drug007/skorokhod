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

	import test_ct, test_rt;

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
		import std : writeln, repeat;
		import std.range : front, popFront, empty;

		while(!ctr.empty && !rtr.empty)
		{
			auto prefix = ' '.repeat(2*(rtr.nestingLevel-1));
			writeln(prefix, rtr.front.name, " ", *ctr.front);

			if (rtr.front.collapsed)
			{
				rtr.skip;
				ctr.skip;
				continue;
			}

			ctr.popFront;
			rtr.popFront;
		}
	}
}