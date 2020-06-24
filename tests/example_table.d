module example_table;

import selection_sleuth;

class ExampleTable
{
	string[4]       header;
	ExampleRecord[] contents;
}

struct ExampleRecord
{
	string player_name;
	int    hit_points;
	string favorite_pet;
	int    lives;
}

ExampleTable  build_example_table()
{
	import std.array;
	auto appendr = appender!(ExampleRecord[]);
	void row(string pname, int hp, string favpet, int lives)
	{
		ExampleRecord rec;
		rec.player_name  = pname;
		rec.hit_points   = hp;
		rec.favorite_pet = favpet;
		rec.lives        = lives;
		appendr.put(rec);
	}

	row("The Destructor",     72, "cuddley kittens",  3);
	row("Edgy McDeathBlade",  45, "frowning ferrets", 2);
	row("Corporation #52",   135, "human souls",      4);
	row("Suckybus",           13, "tinfoil",          0);

	auto res = new ExampleTable;
	res.header[0] = "player_name";
	res.header[1] = "hit_points";
	res.header[2] = "favorite_pet";
	res.header[3] = "lives";
	res.contents = appendr.data;

	return res;
}


class Query(string file = __FILE__, string func = __FUNCTION__, size_t line = __LINE__)
{
	import std.conv : to;

	alias ColumnAccessTracker = SelectionSleuth!(string, SourceLocation(file, func, line).to!string);
	private static ColumnAccessTracker columnTracker;

	alias ResultRowT = ResultRow!ColumnAccessTracker;

	ExampleTable table;
	size_t   whichRow = 0;
	string[] currentRow;

	this(ExampleTable table)
	{
		assert(table !is null);
		currentRow = new string[columnTracker.array.length];
		this.table = table;
	}

	public bool empty() const
	{
		if ( whichRow >= table.contents.length )
			return true;
		else
			return false;
	}

	public ResultRowT front()
	{
		import std.conv;
		import std.traits : FieldNameTuple;
		assert( !empty, "Attempt to retrieve 'front' from empty query." );

		ExampleRecord rec = table.contents[whichRow];
		auto columns = columnTracker.array;
		for ( size_t i = 0; i < columns.length; i++ )
		{
			switch(columns[i])
			{
				static foreach(fieldName; FieldNameTuple!ExampleRecord)
				{
					case fieldName:
						mixin(`currentRow[i] = rec.`~ fieldName ~`.to!string;`);
						goto switchBreak;
				}

				default:
					import std.format;
					throw new Exception(format(
						"Column %s does not exist in the source table. "~
						"Possible values are %s", columns[i], FieldNameTuple!ExampleRecord));
			}
			switchBreak:
		}
		return ResultRowT(&columnTracker, currentRow);
	}

	public void popFront()
	{
		whichRow++;
	}

	public void store_changes()
	{
		import std.conv;
		import std.traits : FieldNameTuple;
		assert( !empty, "Attempt to retrieve 'front' from empty query." );

		ExampleRecord rec = table.contents[whichRow];
		auto columns = columnTracker.array;
		for ( size_t i = 0; i < columns.length; i++ )
		{
			switch(columns[i])
			{
				static foreach(fieldName; FieldNameTuple!ExampleRecord)
				{
					case fieldName:
						mixin(q{
							alias } ~fieldName~ q{_type = typeof(rec.} ~fieldName~ q{);
							rec.} ~fieldName~ q{ = currentRow[i].to!} ~fieldName~ q{_type;
						});
						goto switchBreak;
				}

				default:
					import std.format;
					throw new Exception(format(
						"Column %s does not exist in the source table. "~
						"Possible values are %s", columns[i], FieldNameTuple!ExampleRecord));
			}
			switchBreak:
		}
		table.contents[whichRow] = rec;
	}

	public string to_sql() const
	{
		import std.array;
		auto strBuilder = appender!string;

		strBuilder.put("SELECT ");

		auto arr = this.columnTracker.array;

		if ( arr.length > 0 )
		{
			strBuilder.put(arr[0]);
			arr.popFront();
		}

		foreach( column; arr )
		{
			strBuilder.put(", ");
			strBuilder.put(column);
		}

		strBuilder.put(" FROM ExampleTable");
		return strBuilder.data;
	}
}

struct ResultRow(alias ColumnAccessTracker)
{
	string[] selectedColumns;
	ColumnAccessTracker* columnTracker;
	this(ColumnAccessTracker* tracker, string[] selectedColumns)
	{
		assert(tracker !is null);
		this.columnTracker = tracker;
		this.selectedColumns = selectedColumns;
	}

