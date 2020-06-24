module selection_sleuth;

import std.stdio;

private struct Util
{
	private static T[] inplace_dedup(T)(ref T[] arr)
	{
		size_t srcIdx = 0;
		size_t dstIdx = 0;
		size_t len = arr.length;
		while (srcIdx < len)
		{
			auto e = arr[srcIdx++];
			arr[dstIdx++] = e;
			while (
				srcIdx < len &&
				e == arr[srcIdx] )
				srcIdx++;
		}
		arr.length = dstIdx;
		return arr;
	}

	unittest
	{
		int[] dedup(const(int)[] input)
		{
			int[] result = new int[input.length];
			result[] = input[];
			return inplace_dedup(result);
		}

		assert(dedup([]) == []);
		assert(dedup([0]) == [0]);
		assert(dedup([0,1]) == [0,1]);
		assert(dedup([0,0]) == [0]);
		assert(dedup([0,1,1]) == [0,1]);
		assert(dedup([0,0,1]) == [0,1]);
		assert(dedup([0,0,0]) == [0]);
		assert(dedup([1,2,2,2]) == [1,2]);
		assert(dedup([0,1,2,2]) == [0,1,2]);
		assert(dedup([0,1,1,2]) == [0,1,2]);
		assert(dedup([0,0,1,2]) == [0,1,2]);
		assert(dedup([0,0,0,1]) == [0,1]);
		assert(dedup([1,2,2,2,2]) == [1,2]);
		assert(dedup([0,1,2,2,2]) == [0,1,2]);
		assert(dedup([0,1,1,2,2]) == [0,1,2]);
		assert(dedup([0,1,1,1,2]) == [0,1,2]);
		assert(dedup([0,0,1,1,2]) == [0,1,2]);
		assert(dedup([0,0,0,1,2]) == [0,1,2]);
		assert(dedup([0,0,0,0,1]) == [0,1]);
	}

	public static ptrdiff_t binarySearch(T, ptrdiff_t linearThreshold = 8)(T[] haystack, T needle)
	{
		import std.algorithm.searching : countUntil;
		import std.range.primitives;
		immutable ptrdiff_t notFound = -1;
		if ( haystack.empty )
			return notFound;

		import std.traits : Unqual;
		alias U = Unqual!T;

		ptrdiff_t lo = 0;
		ptrdiff_t hi = haystack.length-1;
		U loVal = haystack[lo];
		U hiVal = haystack[hi];
		if ( needle < loVal || needle > hiVal )
			return notFound;

		while (true)
		{
			// Optimization: For small runs, just linear search.
			// This also makes it easier to write the search without
			// committing accidental fencepost (off-by-1) errors, because
			// we are always guaranteed to have this many elements left
			// when bisecting, and that guarantees that 'mid' is always
			// inside the array AND unique (doesn't overlap 'lo' or 'hi').
			static assert( linearThreshold >= 4 ); // Guarantee no fencepost errors.
			ptrdiff_t delta = hi-lo + 1;
			if ( delta <= linearThreshold )
			{
				ptrdiff_t subIndex = haystack[lo..hi+1].countUntil(needle);
				//writefln("Linear search on %s returns %s", haystack[lo..hi+1], subIndex);
				if ( subIndex < 0 )
					return notFound;
				return lo + subIndex;
			}
			//else
			//	writefln("No linear search. delta==%s, lo==%s, hi==%s", delta, lo, hi);

			ptrdiff_t mid = lo + delta/2;
			U midVal = haystack[mid];
			if ( needle <= midVal )
			{
				hi = mid;
				hiVal = midVal;
				continue;
			}
			else // needle > midVal
			{
				lo = mid; // Tempted to put 'mid+1', but that would require an extra dereference per iteration :/
				loVal = midVal;
				continue;
			}
			assert(0);
		}
		assert(0);
	}

