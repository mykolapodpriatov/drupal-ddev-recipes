#!/usr/bin/env bash
#
# validate-recipes.sh — sanity-check every recipe under recipes/.
#
# Checks:
#   1. yamllint passes on every *.yml / *.yaml file (if yamllint is on PATH).
#   2. Each recipe has a README.md.
#   3. Each recipe (or recipe variant directory containing .ddev/) has a
#      valid-looking .ddev/config.yaml with a `name:` and a `type:` field.
#   4. shellcheck passes on .ddev/commands/**/* and scripts/*.sh
#      (if shellcheck is on PATH).
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
  echo "==> Running shellcheck on .ddev/commands/**/* and scripts/*.sh"
  while IFS= read -r script; do
    if ! shellcheck -S warning -e SC1091,SC2034,SC2012 "$script"; then
      red "shellcheck failed on ${script#"$REPO_ROOT"/}"
      FAIL=1
    fi
  done < <(
    find "$RECIPES_DIR" -type f -path '*/.ddev/commands/*' -not -name '*.md'
    find "${REPO_ROOT}/scripts" -type f -name '*.sh'
  )
else
  yellow "shellcheck not installed — skipping shell lint."
fi

# ----- 4. Decoupled nginx must not serve PHP source ------------------------
# The Drupal path location is a regex and is checked before the .php
# location. It has try_files and no fastcgi_pass. Naming update.php or
# install.php there makes nginx return the file as text.
echo "==> Checking the decoupled nginx does not serve PHP source"
nginx_conf="${RECIPES_DIR}/decoupled/.ddev/nginx_full/nginx-site.conf"
if [ ! -f "$nginx_conf" ]; then
  red "  [decoupled] missing nginx_full/nginx-site.conf"
  FAIL=1
else
  drupal_location=$(grep -E 'location ~ \^/\(jsonapi\|' "$nginx_conf" || true)
  if printf '%s\n' "$drupal_location" | grep -q 'update\\.php\|install\\.php'; then
    red "  [decoupled] the Drupal path location matches a PHP file and would serve its source"
    FAIL=1
  fi
  if ! grep -q 'fastcgi_pass' "$nginx_conf"; then
    red "  [decoupled] nginx-site.conf has no fastcgi_pass, so PHP never runs"
    FAIL=1
  fi
fi

# ----- 5. Mailpit recipe matches the DDEV web image -----------------------
# DDEV ^1.23 (the floor this repo documents) listens for SMTP inside the
# web container at 127.0.0.1:1025 and ships /usr/local/bin/mailpit, not
# mhsendmail. settings.ddev.php points Symfony Mailer at localhost:1025.
echo "==> Checking the mailpit recipe against the DDEV 1.23 Mailpit layout"
mail_ini="${RECIPES_DIR}/mailpit/.ddev/php/mail.ini"
mail_cfg="${RECIPES_DIR}/mailpit/.ddev/config.yaml"
mail_yml="${RECIPES_DIR}/mailpit/config/sync/symfony_mailer.mailer_transport.smtp.yml"
if [ -f "$mail_ini" ]; then
  if grep -E '^[[:space:]]*sendmail_path' "$mail_ini" | grep -q 'mhsendmail'; then
    red "  [mailpit] mail.ini calls mhsendmail, which DDEV ^1.23 does not ship"
    FAIL=1
  fi
  if ! grep -q '/usr/local/bin/mailpit sendmail' "$mail_ini"; then
    red "  [mailpit] mail.ini must route mail() through /usr/local/bin/mailpit sendmail"
    FAIL=1
  fi
  if ! grep -q '127.0.0.1:1025' "$mail_ini"; then
    red "  [mailpit] mail.ini must send to 127.0.0.1:1025"
    FAIL=1
  fi
else
  red "  [mailpit] missing .ddev/php/mail.ini"
  FAIL=1
fi
if [ -f "$mail_yml" ]; then
  if grep -qE '^[[:space:]]*host:[[:space:]]*mailpit[[:space:]]*$' "$mail_yml"; then
    red "  [mailpit] SMTP host mailpit does not resolve; Mailpit is not a compose service"
    FAIL=1
  fi
  if ! grep -qE '^[[:space:]]*host:[[:space:]]*localhost[[:space:]]*$' "$mail_yml"; then
    red "  [mailpit] SMTP host must be localhost, matching settings.ddev.php"
    FAIL=1
  fi
fi
if [ -f "$mail_cfg" ] && grep -q 'smtp://mailpit:' "$mail_cfg"; then
  red "  [mailpit] MAILER_DSN still uses the mailpit hostname"
  FAIL=1
fi

echo ""
if [ "$FAIL" -eq 0 ]; then
  green "All checks passed."
  exit 0
else
  red "Validation failed."
  exit 1
fi
