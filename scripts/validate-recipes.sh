#!/usr/bin/env bash
#
# validate-recipes.sh — sanity-check every recipe under recipes/.
#
# Checks:
#   1. yamllint passes on every *.yml / *.yaml file (if yamllint is on PATH).
#   2. Each recipe has a README.md.
#   3. Each recipe (or recipe variant directory containing .ddev/) has a
#      valid-looking .ddev/config.yaml with a `name:` and a `type:` field.
#   4. shellcheck passes on .ddev/commands/**/* (if shellcheck is on PATH).
#
# Exit code:
#   0 — everything passed (or skipped because tooling missing)
#   1 — something failed; first failure detail printed.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RECIPES_DIR="${REPO_ROOT}/recipes"

red()    { printf '\033[31m%s\033[0m\n' "$*"; }
green()  { printf '\033[32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[33m%s\033[0m\n' "$*"; }

if [ ! -d "$RECIPES_DIR" ]; then
  red "No recipes/ directory found at ${RECIPES_DIR}"
  exit 1
fi

FAIL=0

# ----- 1. yamllint --------------------------------------------------------
if command -v yamllint >/dev/null 2>&1; then
  echo "==> Running yamllint on YAML files under recipes/"
  # Rules live in .yamllint.yml at the repo root (relaxed for Drupal/DDEV
  # config-export YAML — see that file for the rationale). CI reads the same
  # file, so local and CI lint stay in lockstep.
  if ! yamllint -c "${REPO_ROOT}/.yamllint.yml" "$RECIPES_DIR"; then
    red "yamllint reported issues."
    FAIL=1
  else
    green "yamllint OK."
  fi
else
  yellow "yamllint not installed — skipping YAML lint."
fi

# ----- 2. Required files per recipe --------------------------------------
echo "==> Checking required files in each recipe"
shopt -s nullglob

# Each immediate subdirectory of recipes/ is a recipe.
for recipe_dir in "$RECIPES_DIR"/*/; do
  recipe_name="$(basename "$recipe_dir")"

  if [ ! -f "${recipe_dir}README.md" ]; then
    red "  [${recipe_name}] missing README.md"
    FAIL=1
    continue
  fi

  # Find every .ddev/config.yaml under this recipe (recipes may have variants).
  ddev_configs=$(find "$recipe_dir" -type f -path '*/.ddev/config.yaml' 2>/dev/null || true)

  if [ -z "$ddev_configs" ]; then
    red "  [${recipe_name}] no .ddev/config.yaml found"
    FAIL=1
    continue
  fi

  while IFS= read -r cfg; do
    if ! grep -qE '^name:' "$cfg"; then
      red "  [${recipe_name}] ${cfg#"$REPO_ROOT"/} missing 'name:'"
      FAIL=1
    fi
    if ! grep -qE '^type:[[:space:]]*drupal(1[01]|10|11)' "$cfg"; then
      red "  [${recipe_name}] ${cfg#"$REPO_ROOT"/} 'type:' is not a Drupal type"
      FAIL=1
    fi
  done <<<"$ddev_configs"

  green "  [${recipe_name}] structure OK"
done

# ----- 3. shellcheck on bundled commands ---------------------------------
if command -v shellcheck >/dev/null 2>&1; then
  echo "==> Running shellcheck on .ddev/commands/**/*"
  while IFS= read -r script; do
    if ! shellcheck -S warning -e SC1091,SC2034,SC2012 "$script"; then
      red "shellcheck failed on ${script#"$REPO_ROOT"/}"
      FAIL=1
    fi
  done < <(find "$RECIPES_DIR" -type f -path '*/.ddev/commands/*' -not -name '*.md')
else
  yellow "shellcheck not installed — skipping shell lint."
fi

echo ""
if [ "$FAIL" -eq 0 ]; then
  green "All checks passed."
  exit 0
else
  red "Validation failed."
  exit 1
fi
