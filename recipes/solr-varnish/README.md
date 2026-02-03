# Solr + Varnish recipe

A "production-shaped" local stack: Apache Solr 9 in front of Drupal's
`search_api`, and Varnish 7.5 in front of the whole site for HTTP caching
and tag-based purges.

## When to use this

- The project relies on faceted search at scale (Solr is much happier with
  faceting + relevance than the DB backend).
- You're tuning cache headers, `BigPipe`, or page cache tag invalidation and
  want a real Varnish in the loop, not just the internal Drupal page cache.
- You need to reproduce production behaviour that depends on
  `X-Drupal-Cache-Tags` invalidation working end-to-end.

## Performance expectations on local hardware

Rough numbers, M-series Mac, warm cache, anonymous traffic:

| Layer                      | Median TTFB | p95 TTFB |
|----------------------------|-------------|----------|
| Drupal alone (page cache)  | 30-50 ms    | 90 ms    |
| + Varnish HIT              | 1-3 ms      | 5 ms     |
| + Varnish MISS (no Solr)   | 60-90 ms    | 180 ms   |

Solr on cold cache adds 20-40 ms to facet-heavy listings; on warm cache it
disappears below DB query overhead.

## Install

```bash
cp -r recipes/solr-varnish/.ddev /path/to/project/
cd /path/to/project
ddev restart
ddev composer require drupal/search_api drupal/search_api_solr
ddev drush en search_api search_api_solr -y
```

Then see [`setup.md`](setup.md) for the Drupal-side wiring.

## Services exposed

| Service | URL                                                    |
|---------|--------------------------------------------------------|
| Solr admin | `http://solr.<project>.ddev.site:8983/solr/`        |
| Varnish    | `http://varnish.<project>.ddev.site:6081/`         |

The DDEV router still serves Drupal directly on the project hostname —
Varnish is exposed separately so you can A/B test "with cache" vs "without".

## Cache invalidation

The VCL accepts `BAN` requests from inside the Docker network. Drupal's
`purge` + `varnish_purger` modules send a `BAN` with an
`X-Invalidate-Tag` header per cache tag. The VCL strips that header before
hitting the backend so it never leaks to clients.

## Reindexing

```bash
ddev solr-reindex                # full reindex of every search_api index
ddev solr-reindex --index=node   # reindex one specific index
```