	/// Most convenient getter, but can only be used when the column name is
	/// a valid D identifier.
	public @property string opDispatch(string columnName)()
	{
		return get!columnName();
	}

	/// Most convenient setter, but can only be used when the column name is
	/// a valid D identifier.
	public @property string opDispatch(string columnName)(string newCellValue)
	{
		return set!columnName(newCellValue);
	}

	/// Getter to use for columns with non-identifier names.
	public string get(string columnName)()
	{
		columnTracker.put!columnName;
		ptrdiff_t colNumber = columnTracker.index!columnName;
		return this.selectedColumns[colNumber];
	}

	/// Setter to use for columns with non-identifier names.
	public string set(string columnName)(string newCellValue)
	{
		columnTracker.put!columnName;
		ptrdiff_t colNumber = columnTracker.index!columnName;
		return this.selectedColumns[colNumber] = newCellValue;
	}
}

unittest
{
	import std.stdio;

	writefln("Testing in %s", __FILE__);
	auto table = build_example_table();

	auto q1 = new Query!()(table);

	assert(!q1.empty);
	auto q1r1 = q1.front; q1.popFront();
	assert(q1r1.player_name  == "The Destructor");
	assert(q1r1.lives        == "3");
	assert(q1r1.favorite_pet == "cuddley kittens");

	assert(!q1.empty);
	auto q1r2 = q1.front; q1.popFront();
	assert(q1r2.player_name  == "Edgy McDeathBlade");
	assert(q1r2.lives        == "2");
	assert(q1r2.favorite_pet == "frowning ferrets");

	assert(!q1.empty);
	auto q1r3 = q1.front; q1.popFront();
	assert(q1r3.player_name  == "Corporation #52");
	assert(q1r3.lives        == "4");
	assert(q1r3.favorite_pet == "human souls");

	assert(!q1.empty);
	auto q1r4 = q1.front; q1.popFront();
	assert(q1r4.player_name  == "Suckybus");
	assert(q1r4.lives        == "0");
	assert(q1r4.favorite_pet == "tinfoil");

	// Modify the table a bit.
	auto q2 = new Query!()(table);
	foreach(row; q2)
	{
		row.lives = "99";
		q2.store_changes();
	}

	auto q3 = new Query!()(table);

	assert(!q3.empty);
	auto q3r1 = q3.front; q3.popFront();
	assert(q3r1.player_name  == "The Destructor");
	assert(q3r1.lives        == "99");
	assert(q3r1.favorite_pet == "cuddley kittens");

	assert(!q3.empty);
	auto q3r2 = q3.front; q3.popFront();
	assert(q3r2.player_name  == "Edgy McDeathBlade");
	assert(q3r2.lives        == "99");
	assert(q3r2.favorite_pet == "frowning ferrets");

	assert(!q3.empty);
	auto q3r3 = q3.front; q3.popFront();
	assert(q3r3.player_name  == "Corporation #52");
	assert(q3r3.lives        == "99");
	assert(q3r3.favorite_pet == "human souls");

	assert(!q3.empty);
	auto q3r4 = q3.front; q3.popFront();
	assert(q3r4.player_name  == "Suckybus");
	assert(q3r4.lives        == "99");
	assert(q3r4.favorite_pet == "tinfoil");

	// Now we will try selecting different fields, just to make sure
	// there's no cross-talk between Query instances.
	// The following accesses would generate a query similar to this in SQL:
	//     SELECT hit_points, player_name FROM ExampleTable
	auto q4 = new Query!()(table);

	assert(!q4.empty);
	auto q4r1 = q4.front; q4.popFront();
	assert(q4r1.player_name  == "The Destructor");
	assert(q4r1.hit_points   == "72");

	assert(!q4.empty);
	auto q4r2 = q4.front; q4.popFront();
	assert(q4r2.player_name  == "Edgy McDeathBlade");
	assert(q4r2.hit_points   == "45");

	assert(!q4.empty);
	auto q4r3 = q4.front; q4.popFront();
	assert(q4r3.player_name  == "Corporation #52");
	assert(q4r3.hit_points   == "135");

	assert(!q4.empty);
	auto q4r4 = q4.front; q4.popFront();
	assert(q4r4.player_name  == "Suckybus");
	assert(q4r4.hit_points   == "13");

	writeln("  done.");
	writeln("");
}
