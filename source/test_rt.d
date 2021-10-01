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

@("rt_skip")
unittest
{
	import skorokhod.skorokhod;
	mixin skorokhodHelperRT!Var;

	// // set properties of the description
	// threeDesc.field("one").as!ArrayVar.collapsed = true;
	// threeDesc.field("two").as!ArrayVar.elements[0].as!AggregateVar.field("one").as!AggregateVar.collapsed = true;
	auto r = rangeOver(threeDesc);

	int[][] path_etalon = [
		[0],          //  0 three
		[0, 0],       //  1   sh
		[0, 1],       //  2   ub
		[0, 1, 0],    //  3     ub[0]
		[0, 1, 1],    //  4     ub[1]
		[0, 2],       //  5   one
		[0, 2, 0],    //  6     OneT
		[0, 2, 0, 0], //  7       str
		[0, 2, 0, 1], //  8       i
		[0, 2, 1],    //  9     OneT
		[0, 2, 1, 0], // 10       str
		[0, 2, 1, 1], // 11       i
		[0, 2, 2],    // 12     OneT
		[0, 2, 2, 0], // 13       str
		[0, 2, 2, 1], // 14       i
		[0, 3],       // 15   two
		[0, 3, 0],    // 16     TwoT
		[0, 3, 0, 0], // 17       f
		[0, 3, 0, 1], // 18       one
		[0, 3, 0, 2], // 19       d
	];

	int[][] path_result;

	// traverse the description
	{
		import std.algorithm : each, map;
		import std.stdio : writeln;
		import std.array : array;

		auto w = skipper(r);
		auto toString = (Var v) {
			import std : text, repeat;
			auto prefix = ' '.repeat(2*(w.nestingLevel-1));
			auto sn = v.name;
			if (sn == "")
				sn = v.type.name;
			path_result ~= r.path.value[].array;
			return text(r.path, prefix, sn);
		};
		w.map!toString.each!writeln;
		r.path.writeln;
		// path_result.each!writeln;
	}

	import std : writeln, lockstep;
	size_t i;
	foreach(lhs, rhs; lockstep(path_etalon, path_result))
	{
		if (lhs != rhs)
		{
			writeln(i, ": expected ", lhs, "\n", i, ":      got ", rhs);
			assert(0);
		}
		i++;
	}
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