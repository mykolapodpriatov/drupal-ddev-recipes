# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Multisite Drupal recipe (two sites, per-site DDEV overrides, init SQL for
  extra MySQL databases, drush install helper).
- Decoupled recipe — Drupal 11 + Next.js 14 sidecar service, optional
  single-hostname reverse-proxy nginx config, host commands for dev/build.
- Solr + Varnish recipe — Solr 9 sidecar with auto-created `drupal` core,
  Varnish 7.5 with tag-based BAN purges, drush reindex helper.
- Xdebug profile-mode recipe — request-trigger gated, host commands to
  start/stop/open profiles in qcachegrind/kcachegrind.
- Mailpit recipe — PHP sendmail override + Symfony Mailer SMTP transport
  config pointed at DDEV's built-in mailpit service.
- Redis vs Memcached comparison recipe — parallel `.ddev/` configs for
  drupal/redis and drupal/memcache with matched 128 MB caps for fair A/B.
- `scripts/validate-recipes.sh` — yamllint + structural + shellcheck pass
  for the whole `recipes/` tree.
- GitHub Actions `ci.yml` — runs the validate script and also re-parses
  every `.ddev/config.yaml` through `ddev config --auto-confirm` in a job.

## [0.1.0] - 2026-01-14

### Added
- Initial repository scaffolding (README, LICENSE, CONTRIBUTING, .gitignore).
- First recipe: `recipes/multisite/`.
