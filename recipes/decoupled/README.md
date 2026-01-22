# Decoupled (Drupal + Next.js) recipe

Drupal 11 as a headless content API, Next.js 14 as the frontend, both running
under a single DDEV project. Two ways to access them:

- **Two hostnames** (default in this recipe): `https://api.<project>.ddev.site`
  serves Drupal, `https://<project>.ddev.site` serves Next.js.
- **One hostname, reverse-proxied**: nginx routes `/api/*`, `/jsonapi/*`,
  `/sites/default/files/*` and `/user/login` to Drupal, everything else to
  Next.js. The `nginx_full/nginx-site.conf` in this recipe ships ready for
  that mode — comment out `additional_hostnames` to use it.

## Architecture

```
                      ┌───────────────────┐
   Browser ──────────►│ DDEV router (TLS) │
                      └─────────┬─────────┘
                                │
              ┌─────────────────┼─────────────────┐
              ▼                                   ▼
     ┌────────────────────┐              ┌────────────────────┐
     │  web (nginx + PHP) │              │  nextjs (node:20)  │
     │  Drupal 11         │◄────fetch────│  Next.js 14 SSR    │
     │  /jsonapi          │   JSON:API   │  app/ router       │
     │  /api/*            │              │  ISR + on-demand   │
     └────────┬───────────┘              │  revalidation      │
              │                          └────────────────────┘
              ▼
       ┌──────────────┐
       │ MariaDB 10.11│
       └──────────────┘
```

## Install

```bash
cp -r recipes/decoupled/.ddev /path/to/project/
cp -r recipes/decoupled/frontend /path/to/project/   # Next.js skeleton
cd /path/to/project
ddev restart
ddev next-dev    # starts Next.js in dev mode on port 3000
```

URLs after `ddev restart`:

- Drupal: `https://api.<project>.ddev.site` (and `https://<project>.ddev.site`)
- Next.js (in dev): `https://next.<project>.ddev.site:3000`

## CORS

Drupal's `services.yml` ships CORS disabled by default. For decoupled work,
either install the [CORS module](https://www.drupal.org/project/cors) or set
in `web/sites/default/services.yml`:

```yaml
cors.config:
  enabled: true
  allowedHeaders: ['x-csrf-token', 'authorization', 'content-type', 'accept', 'origin', 'x-requested-with']
  allowedMethods: ['*']
  allowedOrigins: ['https://*.ddev.site']
  exposedHeaders: false
  maxAge: 1000
  supportsCredentials: true
```

## Preview mode

The official integration is [`next` module + `next-drupal`](https://next-drupal.org/).
This recipe assumes you'll install them on the Drupal side and consume
`/next/preview` from the Next.js side. The frontend env var
`NEXT_PUBLIC_DRUPAL_BASE_URL` (set in `frontend/.env.example`) points the SDK
at the Drupal API.

## Commands

| Command           | What it does                                          |
|-------------------|-------------------------------------------------------|
| `ddev next-dev`   | Starts Next.js dev server on port 3000.              |
| `ddev next-build` | Production build inside the `nextjs` container.       |
| `ddev next-start` | (optional) Run the production build.                 |
