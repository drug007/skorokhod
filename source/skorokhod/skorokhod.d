module skorokhod.skorokhod;

import taggedalgebraic;

template Skorokhod(Types, Desc)
{
	enum Length = Desc.tupleof.length;	
	alias Reference = TaggedAlgebraic!Types;

	struct RangeOver(T)
	{
		@safe:

		private T* _value;
		private Reference _current;
		private size_t _i;

		this(ref T value) @trusted
		{
			_value = &value;
			_current = Reference(_value);
		}

		bool empty() const
		{
			return _i == Length;
		}

		Reference front()
		{
			return _current;
		}

		void popFront()
		{
			assert(!empty);
			_i++;
			if (!empty)
				_current = mbi(*_value, _i);
			else
				_current = Reference();
		}
	}

	auto rangeOver(T)(ref T value)
	{
		return RangeOver!T(value);
	}

	/// mbi - member by index
	/// allows access to aggregate type members
	/// by index. Not all members are available, it
	/// depends on describing type.
	auto mbi(A)(ref A value, size_t idx)
	{
		switch(idx)
		{
			static foreach(k; 0..Length)
				case k:
				{
					// get the name from description
					enum name = __traits(identifier, Desc.tupleof[k]);
					// return the field of the given name
					return Reference(&__traits(getMember, value, name));
				}
			default:
				assert(0);
		}
	}

	/// tbi - return string representation of a member type by index
	auto tbi(A)(ref A value, size_t idx)
	{
		switch(idx)
		{
			static foreach(k; 0..Length)
				case k:
				{
					enum name = __traits(identifier, Desc.tupleof[k]);
					return typeof(&__traits(getMember, value, name)).stringof;
				}
			default:
				assert(0);
		}
	}
}

mixin template skorokhodHelper(T, Desc = T)
{
	alias Skor = Skorokhod!(Types!T, Desc);
	alias rangeOver = Skor.rangeOver;
	alias Reference = Skor.Reference;
	alias mbi       = Skor.mbi;
	alias tbi       = Skor.tbi;

	// Generates a structure, containing all needed types to pass to TaggedAlgebraic
	// that's a workaround that TaggedAlgebraic accepts only aggregate types or enum
	// mixin Types!Three;
	template Types(T)
	{
		import std.traits : Fields, isAggregateType, isArray;
		import std.meta : AliasSeq, staticMap, NoDuplicates;
		import std.conv : text;
		import std.range : ElementType;

		template HelperList(U)
		{
			alias HelperList = AliasSeq!();
			static foreach(ft; Fields!U)
				HelperList = AliasSeq!(HelperList, ft);
		}

		template TypeList(U)
		{
			alias A = AliasSeq!U;
			static foreach(ft; HelperList!U)
			{
				A = AliasSeq!(A, ft);

				static if (isAggregateType!ft)
				{
					A = AliasSeq!(A, TypeList!ft);
				}
				else static if (isArray!ft)
				{
					A = AliasSeq!(A, TypeList!(ElementType!ft));
				}
			}

			alias TypeList = NoDuplicates!A;
		}

		struct Types
		{
			static foreach(i, ft; TypeList!T)
			{
				mixin(ft, "* _", text(i), ";");
			}
		}
	}
}