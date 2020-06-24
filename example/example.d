import std.stdio;
import selection_sleuth;

import example_table;

int main()
{
	auto table = build_example_table();
	auto q1 = new Query!()(table);

	writeln("If this were SQL, we could now write a query like this:");
	writeln("    SELECT ** FROM ExampleTable");
	writeln("And some D magic would turn it into this:");
	writeln("    "~q1.to_sql());
	writeln("(before it gets executed).");
	writeln("No one needs to type that list in the SELECT clause.");
	writeln("The query object figures it all out by itself by using");
	writeln("information (gleaned at compile time) from get/set and");
	writeln("opDispatch accesses run on the ResultRow objects it provides.");
	writeln("");

	writeln("Query results:");
	size_t i = 0;
	foreach(row; q1)
		writefln(
			"Row[%s] = { player_name = \"%s\", lives = \"%s\", favorite_pet = \"%s\" }",
			++i, row.player_name, row.lives, row.favorite_pet);

	writeln("");
	writeln("Doing some modifications...");
	auto q2 = new Query!()(table);
	foreach(row; q2)
	{
		row.lives = "99";
		q2.store_changes();
	}

	writeln("");
	writeln("And now it would return this:");
	auto q3 = new Query!()(table);
	i = 0;
	foreach(row; q3)
		writefln(
			"Row[%s] = { player_name = \"%s\", lives = \"%s\", favorite_pet = \"%s\" }",
			++i, row.player_name, row.lives, row.favorite_pet);
	writeln("(CHEATERS! All of 'em!)");

	writeln("");
	writeln("Now we will try selecting different fields, just to make sure");
	writeln("there's no cross-talk between Query instances.");
	auto q4 = new Query!()(table);
	writeln("The following accesses would generate a query similar to this in SQL:");
	writeln("    "~q4.to_sql());
	writeln("");
	i = 0;
	foreach(row; q4)
		writefln(
			"Row[%s] = { player_name = \"%s\", hit_points = \"%s\" }",
			++i, row.player_name, row.hit_points);

	writeln("");
	writeln("The end.");
	return 0;
}
