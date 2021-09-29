module skorokhod.skorokhod;

template Skorokhod(Reference)
{
	import skorokhod.model;

	private struct Record
	{
		size_t idx, total;
		Reference reference;
	}

	// allows to iterate over T members (or their subset
	// defined by Desc description)
	// only compile-time filtering is available
	// run-time one should be implemented by other ways
	struct RangeOver
	{
		import std.exception : enforce;
		import auxil.treepath : TreePath;

		@safe:

		Record[] stack;
		TreePath path;

		@disable this();
		@disable this(this);
		@disable this(ref return scope const RangeOver rhs);

		this(Reference reference)
		{
			stack ~= Record(0, 1, reference);
			path.put(0);
		}

		this(ref return scope RangeOver rhs)
		{
			stack = rhs.stack.dup;
			path  = rhs.path;
		}

		private void push()
		{
			stack ~= Record(0, childrenCount(front), front);
			path.put(cast(int) idx);
		}

		private void pop()
		{
			enforce(!empty);
			stack = stack[0..$-1];
			path.popBack;
		}

		private auto idx() const
		{
			enforce(!empty);
			return stack[$-1].idx;
		}

		private auto total() const
		{
			enforce(!empty);
			return stack[$-1].total;
		}

		private bool inProgress() const
		{
			enforce(!empty);
			return stack[$-1].idx < stack[$-1].total;
		}

		private void nextChild()
		{
			enforce(inProgress);
			stack[$-1].idx++;
			path.back = cast(int) idx;
		}

		size_t nestingLevel() const
		{
			return stack.length;
		}

		// InputRange interface

		bool empty() const
		{
			return stack.length == 0;
		}

		auto front()
		{
			enforce(!empty);

			if (nestingLevel == 1)
				return stack[$-1].reference;

			assert(isParent(stack[$-1].reference));
			assert(total);
			return cbi(stack[$-1].reference, idx);
		}

		void popFront() @trusted
		{
			// Clear the stack from records where
			// all children has been visited
			scope(exit)
			{
				while(!empty && !inProgress)
					pop;
			}

			if (nestingLevel == 1 || (isParent(front) && total))
			{
				push;
				assert(idx == 0);
				// in grand parent record go to the next child
				// (i.e. go to the next parent) 
				stack[$-2].idx++;
				return;
			}
			assert(!empty);
			nextChild;
		}

		auto save()
		{
			return this;
		}
	}

	auto rangeOver(Reference reference)
	{
		return RangeOver(reference);
	}

	auto rangeOver(T)(ref T value)
		if (__traits(compiles, reference(value)))
	{
		return RangeOver(reference(value));
	}

	static if (CT!Reference)
	{
		import taggedalgebraic : apply;

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
			import taggedalgebraic : apply, get;

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

		enum IsParent(U) = Model!U.Collapsable;

		template ParentTypes(U)
		{
			import std.meta : Filter;
			import std.traits : Fields;

			alias ParentTypes = Filter!(IsParent, Fields!U);
		}

		auto reference(T)(ref T value)
		{
			return Reference(&value);
		}
	}
	else
	{
		import skorokhod.description : AggregateVar, ArrayVar, Var;

		auto childrenCount(Reference reference) @trusted
		{
			assert(cast(Var) reference);

			if (auto aggregate = cast(AggregateVar) reference)
			{
				return aggregate.fields.length;
			}
			else if (auto array = cast(ArrayVar) reference)
			{
				return array.elements.length;
			}
			else
				return 0;
		}

		bool isParent(Reference reference) @trusted
		{
			assert(cast(Var) reference);
			if (auto aggregate = cast(AggregateVar) reference)
			{
				return true;
			}
			else if (auto array = cast(ArrayVar) reference)
			{
				return true;
			}
			return false;
		}

		auto cbi(Reference reference, size_t idx)
		{
			assert(cast(Var) reference);

			if (auto aggregate = cast(AggregateVar) reference)
			{
				return aggregate.fields[idx];
			}
			else if (auto array = cast(ArrayVar) reference)
			{
				return array.elements[idx];
			}
			else
				return null;
		}

		auto reference(Reference reference)
		{
			return reference;
		}
	}

	// Compile Time vs Run Time
	template CT(U)
	{
		import taggedalgebraic : TaggedAlgebraic;
		enum CT = is(Reference == TaggedAlgebraic!Types, Types);
	}
}

mixin template skorokhodHelperCT(T)
{
	import taggedalgebraic : TaggedAlgebraic;

	alias Reference = TaggedAlgebraic!(Types!T);
	alias reference = CT.reference;
	alias CT        = Skorokhod!Reference;
	alias rangeOver = CT.rangeOver;
	alias mbi       = CT.mbi;
	alias isParent  = CT.isParent;
	alias stringOf  = CT.stringOf;
	alias ParentTypes   = CT.ParentTypes;
	alias childrenCount = CT.childrenCount;

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

mixin template skorokhodHelperRT(T)
{
	import taggedalgebraic : TaggedAlgebraic;

	alias Reference = T;
	alias RT        = Skorokhod!Reference;
	alias rangeOver = RT.rangeOver;
	alias isParent  = RT.isParent;
	alias childrenCount = RT.childrenCount;
}