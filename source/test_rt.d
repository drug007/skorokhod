module test_rt;

/************************************
	Test for run time features
************************************/

import skorokhod.description;
import test_common;
	
Type Float, Ubyte, String, Int, Double, Short;
AggregateType OneT, TwoT, ThreeT;
AggregateVar threeDesc;

Node[] etalon;

int[][] path_etalon;

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

	path_etalon = [
		[0],             //  0 three
		[0, 0],          //  1   sh
		[0, 1],          //  2   ub
		[0, 1, 0],       //  3     ub[0]
		[0, 1, 1],       //  4     ub[1]
		[0, 1],          //  5   ub
		[0, 2],          //  6   one
		[0, 2, 0],       //  7     OneT
		[0, 2, 0, 0],    //  8       str
		[0, 2, 0, 1],    //  9       i
		[0, 2, 0],       // 10     OneT
		[0, 2, 1],       // 11     OneT
		[0, 2, 1, 0],    // 12       str
		[0, 2, 1, 1],    // 13       i
		[0, 2, 1],       // 14     OneT
		[0, 2, 2],       // 15     OneT
		[0, 2, 2, 0],    // 16       str
		[0, 2, 2, 1],    // 17       i
		[0, 2, 2],       // 18     OneT
		[0, 2],          // 19   one
		[0, 3],          // 20   two
		[0, 3, 0],       // 21     TwoT
		[0, 3, 0, 0],    // 22       f
		[0, 3, 0, 1],    // 23     one
		[0, 3, 0, 1, 0], // 24       str
		[0, 3, 0, 1, 1], // 25       i
		[0, 3, 0, 1],    // 26     one
		[0, 3, 0, 2],    // 27     str
		[0, 3, 0, 3],    // 28     d
		[0, 3, 0],       // 29     TwoT
		[0, 3],          // 30   two
		[0],             // 31 three
	];
}

@("Description")
unittest
{
	import std.algorithm : each, map;
	import std.stdio : writeln;
	import skorokhod.skorokhod;

	mixin skorokhodHelperRT!(Var, false);

	auto r = rangeOver(threeDesc);
	version(none) r.map!toString.each!writeln;
	assert(r.map!toPath.equal(path_etalon));
	r = rangeOver(threeDesc);

	foreach(_; 0..6)
		r.popFront;

	assert(r.front.name == "one");
	assert(r.path.value[] == [0, 2]);

	while(!r.empty)
		r.popFront;

	assert(r.path.value[] == [0]);
	assert(r.empty);
}

