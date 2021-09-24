module skorokhod.skorokhod;

import taggedalgebraic;

template Skorokhod(Types)
{
	import skorokhod.model;

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

		@disable this();

		this(size_t total, Reference reference)
		{
			stack ~= Record(0, total, reference);
			path.put(0);
		}

		void push()
		{
			stack ~= Record(0, childrenCount(current), current);
			path.put(cast(int) idx);
		}

		void pop()
		{
			enforce(!empty);
			stack = stack[0..$-1];
			path.popBack;
		}

		auto current()
		{
			enforce(!empty);

			if (nestingLevel == 1)
				return stack[$-1].reference;

			assert(isParent(stack[$-1].reference));
			assert(total);
			return cbi(stack[$-1].reference, idx);
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

		void nextChild()
		{
			enforce(inProgress);
			stack[$-1].idx++;
			path.back = cast(int) idx;
		}

		size_t nestingLevel() const
		{
			return stack.length;
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
		private StateStack _stack;

		this(ref T value) @trusted
		{
			_value = &value;
			_stack = StateStack(1, Reference(_value));
		}

		bool empty() const
		{
			return _stack.empty;
		}

		Reference front()
		{
			return _stack.current;
		}

		void popFront() @trusted
		{
			// Clear the stack from records where
			// all children has been visited
			scope(exit)
			{
				while(!_stack.empty && !_stack.inProgress)
					_stack.pop;
			}

			if (_stack.nestingLevel == 1 || (isParent(_stack.current) && _stack.total))
			{
				_stack.push;
				assert(_stack.idx == 0);
				// in grand parent record go to the next child
				// (i.e. go to the next parent) 
				_stack.stack[$-2].idx++;
				return;
			}
			assert(!empty);
			_stack.nextChild;
		}

		auto save()
		{
			return this;
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
	auto mbi(A, D = A)(ref A value, size_t idx)
	{
		import std.traits : isAggregateType, isArray;

		static if (isAggregateType!A)
		{
			switch(idx)
			{
				static foreach(k; 0..D.tupleof.length)
					case k:
					{
						// get the name from description
						enum name = __traits(identifier, D.tupleof[k]);
						// return the field of the given name
						return Reference(&__traits(getMember, value, name));
					}
				default:
					assert(0);
			}
		}
		else static if (isArray!A)
			return Reference(&value[idx]);
		else
			static assert(0);
	}

	auto cbi(Reference reference, size_t idx)
	{
		import std.exception : enforce;
		import std.traits : isArray;

		enforce(isParent(reference));
		return reference.apply!((ref v) {
			alias V = typeof(*v);
			static if (IsParent!V)
				return mbi!V(*reference.get!(V*), idx);
			else
				return Reference();
		});
	}

	auto childrenCount(Reference reference)
	{
		import std.traits : isArray;

		return reference.apply!((ref v) {
			alias V = typeof(*v);
			static if (IsParent!V)
			{
				static if (isArray!V)
					return v.length;
				else
					return V.tupleof.length;
			}
			else
				return 0;
		});
	}

	auto isParent(Reference reference)
	{
		return reference.apply!((ref v) {
			alias VT = typeof(*v);
			return IsParent!VT;
		});
	}

	string stringOf(Reference reference)
	{
		return reference.apply!((ref v) {
			alias VT = typeof(v);
			return VT.stringof;
		});
	}

	private enum IsParent(U) = Model!U.Collapsable;

	template ParentTypes(U)
	{
		import std.meta : Filter;
		import std.traits : Fields;

		alias ParentTypes = Filter!(IsParent, Fields!U);
	}
}

mixin template skorokhodHelper(T)
{
	alias Skor = Skorokhod!(Types!T);
	alias rangeOver = Skor.rangeOver;
	alias Reference = Skor.Reference;
	alias mbi       = Skor.mbi;
	alias isParent  = Skor.isParent;
	alias stringOf  = Skor.stringOf;
	alias ParentTypes   = Skor.ParentTypes;
	alias childrenCount = Skor.childrenCount;

	// Generates a structure, containing all needed types to pass to TaggedAlgebraic
	// that's a workaround that TaggedAlgebraic accepts only aggregate types or enum
	template Types(T)
	{
		import std.traits : Fields, isAggregateType, isArray, isSomeString;
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
				else static if (isSomeString!ft)
				{
					// do nothing
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