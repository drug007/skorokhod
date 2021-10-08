module skorokhod.skorokhod;

template Skorokhod(Reference, bool NoDebug = true)
{
	import auxil.treepath : TreePath;
	import skorokhod.model;

	// Children are enumerated from 1
	private struct ChildRange
	{
		size_t begin, end;

		@disable this();

		this(size_t b, size_t count)
		{
			assert(!count || b < count);
			begin = b+1;
			end = count;
		}

		bool empty() const
		{
			return begin > end;
		}

		bool nextEmpty() const
		{
			return begin+1 > end;
		}

		size_t front() const
		{
			return begin-1;
		}

		void popFront()
		{
			assert(!empty);
			begin++;
		}
	}

	private struct Record
	{
		ChildRange children;
		Reference reference;
	}

	private struct Element
	{
		Reference reference;
		TreePath path;

		auto nestingLevel() const
		{
			return path.value.length+1;
		}

		alias reference this;

		auto toHash() const
		{
			return typeid(this).getHash(&this);
		}
	}

	// allows to iterate over T members (or their subset
	// defined by Desc description)
	// only compile-time filtering is available
	// run-time one should be implemented by other ways
	struct RangeOver
	{
		import std.exception : enforce;
		import std.array : popBack;

		@safe:

		Record[] stack;
		TreePath path;
		// true if we have reached 
		// the last element of the tree
		bool _inLastElement;

		@disable this();
		@disable this(this);

		this(Reference reference)
		{
			set(reference);
		}

		void set(Reference reference)
		{
			stack = null;
			path = TreePath();

			stack ~= Record(ChildRange(0, childrenCount(reference)), reference);
			path.put(0);
		}

		private void push()
		{
			auto i = cast(int) top.children.front;
			auto child = cbi(front, i);
			stack ~= Record(ChildRange(0, childrenCount(child)), child);
			if (path.value.length < stack.length)
				path.put(i);
			else
				path.value[stack.length-1] = i;
		}

		private void pop()
		{
			enforce(!empty);
			stack.popBack;
		}

		private bool inProgress() const
		{
			enforce(!empty);
			return !top.children.empty;
		}

		private void nextSibling()
		{
			// go to the next sibling
			top.children.popFront;

			// counter of parents whose have visited all their children
			size_t cnt = 0;
			// true if all parents of the current node
			// have visited all their children
			// i.e. the tree has been fully traversed
			bool fullyTraversed;

			scope(success)
			{
				// on successful exit we fix the current
				// length of the path (remove excess elements)
				if (!fullyTraversed)
				{
					while(path.value.length > stack.length)
						path.popBack;
				}
			}

			if (top.children.empty)
			{
				// if the current list is the last list of its parent
				// then we count total number of other grand parents
				cnt++;
				while(cnt < stack.length && stack[$-cnt-1].children.nextEmpty)
				{
					cnt++;
				}

				// if the current list is the last one of all grand parents
				// set the flag
				if (cnt == stack.length)
					fullyTraversed = true;
			}

			// if there is no next subling
			while(top.children.empty)
			{
				// try to level up to the parent
				pop;
				// get out of here if there is no any parent
				if (empty)
					return;
				// go to the next sibling
				top.children.popFront;
			}

			assert(!empty);

			// if there is available sibling
			// make it the current node
			if (!top.children.empty)
				push;
		}

		private ref auto top() inout
		{
			return stack[$-1];
		}

		size_t nestingLevel() const
		{
			return stack.length;
		}

		// skip the current level and levels below the current
		void skip()
		{
			assert(!empty);
			if (stack.length < 2)
			{
				stack = null;
				return;
			}

			pop;
			if (!empty)
				nextSibling;
		}

		// InputRange interface

		bool empty() const
		{
			return _inLastElement || stack.length == 0;
		}

		auto front()
		{
			enforce(!empty);

			static if (NoDebug)
				return stack[$-1].reference;
			else
				return Element(stack[$-1].reference, path);
		}

		void popFront() @trusted
		{
			assert(!_inLastElement);

			if(isParent(front) && inProgress)
			{
				push;
				return;
			}

			pop;
			if (!empty)
				nextSibling;
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

mixin template skorokhodHelperRT(T, bool NoDebug = true)
{
	import taggedalgebraic : TaggedAlgebraic;

	alias Reference = T;
	alias RT        = Skorokhod!(Reference, NoDebug);
	alias rangeOver = RT.rangeOver;
	alias isParent  = RT.isParent;
	alias childrenCount = RT.childrenCount;
}

auto skipper(R)(ref R r)
{
	return Skipper!R(r);
}

auto skipper(M, S)(ref M m, ref S s)
{
	return Skipper!(M, S)(m, s);
}

/// the range skipping the current level if
/// the current var has collapsed equal to true
struct Skipper(Master, S...)
	if (S.length < 2)
{
	private Master* m;
	static if (S.length == 1)
	{
		alias Slave = S[0];
		private Slave*  s;
		public alias Payload = typeof(front());
	}

	static if (S.length == 1)
	{
		this(ref Master m, ref Slave s)
		{
			this.m = &m;
			this.s = &s;
		}
	}
	else
	{
		this(ref Master m)
		{
			this.m = &m;
		}
	}

	bool empty() const
	{
		static if (S.length == 1)
			assert(m.empty == s.empty);
		return m.empty;
	}

	auto front()
	{
		assert(!empty);
		static if (S.length == 1)
		{
			import std.typecons : tuple;
			return tuple(m.front, s.front);
		}
		else
			return m.front;
	}

	void popFront()
	{
		if (m.front.collapsed)
		{
			m.skip;
			static if (S.length == 1)
				s.skip;
		}
		else
		{
			m.popFront;
			static if (S.length == 1)
				s.popFront;
		}
	}

	auto nestingLevel()
	{
		return m.nestingLevel;
	}
}