@("ForwardAndBack")
unittest
{
	import std.algorithm : each, map;
	import std.stdio : writeln;
	import skorokhod.skorokhod;

	mixin skorokhodHelperRT!(Var, false);

	auto r = rangeOver(threeDesc);

	foreach(_; 0..5)
		r.popFront;

	assert(r.front.name == "one");
	assert(r.front.type.name == "OneT[3]");
	assert(r.path.value[] == [0, 2]);

	r.setBackwardDirection;
	r.popFront;
	assert(r.front.type.name == "ubyte");
	assert(r.path.value[] == [0, 1, 1]);

	r.popFront;
	assert(r.front.type.name == "ubyte");
	assert(r.path.value[] == [0, 1, 0]);

	r.popFront;
	assert(r.front.name == "ub");
	assert(r.front.type.name == "ubyte[2]");
	assert(r.path.value[] == [0, 1]);

	r.setForwardDirection;
	r.popFront;
	assert(r.front.name == "");
	assert(r.front.type.name == "ubyte");
	assert(r.path.value[] == [0, 1, 0]);

	r.setBackwardDirection;
	r.popFront;
	assert(r.front.name == "ub");
	assert(r.front.type.name == "ubyte[2]");
	assert(r.path.value[] == [0, 1]);

	r.setForwardDirection;
	r.popFront;
	assert(r.front.name == "");
	assert(r.front.type.name == "ubyte");
	assert(r.path.value[] == [0, 1, 0]);

	r.popFront;
	assert(r.front.name == "");
	assert(r.front.type.name == "ubyte");
	assert(r.path.value[] == [0, 1, 1]);

	r.popFront;
	assert(r.front.name == "one");
	assert(r.front.type.name == "OneT[3]");
	assert(r.path.value[] == [0, 2]);

	r.popFront;
	assert(r.front.name == "");
	assert(r.front.type.name == "OneT");
	assert(r.path.value[] == [0, 2, 0]);

	r.popFront;
	assert(r.front.name == "str");
	assert(r.front.type.name == "string");
	assert(r.path.value[] == [0, 2, 0, 0]);

	r.popFront;
	assert(r.front.name == "i");
	assert(r.front.type.name == "int");
	assert(r.path.value[] == [0, 2, 0, 1]);

	r.popFront;
	assert(r.front.name == "");
	assert(r.front.type.name == "OneT");
	assert(r.path.value[] == [0, 2, 1]);

	r.setBackwardDirection;
	r.popFront;
	assert(r.front.name == "i");
	assert(r.front.type.name == "int");
	assert(r.path.value[] == [0, 2, 0, 1]);

	r.popFront;
	assert(r.front.name == "str");
	assert(r.front.type.name == "string");
	assert(r.path.value[] == [0, 2, 0, 0]);

	r.popFront;
	assert(r.front.name == "");
	assert(r.front.type.name == "OneT");
	assert(r.path.value[] == [0, 2, 0]);

	r.popFront;
	assert(r.front.name == "one");
	assert(r.front.type.name == "OneT[3]");
	assert(r.path.value[] == [0, 2]);

	r.popFront;
	assert(r.front.name == "");
	assert(r.front.type.name == "ubyte");
	assert(r.path.value[] == [0, 1, 1]);

	r.popFront;
	assert(r.front.name == "");
	assert(r.front.type.name == "ubyte");
	assert(r.path.value[] == [0, 1, 0]);

	r.popFront;
	assert(r.front.name == "ub");
	assert(r.front.type.name == "ubyte[2]");
	assert(r.path.value[] == [0, 1]);

	r.popFront;
	assert(r.front.name == "sh");
	assert(r.front.type.name == "short");
	assert(r.path.value[] == [0, 0]);

	r.popFront;
	assert(r.front.name == "three");
	assert(r.front.type.name == "Three");
	assert(r.path.value[] == [0]);

	r.popFront;
	assert(r.empty);
	assert(r.path.value[] == []);
}

@("Forth&Back")
unittest
{
	import skorokhod.skorokhod;

	mixin skorokhodHelperRT!(Var, false);

	auto r = rangeOver(threeDesc);

	auto rw = RandomWalker(150, 23);
	rw.makeUnpredictable;

	foreach(e; rw)
	{
		assert(r.front.path.value[] == path_etalon[e[0]]);
		if (e[1] == 1)
			r.setForwardDirection;
		else
			r.setBackwardDirection;
		r.popFront;
	}
}

@("rt_skip")
unittest
{
	import std.algorithm : each, map;
	import std.stdio : writeln;
	import skorokhod.skorokhod;

	mixin skorokhodHelperRT!(Var, false);
	
	// set properties of the description
	// (we can change these properties on the fly)
	threeDesc.field("two").as!ArrayVar.collapsed = true;

	auto r = rangeOver(threeDesc);
	version(none) r.skipper.map!toString.each!writeln;
	r = rangeOver(threeDesc);
	assert(r.skipper.map!toPath.equal(path_etalon[0..16]));
}

@("rt_skip_root_children")
unittest
{
	import std.algorithm : each, map;
	import std.stdio : writeln;
	import skorokhod.skorokhod;

	mixin skorokhodHelperRT!(Var, false);
	
	// set properties of the description
	// (we can change these properties on the fly)
	threeDesc.as!AggregateVar.collapsed = true;

	auto r = rangeOver(threeDesc);
	version(none) r.skipper.map!toString.each!writeln;
	r = rangeOver(threeDesc);
	assert(r.skipper.map!toPath.equal(path_etalon[0..1]));
}
