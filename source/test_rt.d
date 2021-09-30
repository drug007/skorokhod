module test_rt;

/************************************
	Test for run time features
************************************/

import skorokhod.description;
	
Type Float, Ubyte, String, Int, Double, Short;
AggregateType OneT, TwoT, ThreeT;
AggregateVar threeDesc;

Node[] etalon;

static this()
{
	Short  = new Type("short");
	Float  = new Type("float");
	Ubyte  = new Type("ubyte");
	String = new Type("string");
	Int    = new Type("int");
	Double = new Type("double");

	OneT = new AggregateType("OneT", [
		new ScalarVar("str", String), 
		new ScalarVar("i", Int),
	]);

	TwoT = new AggregateType("TwoT", [
		new ScalarVar("f", Float),
		new AggregateVar("one", OneT),
		new ScalarVar("str", String),
		new ScalarVar("d", Double),
	]);

	ThreeT = new AggregateType("Three", [
		new ScalarVar("sh", Short), 
		new ArrayVar("ub",  new StaticArray(Ubyte, 2)), 
		new ArrayVar("one", new StaticArray(OneT, 3)), 
		new ArrayVar("two", new DynamicArray(TwoT, 1)),
	]);
	threeDesc = new AggregateVar("three", ThreeT);

	etalon = [
		new ScalarVar("three", 
			new AggregateType("Three", [
				new ScalarVar("sh", Short), 
				new ArrayVar("ub",  new StaticArray(Ubyte, 2)), 
				new ArrayVar("one", new StaticArray(OneT, 3)), 
				new ArrayVar("two", new DynamicArray(TwoT, 1)),
			])
		),
		new ScalarVar("sh", Short),
		new ArrayVar("ub", new StaticArray(Ubyte, 2)),
		new ScalarVar("", Ubyte),
		new ScalarVar("", Ubyte),
		new ArrayVar("one", new StaticArray(OneT, 3)),
		new ScalarVar("", OneT),
		new ScalarVar("str", String),
		new ScalarVar("i", Int),
		new ScalarVar("", OneT),
		new ScalarVar("str", String),
		new ScalarVar("i", Int),
		new ScalarVar("", OneT),
		new ScalarVar("str", String),
		new ScalarVar("i", Int),
		new ArrayVar("two", new DynamicArray(TwoT, 1)),
		new ScalarVar("", TwoT),
		new ScalarVar("f", Float), 
		new ScalarVar("one", OneT),
		new ScalarVar("str", String),
		new ScalarVar("i", Int),
		new ScalarVar("str", String),
		new ScalarVar("d", Double),
	];
}

@("Description")
unittest
{
	import skorokhod.skorokhod;
	mixin skorokhodHelperRT!Node;

	auto r = rangeOver(threeDesc);
	version(none) print(r);
	assert(r.equal(etalon));
}

@("skip")
unittest
{
	import skorokhod.skorokhod;
	mixin skorokhodHelperRT!Var;

	// set properties of the description
	threeDesc.field("one").as!ArrayVar.collapsed = true;
	threeDesc.field("two").as!ArrayVar.elements[0].as!AggregateVar.field("one").as!AggregateVar.collapsed = true;
	auto r = rangeOver(threeDesc);

	// traverse the description
	{
		import std : writeln, repeat;
		import std.range : front, popFront, empty;
		while(!r.empty)
		{
			auto prefix = ' '.repeat(2*(r.nestingLevel-1));
			auto sn = r.front.name;
			if (sn == "")
				sn = r.front.type.name;
			writeln(prefix, sn);

			if (r.front.collapsed)
			{
				r.skip;
				continue;
			}
			
			r.popFront;
		}
	}
}

bool collapsed(Var var)
{
	if (auto at = cast(AggregateVar) var)
		return at.collapsed;
	else if (auto a = cast(ArrayVar) var)
		return a.collapsed;
	return false;
}

auto print(R)(R r)
{
	import std : writeln, repeat;
	import std.range : front, popFront, empty;

	while(!r.empty)
	{
		auto prefix = ' '.repeat(2*(r.nestingLevel-1));
		auto sn = r.front.name;
		if (sn == "")
			sn = r.front.type.name;
		writeln(prefix, sn);
		r.popFront;
	}
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
			stderr.writeln(i, ": ", sample.front.name, "\n", i, ": ", etalon.front.name);
			return false;
		}
		sample.popFront;
		etalon.popFront;
	}

	return true;
}