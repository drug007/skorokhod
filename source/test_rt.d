module test_rt;

/************************************
	Test for run time features
************************************/import skorokhod.description;
	
Type FloatType, UbyteType, StringType, IntType, DoubleType;
AggregateType OneType, TwoType, ThreeType;

Var ShVar, UbVar, StrVar, IntVar, OneVar, TwoVar, threeDesc;
DynamicArray TwoTypeDynArray;

Node[] etalon;

static this()
{
	FloatType  = new Type("float");
	UbyteType  = new Type("ubyte");
	StringType = new Type("string");
	IntType    = new Type("int");
	DoubleType = new Type("double");

	ShVar = new Var("sh", StringType);
	UbVar = new Var("ub", new StaticArray(UbyteType, 2));

	StrVar = new Var("str", StringType);
	IntVar = new Var("i", IntType);
	OneType = new AggregateType("One", [StrVar, IntVar]);
	OneVar = new Var("one", new StaticArray(OneType, 3));

	TwoType = new AggregateType("Two", [
		new Var("f", FloatType), 
		new Var("one", OneType),
		new Var("str", StringType),
		new Var("d", DoubleType),
	]);

	TwoTypeDynArray = new DynamicArray(TwoType, 1);
	TwoVar = new Var("two", TwoTypeDynArray);
	ThreeType = new AggregateType("Three", [ ShVar, UbVar, OneVar, TwoVar]);
	threeDesc = new Var("three", ThreeType);

	etalon = [
		new Var("three", 
			new AggregateType("Three", [ 
				new Var("sh", StringType),                    // shVar
				new Var("ub", new StaticArray(UbyteType, 2)), // UbVar 
				new Var("one", OneType),                      // OneVar
				new Var("two", TwoTypeDynArray),              // TwoVar
			])
		),
		new Var("sh", StringType),
		new Var("ub", new StaticArray(UbyteType, 2)),
		new Type("ubyte"),
		new Type("ubyte"),
		new Var("one", new StaticArray(OneType, 3)),
		OneType,
		new Var("str", StringType),
		new Var("i", IntType),
		OneType,
		new Var("str", StringType),
		new Var("i", IntType),
		OneType,
		new Var("str", StringType),
		new Var("i", IntType),
		new Var("two", new DynamicArray(TwoType, 1)),
		TwoType,
		new Var("f", FloatType), 
		new Var("one", OneType),
		new Var("str", StringType),
		new Var("i", IntType),
		new Var("str", StringType),
		new Var("d", DoubleType),
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

auto print(R)(R r)
{
	import std : writeln, repeat;
	import std.range : front, popFront, empty;

	while(!r.empty)
	{
		auto prefix = ' '.repeat(2*(r.nestingLevel-1));
		writeln(prefix, r.front.name);
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