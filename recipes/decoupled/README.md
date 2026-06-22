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

## Configure the frontend env (required)

Unlike the other recipes in this repo, the decoupled recipe is **not** a pure
drop-in: the Next.js frontend needs to know your Drupal hostname, and that
depends on your DDEV project name. Copy `frontend/.env.example` to
`frontend/.env` and set `NEXT_PUBLIC_DRUPAL_BASE_URL` to your real Drupal URL:

```bash
cp frontend/.env.example frontend/.env
# Edit it, or derive the value from DDEV at copy time:
sed -i '' "s#https://api.drupal-decoupled.ddev.site#https://api.$(ddev describe -j | jq -r .raw.name).ddev.site#" frontend/.env
```

The defaults baked into `frontend/.env.example` and `frontend/next.config.js`
assume a project named `drupal-decoupled`; they only work as-is if your DDEV
project happens to have that name. For any other project name you **must**
update `NEXT_PUBLIC_DRUPAL_BASE_URL` to `https://api.<your-project>.ddev.site`
(or set it to whatever hostname serves Drupal in your setup).

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

To serve the production build, run `ddev next-build` and then start it inside
the container with `docker exec -it ddev-${DDEV_SITENAME}-nextjs npm run start`
(the `start` script is in `frontend/package.json`).
