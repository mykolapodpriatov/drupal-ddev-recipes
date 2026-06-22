# Contributing

Thanks for taking the time to contribute. This repo is a curated set of DDEV
recipes for Drupal — every recipe is meant to be **copy-paste runnable**, not
a tutorial. Please keep that bar in mind when proposing changes.

## Ground rules

- **DDEV ^1.23** and **PHP 8.3+** are the minimum supported versions.
- Recipes target **Drupal 11** primarily and **Drupal 10.3+** where it does
  not require extra effort.
- Every recipe lives under `recipes/<recipe-name>/` and ships its own
  `README.md` plus a working `.ddev/` directory.
- A recipe must boot with a clean `ddev start` from an empty Drupal project
  after the `.ddev/` directory is copied in. Keep manual steps to a minimum;
  where a recipe genuinely needs project-specific values (e.g. the decoupled
  recipe's frontend hostname), document them clearly in that recipe's README.
- Keep configuration files commented. The audience is a developer learning
  *why*, not just *what*.

## Adding a new recipe

1. Open an issue describing the use-case the recipe solves and the moving
   parts (extra services, host commands, settings.php snippets).
2. Create `recipes/<your-recipe>/` with at minimum:
   - `README.md` — purpose, when to use, when **not** to use, install steps.
   - `.ddev/config.yaml` — base DDEV config.
   - Any `docker-compose.*.yaml`, `commands/`, `php/`, `nginx_full/` overrides.
3. Add an entry to the top-level `README.md` recipe table.
4. Add a CHANGELOG entry under `[Unreleased]`.
5. Run `scripts/validate-recipes.sh` locally before pushing.

## Style

- YAML: 2-space indent, no trailing whitespace. We run `yamllint` in CI.
- Shell: `#!/usr/bin/env bash`, `set -euo pipefail`, shellcheck-clean.
- VCL / nginx confs: comment every non-obvious block.

## Reporting bugs

Open an issue with:
- Recipe name and commit SHA.
- `ddev version` output.
- Host OS (the Docker provider matters — Docker Desktop, Colima, OrbStack).
- Minimal reproduction (ideally a public branch).
