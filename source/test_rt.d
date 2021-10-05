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
		[0, 2],          //  5   one
		[0, 2, 0],       //  6     OneT
		[0, 2, 0, 0],    //  7       str
		[0, 2, 0, 1],    //  8       i
		[0, 2, 1],       //  9     OneT
		[0, 2, 1, 0],    // 10       str
		[0, 2, 1, 1],    // 11       i
		[0, 2, 2],       // 12     OneT
		[0, 2, 2, 0],    // 13       str
		[0, 2, 2, 1],    // 14       i
		[0, 3],          // 15   two
		[0, 3, 0],       // 16     TwoT
		[0, 3, 0, 0],    // 17       f
		[0, 3, 0, 1],    // 18       one
		[0, 3, 0, 1, 0], // 19         str
		[0, 3, 0, 1, 1], // 20         i
		[0, 3, 0, 2],    // 21       str
		[0, 3, 0, 3],    // 22       d
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
