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
		import std.algorithm : each, map;
		import std.stdio : writeln;

		auto s = skipper(rtr, ctr);
		auto toString = (s.Payload t) {
			import std : text, repeat;
			auto prefix = ' '.repeat(2*(s.nestingLevel-1));
			auto m = t[0];
			auto s = t[1];
			auto mtext = m.name == "" ? m.type.name : m.name;
			return text(prefix, mtext, " ", *s);
		};
		s.map!toString.each!writeln;
	}
}