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

## [0.1.0] - 2026-01-14

### Added
- Initial repository scaffolding (README, LICENSE, CONTRIBUTING, .gitignore).
- First recipe: `recipes/multisite/`.
