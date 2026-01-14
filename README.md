# Drupal DDEV Recipes

A curated collection of [DDEV](https://ddev.com/) recipes for the Drupal
scenarios that actually come up in client work: multisite, decoupled,
Solr + Varnish, Xdebug profiling, mail testing, and Redis vs Memcached.

Each recipe is a drop-in `.ddev/` directory. No frameworks, no abstractions —
copy it into your project, run `ddev restart`, you're done.

## Requirements

| Tool   | Version |
|--------|---------|
| DDEV   | `^1.23` |
| Docker | Any provider supported by DDEV (Docker Desktop, Colima, OrbStack, Rancher Desktop) |
| PHP    | `8.3+` (provided by the DDEV web container) |
| Drupal | `11.x` primary, `10.3+` supported where noted |

## Recipes

| Recipe | What it does |
|--------|--------------|
| [`multisite`](recipes/multisite/) | Two Drupal sites on one codebase with separate DBs and hostnames. |
| [`decoupled`](recipes/decoupled/) | Drupal 11 backend + Next.js 14 frontend, JSON:API, CORS, preview mode. |
| [`solr-varnish`](recipes/solr-varnish/) | Solr 9 + Varnish 7.5 in front of Drupal with a production-style VCL. |
| [`xdebug-profile`](recipes/xdebug-profile/) | Xdebug in **profile** mode (not debug) for cachegrind analysis. |
| [`mailpit`](recipes/mailpit/) | DDEV's built-in Mailpit wired to `symfony_mailer` for transactional email testing. |
| [`redis-memcached-comparison`](recipes/redis-memcached-comparison/) | Side-by-side Redis and Memcached setups with Drupal `settings.php` snippets. |

## How to use a recipe

```bash
# From the root of your Drupal project:
cp -r path/to/drupal-ddev-recipes/recipes/<name>/.ddev/ .
# Then either start fresh or reload the existing project:
ddev restart
```

If the recipe ships extra files outside `.ddev/` (e.g. `sites.php.example`
for multisite, or a `frontend/` skeleton for decoupled), each recipe's README
explains where they go.

## Validation

Before pushing changes, run:

```bash
./scripts/validate-recipes.sh
```

It runs `yamllint` on every YAML file under `recipes/` and checks that each
recipe has the required structure (`README.md`, `.ddev/config.yaml`). CI runs
the same script on every PR.

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md). New recipes welcome — keep them
copy-paste runnable.

## License

MIT — see [`LICENSE`](LICENSE).
