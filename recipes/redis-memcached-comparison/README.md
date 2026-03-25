# Redis vs Memcached comparison recipe

Two parallel DDEV setups so you can A/B Drupal's cache backends without
guessing. Same Drupal 11 codebase, swap the `.ddev/` directory, restart,
re-run your bench.

## When to use which

| Need                                              | Pick                |
|---------------------------------------------------|---------------------|
| Pure cache, no persistence, lowest possible latency on small values | **Memcached** |
| Cache + queue + lock + flood + session store in one box             | **Redis**     |
| Multi-server, want to avoid LB stickiness                           | **Redis** (replication)  |
| Tag invalidation via `cache.backend.chainedfast`                    | Either — both contribs support it |
| You already run Redis for the queue / session                       | **Redis** (one fewer service) |

In rough numbers on warm cache, anonymous Drupal 11:

- Memcached: ~0.05-0.10 ms per cache item GET
- Redis (Unix socket): ~0.08-0.15 ms per GET
- Redis (TCP, no pipeline): ~0.15-0.25 ms per GET

For most sites, the difference is dwarfed by render and DB time. Pick on
operational fit, not micro-benchmarks.

## How to use

```bash
# Option A: Redis stack
cp -r recipes/redis-memcached-comparison/with-redis/.ddev /path/to/project/
cd /path/to/project
ddev restart
ddev composer require drupal/redis
ddev drush en redis -y
# then copy the settings.php snippet below into web/sites/default/settings.php
```

```bash
# Option B: Memcached stack
cp -r recipes/redis-memcached-comparison/with-memcached/.ddev /path/to/project/
cd /path/to/project
ddev restart
ddev composer require drupal/memcache
ddev drush en memcache -y
# then copy the settings.php snippet below into web/sites/default/settings.php
```

You can switch between them by deleting `.ddev/` and copying the other
recipe in.

## settings.php — Redis

```php
// web/sites/default/settings.php

if (extension_loaded('redis') && getenv('IS_DDEV_PROJECT')) {
  $settings['redis.connection']['interface']   = 'PhpRedis';
  $settings['redis.connection']['host']        = 'redis';
  $settings['redis.connection']['port']        = 6379;
  $settings['redis.connection']['persistent']  = TRUE;

  $settings['cache']['default']                = 'cache.backend.redis';
  $settings['cache_prefix']                    = 'drupal_' . getenv('DDEV_SITENAME');

  // Use chained-fast to keep an APCu layer in front of Redis on hot keys.
  $settings['cache']['bins']['bootstrap']      = 'cache.backend.chainedfast';
  $settings['cache']['bins']['config']         = 'cache.backend.chainedfast';
  $settings['cache']['bins']['discovery']      = 'cache.backend.chainedfast';

  // Pipe queue and lock through Redis too — saves a service.
  $settings['queue_default']                   = 'queue.redis';
  $settings['lock']                            = 'lock.redis';
  $settings['flood']                           = 'flood.redis';
}
```

## settings.php — Memcached

```php
// web/sites/default/settings.php

if (extension_loaded('memcached') && getenv('IS_DDEV_PROJECT')) {
  $settings['memcache']['servers']             = ['memcached:11211' => 'default'];
  $settings['memcache']['bins']                = ['default' => 'default'];
  $settings['memcache']['key_prefix']          = 'drupal_' . getenv('DDEV_SITENAME');

  $settings['cache']['default']                = 'cache.backend.memcache';

  $settings['cache']['bins']['bootstrap']      = 'cache.backend.chainedfast';
  $settings['cache']['bins']['config']         = 'cache.backend.chainedfast';
  $settings['cache']['bins']['discovery']      = 'cache.backend.chainedfast';
}
```

## Benching

Same hardware, same code, same DB. Warm cache (5 requests then measure):

```bash
ab -n 500 -c 10 -H 'Accept-Encoding: gzip' \
  https://<project>.ddev.site/
```

Look at the `mean` row, not `min`. Differences of <5 ms are noise.
