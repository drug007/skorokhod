module skorokhod.skorokhod;

template Skorokhod(Reference, bool NoDebug = true)
{
	import auxil.treepath : TreePath;
	import skorokhod.model;

	enum Direction { forward = 1, backward = -1 }

	private struct ChildRange
	{
		size_t begin, end;
		Direction direction;

		@disable this();

		this(Direction d, size_t count, bool inverseDirection)
		{
			direction = d;
			if (!count)
			{
				begin = 1;
				end = 0;
				return;
			}
			// the first index in case of forward direction and
			// the last one in other case
			begin = (direction == Direction.forward) ? 1 : count;
			// if end equals to zero it means that the node is a leaf one
			end = count;
			// inverse front and back if needed
			if (inverseDirection)
				begin = (begin == 1) ? end : 1;
		}

		// calculate new direction considering the current one and
		// necessity of its inversion
		auto calcDirection(bool inverseDirection) const
		{
			if (inverseDirection)
				return (direction == Direction.forward) ? Direction.backward : Direction.forward;
			return direction;
		}

		bool checkEmtpiness(size_t value, bool inverseDirection = false) const
		{
			// leaf node is always empty
			if (!end)
				return true;
			// our interval is [1, end]
			Direction d = calcDirection(inverseDirection);
			final switch(d)
			{
				case Direction.forward:
					return value > end;
				case Direction.backward:
					return value < 1;
			}
		}

		void skip(bool inverseDirection = false)
		{
			// our interval is [1, end]
			Direction d = calcDirection(inverseDirection);
			final switch(d)
			{
				case Direction.forward:
					begin = end + 1;
				break;
				case Direction.backward:
					begin = 0;
				break;
			}
		}

		bool nextEmpty(bool inverseDirection = false) const
		{
			return checkEmtpiness(begin + direction, inverseDirection);
		}

		bool empty(bool inverseDirection = false) const
		{
			return checkEmtpiness(begin, inverseDirection);
		}

		size_t front(bool inverseDirection)
		{
			if (begin == 0)
			{
				if (!end)
					return 1;
				begin = calcDirection(inverseDirection) == Direction.forward ?  1 : end;
			}
			assert(begin > 0 && (!end || begin <= end));
			return begin-1;
		}

		void next(bool inverseDirection = false)
		{
			assert(!empty(inverseDirection));
			begin += calcDirection(inverseDirection);
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
		bool inverseDirection;

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

			stack ~= Record(ChildRange(direction(reference), childrenCount(reference), inverseDirection), reference);
			path.put(0);
		}

		private void push()
		{
			auto curr_child_idx = cast(int) top.children.front(inverseDirection);
			auto child = cbi(front, curr_child_idx);
			stack ~= Record(ChildRange(direction(child), childrenCount(child), inverseDirection), child);

			// process path
			if (path.value.length < stack.length)
				path.put(curr_child_idx);
			else
				path.value[stack.length-1] = curr_child_idx;
		}

		private void pop()
		{
			enforce(!empty);
			if (stack.length > 1)
				stack[$-2].children.direction = stack[$-1].children.direction;
			stack.popBack;
		}

		private ref auto top() inout
		{
			return stack[$-1];
		}

		size_t nestingLevel() const
		{
			return stack.length;
		}

		void setForwardDirection()
		{
			inverseDirection = false;
		}

		void setBackwardDirection()
		{
			inverseDirection = true;
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

			top.children.skip;
			popFront;
		}

		// InputRange interface

		bool empty() const
		{
			return stack.length == 0;
		}

		auto front()
		{
			enforce(!empty);

			static if (NoDebug)
				return stack[$-1].reference;
			else
				return Element(stack[$-1].reference, path);
		}

		void popFront()
		{
			if (inverseDirection)
				popFrontBackward;
			else
				popFrontForward;
				
		}

		private enum TraversalState { descent, ascent, next, }
		private TraversalState _traversal_state;
		private bool _returnFlag;

		auto returnFlag() const { return _returnFlag; }

		private void popFrontForward()
		{
			assert(!empty);
			scope(exit)
			{
				while(stack.length && path.value.length > stack.length)
					path.popBack;
			}

			while(!empty) final switch(_traversal_state)
			{
				case TraversalState.descent:
					if (!top.children.empty)
					{
						push;
						// designates that the current node is visited
						// first time before visiting any of its children
						_returnFlag = false;
						return;
					}
					_traversal_state = TraversalState.ascent;
					if (top.children.end != 0)
					{
						// designates that the current node is visited
						// once again after visiting all of its children
						_returnFlag = true;
						return;
					}
				break;
				case TraversalState.ascent:
					pop;
					if (empty)
						return;
					if (!top.children.empty)
						_traversal_state = TraversalState.next;
				break;
				case TraversalState.next:
					top.children.next;
					_traversal_state = TraversalState.descent;
				break;
			}
		}

		private void popFrontBackward()
		{
			assert(!empty);
			
			scope(exit)
			{
				while(stack.length && path.value.length > stack.length)
					path.popBack;
			}
			// edge case if only root is available
			if (stack.length == 1)
			{
				pop;
				path.value.popBack;
				return;
			}

			// level up to the parent
			pop;
			// select next child of the parent
			top.children.next(inverseDirection);
			// if there is no more child stay in the parent
			if (top.children.empty(inverseDirection))
				return;
			// go down to the selected child of the parent
			push;
			// go down to the deepest and lastest child
			while(true)
			{
				// select the last child of the current parent
				top.children.begin = top.children.end;
				// stop if there is no more children available
				if (top.children.empty(inverseDirection))
					return;
				// go to the selected child
				push;
			}
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

		// this type of reference has no explicit direction at all
		// and by default it means forward direction
		auto direction(Reference reference)
		{
			return Direction.forward;
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

		auto direction(Reference reference)
		{
			assert(reference);
			return reference.forwardDirection ? Direction.forward : Direction.backward;
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