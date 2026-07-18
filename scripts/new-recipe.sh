#!/usr/bin/env bash
#
# new-recipe.sh — scaffold a new recipe that already passes validate-recipes.sh.
#
# CONTRIBUTING invites new recipes, but every author hand-copies the same
# boilerplate to satisfy the structure rules (a README.md plus a .ddev/config.yaml
# with a `name:` and a Drupal `type:`). This generates that valid skeleton in one
# step and refuses to clobber an existing recipe.
#
# Usage:
#   scripts/new-recipe.sh <recipe-name>
#
# Creates:
#   recipes/<recipe-name>/.ddev/config.yaml   (name: drupal-<name>, type: drupal11)
#   recipes/<recipe-name>/README.md           (a stub to fill in)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

die() { printf 'error: %s\n' "$*" >&2; exit 1; }

[ "$#" -eq 1 ] || die "usage: $(basename "$0") <recipe-name>"

NAME="$1"

# Recipe dir names double as DDEV project names: lowercase letters, digits and
# hyphens, starting with a letter. Validate up front so the generated
# config.yaml is a valid DDEV name and lints clean.
if ! printf '%s' "$NAME" | grep -qE '^[a-z][a-z0-9-]*$'; then
  die "recipe name must be lowercase letters/digits/hyphens and start with a letter (got '${NAME}')"
fi

RECIPE_DIR="${REPO_ROOT}/recipes/${NAME}"
if [ -e "$RECIPE_DIR" ]; then
  die "recipe already exists: recipes/${NAME} (refusing to overwrite)"
fi

mkdir -p "${RECIPE_DIR}/.ddev"

# --- .ddev/config.yaml ----------------------------------------------------
# Mirrors the base config shared by the other recipes so the skeleton boots
# with a plain `ddev start` before any services are added.
cat > "${RECIPE_DIR}/.ddev/config.yaml" <<YAML
name: drupal-${NAME}
type: drupal11
docroot: web
php_version: "8.3"
webserver_type: nginx-fpm
router_http_port: "80"
router_https_port: "443"
xdebug_enabled: false
performance_mode: mutagen
composer_version: "2"
database:
  type: mariadb
  version: "10.11"
nodejs_version: "20"

# TODO: add this recipe's services and overrides here — e.g.
# additional_hostnames, web_environment, docker-compose.*.yaml,
# commands/, php/, nginx_full/.
YAML

# --- README.md ------------------------------------------------------------
# The backticked code fences are escaped (\`) so the unquoted heredoc keeps
# them literal while still expanding ${NAME}.
cat > "${RECIPE_DIR}/README.md" <<MD
# ${NAME} recipe

> TODO: one-line summary of what this recipe sets up and why.

## When to use this

- TODO

## When *not* to use this

- TODO

## Install

\`\`\`bash
cp -r recipes/${NAME}/.ddev /path/to/project/
cd /path/to/project
ddev restart
\`\`\`

## Notes

TODO: settings.php snippets, service URLs, Composer requirements, etc.
MD

printf 'Created recipes/%s\n' "$NAME"
printf 'Next steps:\n'
printf '  1. Flesh out recipes/%s/.ddev/config.yaml and README.md\n' "$NAME"
printf '  2. Add a row to the root README.md recipe table\n'
printf '  3. Add a CHANGELOG entry under [Unreleased]\n'
printf '  4. Run scripts/validate-recipes.sh\n'