	unittest
	{
		// Set the linearSearchThreshold lower than what is probably used
		// for practical code. This allows us to test with smaller arrays.
		immutable linearSearchThreshold = 4;
		alias bsearch = binarySearch!(int, linearSearchThreshold);

		// Basic boundary conditions.
		assert(bsearch([],1) == -1);
		assert(bsearch([0],1) == -1);
		assert(bsearch([1],1) == 0);
		assert(bsearch([0,0],1) == -1);
		assert(bsearch([0,1],1) == 1);
		assert(bsearch([1,1],1) == 0);
		assert(bsearch([1,2],1) == 0);
		assert(bsearch([2,2],1) == -1);

		// Searching with arrays at or longer than the linear search threshold.
		assert(bsearch([0,0,0,0],1) == -1);
		assert(bsearch([1,1,1,1],1) == 0);
		assert(bsearch([2,2,2,2],1) == -1);
		assert(bsearch([1,2,2,2],1) == 0);
		assert(bsearch([0,1,1,2],1) == 1);
		assert(bsearch([0,0,0,1],1) == 3);
		assert(bsearch([0,1,3,4],2) == -1);
		assert(bsearch([0,0,0,0,0],1) == -1);
		assert(bsearch([1,1,1,1,1],1) == 0);
		assert(bsearch([2,2,2,2,2],1) == -1);
		assert(bsearch([1,2,2,2,2],1) == 0);
		assert(bsearch([0,0,1,2,2],1) == 2);
		assert(bsearch([0,0,0,0,1],1) == 4);
		assert(bsearch([0,1,1,3,4],2) == -1);
		assert(bsearch([0,0,0,0,0,0,0,0],1) == -1);
		assert(bsearch([1,1,1,1,1,1,1,1],1) == 0);
		assert(bsearch([2,2,2,2,2,2,2,2],1) == -1);
		assert(bsearch([0,0,0,0,0,0,0,1],1) == 7);
		assert(bsearch([0,0,0,0,0,0,1,2],1) == 6);
		assert(bsearch([0,0,0,0,0,1,2,2],1) == 5);
		assert(bsearch([0,0,0,0,1,2,2,2],1) == 4);
		assert(bsearch([0,0,0,1,2,2,2,2],1) == 3);
		assert(bsearch([0,0,1,2,2,2,2,2],1) == 2);
		assert(bsearch([0,1,2,2,2,2,2,2],1) == 1);
		assert(bsearch([1,2,2,2,2,2,2,2],1) == 0);
		assert(bsearch([0,1,1,1,1,1,1,2],1) == 1);
		assert(bsearch([0,0,1,1,1,1,1,2],1) == 2);
		assert(bsearch([0,0,0,1,1,1,1,2],1) == 3);
		assert(bsearch([0,0,0,0,1,1,1,2],1) == 4);
		assert(bsearch([0,0,0,0,0,1,1,2],1) == 5);
		assert(bsearch([0,0,0,0,0,0,1,2],1) == 6);
		assert(bsearch([0,1,1,1,1,1,1,1],1) == 1);
		assert(bsearch([0,0,1,1,1,1,1,1],1) == 2);
		assert(bsearch([0,0,0,1,1,1,1,1],1) == 3);
		assert(bsearch([0,0,0,0,1,1,1,1],1) == 4);
		assert(bsearch([0,0,0,0,0,1,1,1],1) == 5);
		assert(bsearch([0,0,0,0,0,0,1,1],1) == 6);
		assert(bsearch([0,2,2,2,2,2,2,2],1) == -1);
		assert(bsearch([0,0,2,2,2,2,2,2],1) == -1);
		assert(bsearch([0,0,0,2,2,2,2,2],1) == -1);
		assert(bsearch([0,0,0,0,2,2,2,2],1) == -1);
		assert(bsearch([0,0,0,0,0,2,2,2],1) == -1);
		assert(bsearch([0,0,0,0,0,0,2,2],1) == -1);
		assert(bsearch([0,0,0,0,0,0,0,2],1) == -1);
	}
}

/// This struct is useful for generating the _callSiteId needed by the
/// SelectionSleuth.
/// Usage: Have your type that uses SelectionSleuth accept template parameters
/// for file, function, and line number, using __FILE__, __FUNCTION__, and
/// __LINE__, respectively, as parameter defaults.
/// Feed those arguments into this struct and then call .toString() or
/// std.conv's to!string() function on this to receive a string suitable for
/// use as SelectionSleuth's unique id.
public struct SourceLocation
{
	string file;
	string func;
	int    line;

