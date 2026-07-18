# PostgreSQL recipe

Runs Drupal 11 on **PostgreSQL 16** instead of the DDEV default of MariaDB.
Use this when the target production environment is Postgres (e.g. a managed
Cloud SQL / RDS Postgres instance, or a platform like Platform.sh configured
for pgsql) and you want local parity on the database engine.

DDEV supports Postgres natively — set `database.type: postgres` and DDEV
starts a `postgres:16` container as the `db` service. Everything else
(`ddev drush`, `ddev launch`, Mailpit, Xdebug) works exactly as it does on
MySQL/MariaDB.

## When *not* to use this

- If production runs MySQL/MariaDB, stay on the default — matching the engine
  locally is the whole point.
- Some contrib modules still ship MySQL-only queries or `dbtng` assumptions.
  Postgres is a Drupal-core-supported driver, but audit your contrib list
  before committing a project to it.

## Install

```bash
cp -r recipes/postgres/.ddev /path/to/project/
cd /path/to/project
ddev restart
```

`ddev restart` recreates the `db` container on Postgres 16. If the project
previously ran MySQL/MariaDB, DDEV will delete the old database volume — snapshot
first with `ddev snapshot` if you need it.

Then install Drupal against the pgsql driver:

```bash
ddev drush site:install --db-url=pgsql://db:db@db:5432/db -y
```

## settings.php

Point Drupal's default connection at the `pgsql` driver. DDEV's
`settings.ddev.php` already does this when it detects a Postgres `db`
service, but if you manage `settings.php` yourself, use:

```php
$databases['default']['default'] = [
  'driver' => 'pgsql',
  'namespace' => 'Drupal\\pgsql\\Driver\\Database\\pgsql',
  'host' => 'db',
  'port' => '5432',
  'database' => 'db',
  'username' => 'db',
  'password' => 'db',
  'prefix' => '',
  // Postgres uses a schema, not a prefix, for isolation. 'public' is the
  // default and is almost always what you want.
  // 'schema' => 'public',
];
```

The `namespace` is what changes versus MySQL — Drupal 10/11 ship the pgsql
driver in the `pgsql` core module (`Drupal\pgsql\Driver\Database\pgsql`),
which must be enabled for the connection to work.

## Importing a database — Postgres vs MySQL

`ddev import-db` works with Postgres, but the dump format differs from MySQL:

- **Feed it a Postgres dump.** A MySQL `.sql` dump will **not** import into
  Postgres — the SQL dialects diverge (backticks, `AUTO_INCREMENT`, engine
  clauses, etc.). Export from a Postgres source with `pg_dump`.

  ```bash
  # Plain-SQL dump (importable directly):
  pg_dump --no-owner --no-privileges -Fp mydb > mydb.sql
  ddev import-db --file=mydb.sql

  # Gzipped works too:
  ddev import-db --file=mydb.sql.gz
  ```

- **Custom/directory `pg_dump` formats (`-Fc`, `-Fd`) are not supported** by
  `ddev import-db` — it pipes plain SQL to `psql`. Dump with `-Fp` (plain).

- **Exporting** back out uses the same flag:

  ```bash
  ddev export-db --file=mydb.sql.gz
  ```

- Migrating an existing MySQL Drupal site to Postgres is a data migration,
  not a dump swap — use a tool like `pgloader` or Drupal's own migrate
  framework. `ddev import-db` alone will not convert dialects.

## Verifying

```bash
ddev drush sql:query "SELECT version();"   # should print PostgreSQL 16.x
ddev drush status                          # 'Database driver' => pgsql
```
