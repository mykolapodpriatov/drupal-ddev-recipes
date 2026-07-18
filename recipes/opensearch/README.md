# OpenSearch recipe

A single-node [OpenSearch](https://opensearch.org/) 2.x service wired for
Drupal's `search_api`. OpenSearch is the Apache-2.0-licensed fork of
Elasticsearch, so this is a license-clear, Elasticsearch-compatible backend
for full-text search, faceting, and aggregations.

## When to use this

- You want an Elasticsearch-compatible Search API backend without the SSPL
  licensing of Elasticsearch itself.
- Production runs OpenSearch (AWS OpenSearch Service, self-hosted OpenSearch)
  and you want local parity on the search engine.
- You need aggregations / relevance tuning that the database backend and even
  Solr do not express as naturally.

## When *not* to use this

- A small site whose search needs are met by the core database backend — an
  extra JVM service is overhead you do not need.
- Production runs Apache Solr — use the [`solr-varnish`](../solr-varnish/)
  recipe for engine parity instead.

## Security note

The service starts with `DISABLE_SECURITY_PLUGIN=true`, so the node is plain
HTTP on port 9200 with **no authentication and no TLS**. That is deliberate for
local development. Never copy these settings to a production cluster.

## Install

```bash
cp -r recipes/opensearch/.ddev /path/to/project/
cd /path/to/project
ddev restart
ddev composer require drupal/search_api drupal/search_api_opensearch
ddev drush en search_api search_api_opensearch -y
```

The `search_api_opensearch` module pulls in the `opensearch-project/opensearch-php`
client via Composer, so require it through `ddev composer` (not by hand) to keep
the autoloader in sync.

## Service exposed

| Service       | URL from the web container | URL from the host                                  |
|---------------|----------------------------|----------------------------------------------------|
| OpenSearch    | `http://opensearch:9200`   | `http://opensearch.<project>.ddev.site:9200`       |

Quick smoke test once the containers are up:

```bash
ddev exec curl -s http://opensearch:9200/_cluster/health
# {"cluster_name":"docker-cluster","status":"green",...}
```

## Search API server settings

Create the Search API server at `/admin/config/search/search-api/add-server`
(or import the config below) and point it at the sidecar:

| Field    | Value                     |
|----------|---------------------------|
| Backend  | **OpenSearch**            |
| URL      | `http://opensearch:9200`  |

There is no username/password/CA cert to set — the security plugin is off.

Prefer to manage it as config? A minimal
`search_api.server.opensearch.yml` looks like:

```yaml
id: opensearch
name: 'OpenSearch'
backend: opensearch
backend_config:
  connector: standard
  connector_config:
    url: 'http://opensearch:9200'
```

Then add an index against this server, map your fields, and index:

```bash
ddev drush search-api:index
ddev drush search-api:status
```

## Verifying

```bash
ddev exec curl -s http://opensearch:9200            # node info + version 2.x
ddev drush search-api:status                         # index shows "100%"
```
