# Solr + Varnish: order of operations

Follow these steps the first time you bring the stack up.

## 1. Boot the stack

```bash
ddev restart
ddev composer require drupal/search_api drupal/search_api_solr drupal/purge drupal/varnish_purger
ddev drush en search_api search_api_solr purge varnish_purger -y
```

## 2. Wire Drupal to Solr

Admin > Configuration > Search and metadata > Search API > Add server.

- **Backend**: Solr
- **Solr connector**: Standard
- **HTTP protocol**: `http`
- **Host**: `solr`           ← the docker service name
- **Port**: `8983`
- **Solr core**: `drupal`
- **solr.install.dir**: leave empty

Press "Save". The status block should now show "Server connection: OK" and
"Configset compatibility: drupal-9 (or newer)".

If "Configset compatibility" complains, click "Get config.zip", unzip it
over `.ddev/solr/cores/drupal/conf/`, and `ddev restart`.

## 3. Create an index

Same page > Add index.

- **Data sources**: Content (or whatever entity type you want indexed)
- **Server**: the one you just created
- Tick the bundles you want to expose
- "Save and add fields", add at least: title, body, status, created

Then run:

```bash
ddev solr-reindex
```

## 4. Wire Drupal to Varnish

Admin > Configuration > Development > Performance > Purge.

- Add purger: **Varnish Purger** (from the `varnish_purger` module)
- Configure the purger:
  - Hostname: `varnish`
  - Port: `6081`
  - Path: `/`
  - Request method: `BAN`
  - Header name: `X-Invalidate-Tag`
  - Header value: `[invalidation:expression]`
- Add processor: **Cache tags queuer**
- Add queue: **Database**

Verify with:

```bash
# Should HIT after the second request.
curl -I http://varnish.<project>.ddev.site:6081/
```

## 5. Smoke test invalidation

Edit a node, save, then re-curl the URL. The `X-Cache` header should flip
back to `MISS` on the first request after save (the tag the node belongs
to got `BAN`-ed).
