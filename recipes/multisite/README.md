# Multisite Drupal recipe

Two Drupal sites running off a single codebase, two databases, two hostnames,
all under one DDEV project. Useful for client portfolios where each brand is
a separate site but shares modules, themes, and config splits.

## Layout

```
docroot/
  sites/
    site1.ddev.site/
      settings.php
      files/
    site2.ddev.site/
      settings.php
      files/
    default/
    sites.php          <-- maps hostnames to directories
```

After copying this recipe in, your project should have:

- `https://site1.ddev.site` -> `sites/site1.ddev.site` -> DB `db_site1`
- `https://site2.ddev.site` -> `sites/site2.ddev.site` -> DB `db_site2`

## Install

```bash
# 1. Copy the .ddev directory into your project root:
cp -r recipes/multisite/.ddev /path/to/project/

# 2. Copy sites.php to your sites/ directory:
cp recipes/multisite/sites.php.example /path/to/project/web/sites/sites.php

# 3. Boot it:
cd /path/to/project
ddev restart

# 4. Run the bundled install command (installs Drupal on both sites):
ddev multisite-install
```

The `multisite-install` command runs `drush site:install` twice, once per
site, using the per-site `--db-url` so each site lands in its own database.

## Adding a third site

1. Add `site3.ddev.site` to `.ddev/config.yaml` under `additional_hostnames`.
2. Add a `.ddev/config.site3.yaml` override if you need site-specific PHP
   tweaks or extra env vars.
3. Add `CREATE DATABASE IF NOT EXISTS db_site3 ...` to
   `.ddev/mysql/multisite-init.sql`.
4. Add a `'site3.ddev.site' => 'site3.ddev.site'` mapping in `sites.php`.
5. Run `ddev restart` (re-runs the init SQL on a fresh DB) and re-run
   `ddev multisite-install`.

## Notes

- `additional_hostnames` is the right knob for multisite, **not**
  `additional_fqdns`. The `.ddev.site` suffix is added by DDEV's mkcert.
- The extra MySQL DBs are created by mounting an init script into
  `/docker-entrypoint-initdb.d/`. That directory only runs on **first** DB
  init — if you change `multisite-init.sql` after the fact, run
  `ddev delete -Oy && ddev start` to re-trigger it.
- Each `sites/<host>/settings.php` should `require` the DDEV-generated
  `settings.ddev.php` for that site. DDEV ^1.23 generates a per-site
  `settings.ddev.php` automatically when it detects a multisite layout.
