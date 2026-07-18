# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- PostgreSQL recipe — Drupal 11 on PostgreSQL 16 via DDEV's native
  `database.type: postgres`, with a `pgsql`-driver `settings.php` snippet and
  notes on how `ddev import-db` differs from MySQL (plain `pg_dump` only, no
  MySQL dumps, no custom/directory formats).
- OpenSearch recipe — single-node OpenSearch 2.x sidecar (the Apache-2.0
  Elasticsearch fork) wired for Search API, security plugin disabled for local
  dev, with the `search_api_opensearch` Composer note and server settings.
- Browser/E2E testing recipe — a `selenium/standalone-chromium` sidecar
  (multi-arch, runs on Apple Silicon) reachable at `http://chrome:4444/wd/hub`
  for FunctionalJavascript and Nightwatch tests, plus a `run-functional`
  command that exports `MINK_DRIVER_ARGS_WEBDRIVER` and runs the browser
  testsuite, with a live noVNC view on 7900.

## [0.2.0] - 2026-06-22

### Added
- Decoupled recipe — Drupal 11 + Next.js 14 sidecar service, JSON:API/CORS
  guidance, optional single-hostname reverse-proxy nginx config, and host
  commands (`next-dev`, `next-build`) plus a `frontend/` skeleton.
- Solr + Varnish recipe — Solr 9 sidecar with an auto-created `drupal` core,
  Varnish 7.5 with tag-based BAN purges, and a drush reindex helper.
- Xdebug profile-mode recipe — request-trigger gated, with `profile-start`,
  `profile-stop`, and `profile-open` host commands targeting
  qcachegrind/kcachegrind.
- Mailpit recipe — PHP sendmail override plus Symfony Mailer SMTP transport
  config pointed at DDEV's built-in Mailpit service.
- Redis vs Memcached comparison recipe — parallel `.ddev/` configs for
  drupal/redis and drupal/memcache with matched 128 MB caps for a fair A/B,
  and copy-paste `settings.php` snippets for each backend.
- `scripts/validate-recipes.sh` — yamllint + per-recipe structure checks +
  shellcheck over the whole `recipes/` tree.
- GitHub Actions `ci.yml` — a lint job running the validate script and a
  second job that re-parses every `.ddev/config.yaml` through
  `ddev config --auto-confirm`.

### Changed
- Xdebug profile recipe now ships its PHP ini **disabled**
  (`xdebug-profile.ini.disabled`) so profile mode's ~3-10x overhead is no
  longer enabled at plain `ddev start`; `profile-start`/`profile-stop` toggle
  it on and off.

### Fixed
- Decoupled recipe README and `frontend/.env.example` now document that
  `NEXT_PUBLIC_DRUPAL_BASE_URL` must be set to the project's real Drupal
  hostname instead of the hard-coded `drupal-decoupled` default.
- Xdebug recipe README now points at the correct cachegrind output path
  (`/mnt/ddev_config/cachegrind`, host `./.ddev/cachegrind/`).

## [0.1.0] - 2026-01-14

### Added
- Initial repository scaffolding (README, LICENSE, CONTRIBUTING, .gitignore).
- First recipe: `recipes/multisite/` (two sites on one codebase with separate
  DBs/hostnames, per-site DDEV overrides, init SQL for extra MySQL databases,
  and a drush install helper).

[Unreleased]: https://github.com/mykolapodpriatov/drupal-ddev-recipes/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/mykolapodpriatov/drupal-ddev-recipes/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/mykolapodpriatov/drupal-ddev-recipes/releases/tag/v0.1.0
