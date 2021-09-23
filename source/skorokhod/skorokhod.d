module skorokhod.skorokhod;

import taggedalgebraic;

template Skorokhod(Types, Desc)
{
	enum Length = Desc.tupleof.length;	
	alias Reference = TaggedAlgebraic!Types;

	private struct Record
	{
		size_t idx, total;
		Reference reference;
	}

	private struct StateStack
	{
		import std.exception : enforce;
		import auxil.treepath : TreePath;

		@safe:

		Record[] stack;
		TreePath path;

		this(size_t total, Reference reference)
		{
			push(total, reference);
		}

		void push(size_t total, Reference reference)
		{
			stack ~= Record(0, total, reference);
			path.put(cast(int) idx);
		}

		void pop()
		{
			enforce(!empty);
			stack = stack[0..$-1];
			path.popBack;
		}

		auto reference()
		{
			enforce(!empty);
			// return stack[$-1].reference.children(idx);
			stack[$-1].reference.apply!((v) {
				import std.meta : staticIndexOf;
				alias Type = typeof(v);
				static if (staticIndexOf!(ParentTypes!Types, Type) > -1)
					return mbi!Type(stack[$-1].reference.get!Type, _idx);
				else
					return stack[$-1].reference;
			});
		}

		auto idx() const
		{
			enforce(!empty);
			return stack[$-1].idx;
		}

		auto total() const
		{
			enforce(!empty);
			return stack[$-1].total;
		}

		bool empty() const
		{
			return stack.length == 0;
		}

		bool inProgress() const
		{
			enforce(!empty);
			return stack[$-1].idx < stack[$-1].total;
		}

		void nextNode()
		{
			enforce(inProgress);
			stack[$-1].idx++;
			path.back = cast(int) idx;
		}
	}

	// allows to iterate over T members (or their subset
	// defined by Desc description)
	// only compile-time filtering is available
	// run-time one should be implemented by other ways
	struct RangeOver(T)
	{
		@safe:

		private T* _value;
		private Reference _current;
		private size_t _i;
		private StateStack _stack;

		this(ref T value) @trusted
		{
			_value = &value;
			version(none) _current = Reference(_value);
			else _current = mbi(*_value, _i);
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

	template Tbi(T, size_t idx)
	{
		enum name = __traits(identifier, Desc.tupleof[idx]);
		alias Tbi = typeof(__traits(getMember, T, name))*;
	}

	/// tbi - return string representation of a member type by index
	auto tbi(A)(ref A value, size_t idx)
	{
		switch(idx)
		{
			static foreach(k; 0..Length)
				case k:
					return Tbi!(A, k).stringof;
			default:
				assert(0);
		}
	}

	auto isParent(Reference reference)
	{
		return reference.apply!((v) {
			alias VT = typeof(v);
			return IsParent!VT;
		});
	}

	private template IsParent(Pointer)
	{
		import std.traits : PointerTarget;
		import skorokhod.model;

		alias Pointee = PointerTarget!Pointer;

		static if (Model!Pointee.Collapsable)
			enum IsParent = true;
		else
			enum IsParent = false;
	}

	template ParentTypes(U)
	{
		import std.meta : AliasSeq;
		import std.traits : Fields;

		alias S = AliasSeq!();
		static foreach(FT; Fields!U)
			static if (IsParent!FT)
				S = AliasSeq!(S, FT);

		alias ParentTypes = S;
	}

	template parentsTypes(T)
	{
		import std.meta : AliasSeq;
		import std.traits : PointerTarget;
		import skorokhod.model;
		
		alias S = AliasSeq!();
		static foreach(i; 0..Length)
			// Pointer = Tbi!(T, i)
			// Pointee = PointerTarget!Pointer
			// Model   = Model!Pointee
			static if (IsParent!(Tbi!(T, i)))
				S = AliasSeq!(S, PointerTarget!(Tbi!(T, i)));

		alias parentsTypes = S;
	}

	/// returns static array containing order numbers of
	/// T members having children
	/// the numbers are ordered in ascending order
	template parentsNumbers(T)
	{
		import std.meta : AliasSeq;
		import std.traits : PointerTarget;
		import skorokhod.model;

		alias S = AliasSeq!();
		static foreach(i; 0..Length)
			// Pointer = Tbi!(T, i)
			// Pointee = PointerTarget!Pointer
			// Model   = Model!Pointee
			static if (Model!(PointerTarget!(Tbi!(T, i))).Collapsable)
				S = AliasSeq!(S, i);

		auto initialize()
		{
			ubyte[S.length] par;
			static foreach(i; 0..S.length)
				par[i] = S[i];
			return par;
		}

		enum parentsNumbers = initialize();
	}
}

mixin template skorokhodHelper(T, Desc = T)
{
	alias Skor = Skorokhod!(Types!T, Desc);
	alias rangeOver = Skor.rangeOver;
	alias Reference = Skor.Reference;
	alias mbi       = Skor.mbi;
	alias tbi       = Skor.tbi;
	alias isParent  = Skor.isParent;
	alias parentsNumbers = Skor.parentsNumbers;
	alias parentsTypes   = Skor.parentsTypes;

	// Generates a structure, containing all needed types to pass to TaggedAlgebraic
	// that's a workaround that TaggedAlgebraic accepts only aggregate types or enum
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