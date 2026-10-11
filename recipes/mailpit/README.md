# Mailpit recipe

DDEV ships with [Mailpit](https://mailpit.axllent.org/) built in since
`v1.22`. From `v1.23` (the floor this repo supports) Mailpit is a process
inside the web container. SMTP is `127.0.0.1:1025`. The UI is on `:8025`.

This recipe doesn't add Mailpit (it's already there), it covers the
**Drupal-side** wiring you actually need: making sure Symfony Mailer talks
to the right host, and making sure transactional emails (password reset,
order confirmations, webform submissions) actually leave the application.

## Accessing the Mailpit UI

After `ddev start`:

```
https://<project>.ddev.site:8026
```

DDEV exposes 8025 (HTTP) and 8026 (HTTPS) by default.

You can also pop it open from the CLI:

```bash
ddev launch -m            # or: ddev launch mailpit
```

## Install

```bash
cp -r recipes/mailpit/.ddev /path/to/project/
cd /path/to/project
ddev restart
ddev composer require drupal/symfony_mailer
ddev drush en symfony_mailer -y
```

Then either:

- Import the bundled `symfony_mailer.mailer_transport.smtp.yml` from this
  recipe's `config/sync/` into your project's config sync directory, OR
- Manually create an SMTP transport at
  `/admin/config/system/mailer/transport` with:
  - Host: `localhost`
  - Port: `1025`
  - Encryption: `none`
  - Auth: off

## Verifying delivery

Trigger a password reset from `/user/password` and check the Mailpit UI.
You should see the message land within a second, with full headers and
both plain-text + HTML parts.

If nothing shows up:

```bash
# From inside the web container, send a raw test:
ddev exec 'echo "Test mail body" | mail -s "Test" you@example.com'

# Mailpit is not its own service, so `ddev logs -s mailpit` has nothing
# to follow. Open the UI above to see the captured message.
```

## Symfony Mailer vs the old core Mail interface

For Drupal 10.3+ and 11.x, **always use `symfony_mailer`** — the core
`MailManager` is in long-term maintenance only. `symfony_mailer` gives you:

- Real SMTP, Amazon SES, Postmark transports without contrib helpers.
- Templated emails as Twig (per-message override-able by theme).
- DSN-based transport config (`smtp://127.0.0.1:1025`), the same shape in dev and prod.

## Why mail.ini

`.ddev/php/mail.ini` keeps PHP's `sendmail_path` on
`/usr/local/bin/mailpit sendmail`, aimed at `127.0.0.1:1025`. That is the
command the DDEV 1.23 web image already uses. The image does not ship
`mhsendmail`, and the hostname `mailpit` does not resolve, so either of
those overrides makes `mail()` fail. This still covers modules that call
`mail()` directly.
