# migration

Include DB changes directly in your resources.

## How?

### Simplest: Idempotency

Most of the time, we want to add a table if it doesn't exist.

- Pick a resource.
- Add a `sql` directory to that resource.
- Write a query that performs an [idempotent](https://en.wikipedia.org/wiki/Idempotence) action, like `CREATE TABLE IF NOT EXISTS`.
- Call `exports['migration']:Migrate({ LoadResourceFile('<your resource name>', 'sql/<filename>.sql' })` within `MySQL.ready`.

Full example:

`resources/foo/fxmanifest.lua`:
```lua
fx_version 'cerulean'
game 'gta5'

dependency 'migration'

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'server.lua',
}

```

`resources/foo/server.lua`:
```lua
MySQL.ready(function()
	exports['migration']:Migrate({
		LoadResourceFile('foo', 'sql/create-table.sql'),
	})
end)

```

`resources/foo/sql/create-table.sql`:
```lua
CREATE TABLE IF NOT EXISTS `foo` (
  `id` int(11) PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT
);

```

Every time this resource starts, it will create this table if it doesn't exist. This is a lightweight operation.

### Conditions

The Lua table passed to the `Migrate` function can be more advanced. For example, if you need to check for the existence of a column and add it if it's not present, you could:
- Create a SQL file like before and call it something descriptive, like `resources/foo/sql/check-for-column.sql`.
- Create a SQL file that will perform the change if the condition is met (column is not present), like `resources/foo/sql/add-column.sql`.

The condition would depend on exactly what you're trying to do, but in this example we're adding a column. This query will return a single row containing `column_name`: `foo_bar` if the migration has already been made.

`check-for-column.sql`:
```sql
SELECT
  `column_name`
FROM
  `INFORMATION_SCHEMA`.`COLUMNS`
WHERE
  `TABLE_NAME` = 'players' AND
  `column_name` = 'foo_bar';

```

This query will actually perform the migration if the condition above is met.
`add-column.sql`:
```sql
ALTER TABLE
  `players`
ADD COLUMN
  `foo_bar` LONGTEXT;

```

After that, we can adjust our call to `migration:Migrate` to provide a table with the first item being conditions and queries.
`server.lua`:
```lua
exports['migration']:Migrate({
  {
    conditions = {
      LoadResourceFile('foo', 'sql/check-for-column.sql'),
    },
    queries = {
      LoadResourceFile('foo', 'sql/add-column.sql'),
    },
  },
})

```

Note: the lua table passed to `Migrate` is effectively an "array" of these condition + query pairs. All conditions must be satisfied in order for the queries to run. If conditions are met, then all queries will run.
