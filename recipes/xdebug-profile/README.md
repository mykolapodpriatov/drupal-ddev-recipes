# Xdebug profile mode recipe

Xdebug has two modes people confuse all the time:

| Mode    | Use case                                          |
|---------|---------------------------------------------------|
| `debug` | Step-debugging in your IDE. Stops execution. **Slow**. |
| `profile` | Generates cachegrind files for *post-mortem* performance analysis. No step-debugging. **Slower per request, but the data is gold.** |

This recipe configures Xdebug in **profile** mode, triggered per-request,
so your normal browsing doesn't generate a flood of profiles.

## When to profile

- A page is suspiciously slow and you don't know which hook / service /
  query is responsible.
- You're shaving milliseconds off a hot path (cache warm requests, API
  endpoints, batch ops).
- `webprofiler` / Symfony profiler isn't granular enough.

## How to read a profile

You need a cachegrind viewer. Recommended:

- **macOS**: `brew install qcachegrind` (the cleanest UI)
- **Linux**: `apt install kcachegrind` (same author, same UX)
- **Windows**: `WinCacheGrind` (older but works)
- **Cross-platform**: [`webgrind`](https://github.com/jokkedk/webgrind) — runs
  in the browser, no install.

Open the cachegrind file, sort by "Self" or "Inclusive" time, drill into the
slowest callees. For Drupal, you're usually looking at:

- `Drupal\Core\Database\Connection::query` aggregating to >50% — DB problem.
- `drupal_render` / `_theme` heavy — render cache misses.
- `Twig\Environment::render` heavy on uncached output — template work.

## Install

```bash
cp -r recipes/xdebug-profile/.ddev /path/to/project/
cd /path/to/project
ddev profile-start    # switches to profile mode and restarts
```

Then make a request **with** the trigger:

```bash
# Either:
curl -H 'XDEBUG_TRIGGER: 1' https://<project>.ddev.site/some/slow/page
# Or visit with a browser extension that sets the cookie:
#   "Xdebug helper" / "Xdebug Profiler" Chrome/Firefox extension.
```

Profile files appear in `/tmp/cachegrind/` inside the web container. They're
also mounted to the host at `./.ddev/cachegrind/` so you can open them
directly.

```bash
ddev profile-open     # opens the latest cachegrind file with qcachegrind
ddev profile-stop     # switches back to default mode
```

## Why "trigger" mode and not "always"

Without the trigger, **every** request — including AJAX, every CSS file,
every cron run — produces a cachegrind file. After 30 seconds you have a
gigabyte of cachegrind files and you can't find the one you wanted.

`xdebug.start_with_request=trigger` means: only profile when the request
carries `XDEBUG_TRIGGER` as a GET/POST param, cookie, or HTTP header.

## Caveats

- Profile mode adds **~3-10x** overhead per request. Never enable on a
  shared environment.
- `cachegrind.out.<pid>.<timestamp>` files can be 5-50 MB each. Clear them
  occasionally: `rm -f .ddev/cachegrind/cachegrind.out.*`.
- Profile mode and debug mode can coexist (`xdebug.mode=debug,profile`) but
  it's rarely what you want — pick one job per session.
