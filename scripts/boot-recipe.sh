#!/usr/bin/env bash
#
# boot-recipe.sh — copy a recipe's .ddev/ into a scratch project and ddev start it.
#
# This is the CI smoke: no Drupal codebase is required. `ddev start` brings
# up web/db plus any compose sidecars from the recipe alone.
#
# Usage:
#   scripts/boot-recipe.sh --list          # recipe dirs (relative to recipes/), one per line
#   scripts/boot-recipe.sh --json          # same list as a JSON array (for GHA matrix)
#   scripts/boot-recipe.sh <recipe-dir>    # boot that recipe
#
# <recipe-dir> is relative to recipes/ (e.g. mailpit or
# redis-memcached-comparison/with-redis) or a path that contains .ddev/config.yaml.
#
# Mutagen is forced off in the scratch project: recipes ship
# `performance_mode: mutagen` for macOS contributors, but GitHub-hosted
# Linux runners do not need it and it can stall the boot.
#
# Recipes whose start hooks need Composer (or other extra network) are a
# known follow-up; none of the current recipes do that.
#
# Exit 0 on a healthy start; 1 on failure. Always `ddev delete -Oy` the
# scratch project afterwards.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RECIPES_DIR="${REPO_ROOT}/recipes"

red()    { printf '\033[31m%s\033[0m\n' "$*"; }
green()  { printf '\033[32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[33m%s\033[0m\n' "$*"; }

die() { red "error: $*" >&2; exit 1; }

list_recipes() {
  find "$RECIPES_DIR" -type f -path '*/.ddev/config.yaml' \
    | sed "s|^${RECIPES_DIR}/||;s|/.ddev/config.yaml\$||" \
    | sort
}

if [ "${1:-}" = "--list" ]; then
  list_recipes
  exit 0
fi

if [ "${1:-}" = "--json" ]; then
  list_recipes | python3 -c 'import json, sys; print(json.dumps([line.strip() for line in sys.stdin if line.strip()]))'
  exit 0
fi

[ "$#" -eq 1 ] || die "usage: $(basename "$0") --list | --json | <recipe-dir>"

RECIPE_ARG="$1"

if [ -f "${RECIPE_ARG}/.ddev/config.yaml" ]; then
  SRC="$(cd "$RECIPE_ARG" && pwd)"
elif [ -f "${RECIPES_DIR}/${RECIPE_ARG}/.ddev/config.yaml" ]; then
  SRC="${RECIPES_DIR}/${RECIPE_ARG}"
else
  die "no .ddev/config.yaml under '${RECIPE_ARG}' (tried recipes/${RECIPE_ARG} too)"
fi

command -v ddev >/dev/null 2>&1 || die "ddev is not on PATH"

# Non-interactive so mkcert / router prompts cannot hang CI.
export DDEV_NONINTERACTIVE=true

SCRATCH=""
cleanup() {
  if [ -n "${SCRATCH}" ] && [ -d "${SCRATCH}/.ddev" ]; then
    (cd "$SCRATCH" && ddev delete -Oy) || true
  fi
  if [ -n "${SCRATCH}" ] && [ -d "${SCRATCH}" ]; then
    rm -rf "$SCRATCH"
  fi
}
trap cleanup EXIT

SCRATCH="$(mktemp -d "${TMPDIR:-/tmp}/ddev-boot-XXXXXX")"
echo "==> scratch ${SCRATCH}"
echo "==> recipe  ${SRC#"$REPO_ROOT"/}"

cp -a "${SRC}/.ddev" "${SCRATCH}/"

# Docroot so nginx has something to serve. ddev start does not need Drupal.
mkdir -p "${SCRATCH}/web"
printf '%s\n' '<?php echo "ok";' > "${SCRATCH}/web/index.php"

# Decoupled mounts ../frontend from .ddev/; copy it if the recipe ships one.
if [ -d "${SRC}/frontend" ]; then
  cp -a "${SRC}/frontend" "${SCRATCH}/"
fi

# Scratch-only override. Not committed; not copied back into the recipe.
cat > "${SCRATCH}/.ddev/config.ci.yaml" <<'YAML'
# Forced by scripts/boot-recipe.sh for Linux CI / local smoke.
# Recipes keep performance_mode: mutagen for macOS contributors.
performance_mode: none
# Heavy sidecars (OpenSearch, Solr, Chromium) can exceed the 120s default
# on a cold image pull + first healthcheck.
default_container_timeout: "240"
YAML

cd "$SCRATCH"

# Fail fast on a broken compose override before pulling images when possible.
if ddev help utility >/dev/null 2>&1; then
  echo "==> ddev utility compose-config"
  ddev utility compose-config >/dev/null
elif ddev help debug >/dev/null 2>&1; then
  echo "==> ddev debug compose-config"
  ddev debug compose-config >/dev/null
else
  yellow "neither 'ddev utility' nor 'ddev debug' available — skipping compose-config"
fi

echo "==> ddev start"
ddev start

echo "==> ddev status / describe"
ddev status

echo "==> asserting every container is running"
ddev describe --json-output | python3 -c '
import json, sys

text = sys.stdin.read()
candidates = []
try:
    candidates.append(json.loads(text))
except json.JSONDecodeError:
    for line in text.splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            candidates.append(json.loads(line))
        except json.JSONDecodeError:
            continue

raw = None
for obj in reversed(candidates):
    if not isinstance(obj, dict):
        continue
    if "raw" in obj and isinstance(obj["raw"], dict):
        raw = obj["raw"]
        break
    if "status" in obj and "services" in obj:
        raw = obj
        break

if raw is None:
    print("could not parse ddev describe --json-output", file=sys.stderr)
    sys.stderr.write(text[:2000])
    sys.exit(1)

status = raw.get("status")
if status != "running":
    print(f"project status is {status!r}, expected running", file=sys.stderr)
    sys.exit(1)

services = raw.get("services") or {}
if not services:
    print("ddev describe reported no services", file=sys.stderr)
    sys.exit(1)

# xhgui is a built-in DDEV service that stays stopped unless `ddev xhgui on`.
# describe still lists it. Ignore that; fail on any other non-running service
# (recipe sidecars such as solr/chrome/opensearch must actually come up).
optional_stopped = {"xhgui"}

bad = []
checked = []
for name, svc in sorted(services.items()):
    st = svc.get("status")
    if name in optional_stopped and st == "stopped":
        continue
    checked.append(name)
    if st != "running":
        bad.append(f"{name}={st}")

if "web" not in services or services["web"].get("status") != "running":
    bad.append("web missing or not running")

if bad:
    print("services not running: " + ", ".join(bad), file=sys.stderr)
    sys.exit(1)

print("checked running: " + ", ".join(checked))
'

# Extra proof the web container answers exec (covers a "running" but wedged web).
ddev exec -- php -r 'echo "web-ok\n";'

green "boot OK: ${SRC#"$REPO_ROOT"/}"
