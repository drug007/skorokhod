module skorokhod.model;

import auxil.traits;

alias SizeType = int;

template Model(alias A)
{
	static if (dataHasStaticArrayModel!(TypeOf!A))
		alias Model = StaticArrayModel!A;
	else static if (dataHasRandomAccessRangeModel!(TypeOf!A))
		alias Model = RaRModel!A;
	else static if (dataHasAggregateModel!(TypeOf!A))
		alias Model = AggregateModel!A;
	else
		alias Model = ScalarModel!A;
}

auto model(T)(ref const(T) value)
{
	return Model!T(value);
}

private struct StaticArrayModel(alias A)
{
	enum Collapsable = true;
	enum DynamicCollapsable = false;

	alias Data = TypeOf!A;
	static assert(isProcessible!Data);

	alias ElementType = typeof(Data.init[0]);
	Model!ElementType[Data.length] model;
	alias model this;

	@disable this();

	this(ref const(Data) data)
	{
		static foreach(i; 0..data.length)
			model[i] = Model!ElementType(data[i]);
	}
}

private struct RaRModel(alias A)
{
	import automem : Vector;
	import std.experimental.allocator.mallocator : Mallocator;

	enum Collapsable = true;
	enum DynamicCollapsable = false;

	alias Data = TypeOf!A;
	static assert(isProcessible!Data);

	alias ElementType = typeof(Data.init[0]);
	Vector!(Model!ElementType, Mallocator) model;
	alias model this;

	@disable this();

	this(ref const(Data) data)
	{
		update(data);
	}

	void update(ref const(Data) data)
	{
		model.length = data.length;
		foreach(i, ref e; model)
			e = Model!ElementType(data[i]);
	}

	version(none) void update(T)(ref TaggedAlgebraic!T v)
	{
		update(taget!Data(v));
	}
}

template AggregateModel(alias A)
{
	alias Data = TypeOf!A;
	static assert(isProcessible!Data);

	struct AggregateModel
	{
		enum Collapsable = true;
		enum DynamicCollapsable = false;

		import std.format : format;

		import auxil.traits : DrawableMembers;
		static foreach(member; DrawableMembers!Data)
			mixin("Model!(Data.%1$s) %1$s;".format(member));

		@disable this();

		this(ref const(Data) data)
		{
			foreach(member; DrawableMembers!Data)
			{
				static if (isNullable!(typeof(mixin("data." ~ member))) ||
						isTimemarked!(typeof(mixin("data." ~ member))))
				{
					if (mixin("data." ~ member).isNull)
						continue;
				}
				else
					mixin("this.%1$s = Model!(Data.%1$s)(data.%1$s);".format(member));
			}
		}
	}
}

struct ScalarModel(alias A)
	if (!dataHasAggregateModel!(TypeOf!A) && 
	    !dataHasStaticArrayModel!(TypeOf!A) &&
	    !dataHasRandomAccessRangeModel!(TypeOf!A) &&
	    !dataHasTaggedAlgebraicModel!(TypeOf!A) &&
	    !dataHasAssociativeArrayModel!(TypeOf!A))
{
	enum Spacing = 1;
	SizeType size = 0;

	enum Collapsable = false;
	enum DynamicCollapsable = false;

	alias Data = TypeOf!A;
	static assert(isProcessible!Data);

	@disable this();

	this(ref const(Data) data)
	{
	}
}