	this(string _file, string _func, int _line)
	{
		this.file = _file;
		this.func = _func;
		this.line = _line;
	}

	string toString()
	{
		import std.format;
		return format("%s: %s(...) @%s", file, func, line);
	}
}

public class AccessorNotEstablishedException : Exception
{
	this(string msg) { super(msg); }
}

public struct SelectionSleuth(T, string _callSiteId)
{
	import std.array;
	public immutable string callSiteId = _callSiteId;
	private static Appender!(T[]) arrayBuilder;
	private static bool builderValid = false;
	private immutable(T)[]  arrayResult;
	private bool arrayReady = false;

	/// The array of identifiers that were accessed (e.g. visited by this
	/// SelectionSleuth's 'put' function).
	/// The first retrieval of this array will be an O(n*log(n)) operation,
	/// as it involves sorting and deduplicating the contents of the working
	/// data that was 
	public @property immutable(T)[] array()
	{
		if ( !this.arrayReady )
		{
			this.prepare_array();
			this.arrayReady = true;
		}

		return this.arrayResult;
	}

	//@disable this();

	public void put(T accessorId)()
	{
		struct Foo
		{
			static this()
			{
				//// .array should not be accessed during start-time.
				//assert( !arrayReady ); // TODO: no way to enforce this, it seems.

				// Construct the array appender once, before any accessor
				// identifiers are stored.
				// I would do this in a top-level 'static this()' if it could
				// be guaranteed to run before any static constructors in the
				// 'put' function (or maybe it is guaranteed, but the intent
				// still wouldn't be as clear).
				if ( !builderValid )
				{
					arrayBuilder = appender!(T[])();
					builderValid = true;
				}

				arrayBuilder.put(accessorId);
			}
		}
	}

	/// Retrieves the 'index' of the given 'accessorId' such that
	/// selectionSleuth.array[index] would return that 'accessorId'.
	/// If selectionSleuth.array has never been accessed, this will have
	/// the same first-run algorithmic complexity as that, O(n*log(n)), because
	/// this function will need to use that property in its calculations.
	/// Otherwise, this costs O(log(n)) time complexity on first run, then
	/// becomes a simple O(1) test-and-variable-return for all runs afterwards.
	/// Time complexities are stated with 'n' being the number of accessors
	/// tracked by this instance of SelectionSleuth, after deduping.
	/// Throws an AccessorNotEstablishedException if the passed 'accessorId'
	/// was never given in a call to selectionSleuth.put!(...).
	public ptrdiff_t index(T accessorId)()
	{
		// This static variable will be unique to this accessor ID, which is
		// also unique to this SelectionSleuth instance.
		static ptrdiff_t idx = ptrdiff_t.max;

		// Memoize the calculation.
		if ( idx == ptrdiff_t.max )
			idx = this.calculate_index(accessorId);

		// ...
		return idx;
	}

	// Optimization: Break this stuff out of the 'get_index' function so that
	// this only-used-once stuff isn't as likely to be loaded into the
	// instruction cache every dang time an index is retrieved.
	private ptrdiff_t calculate_index(T accessorId)
	{
		auto arr = this.array;

		// O(log(n)) binary search.
		ptrdiff_t index = Util.binarySearch(arr, accessorId);
		if ( index < 0 )
		{
			import std.format;
			throw new AccessorNotEstablishedException(format(
				"Accessor \"%s\" was never established with a corresponding"
				~" call to SelectionSleuth.put(identifier). Current accessor"
				~" array is as follows: %s", accessorId, arr));
		}

		return index;
	}

	private void prepare_array()
	{
		import std.algorithm.sorting : sort;
		import std.exception : assumeUnique;

		// Retrieve, sort, and deduplicate the list of accessor identifiers.
		auto arr = arrayBuilder.data.dup;
		arr.sort;
		Util.inplace_dedup(arr);
		this.arrayResult = assumeUnique(arr);

		// Give the GC an opportunity to reclaim some resources.
		this.arrayBuilder.clear();
		this.builderValid = false;
	}
}

