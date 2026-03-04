# Mailpit recipe

DDEV ships with [Mailpit](https://mailpit.axllent.org/) built in since
`v1.22`. PHP's `mail()` and any `sendmail`-style transport in the web
container is auto-routed to Mailpit at `mailpit:1025` (SMTP) / `:8025` (UI).

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
  - Host: `mailpit`
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

# Then tail Mailpit logs:
ddev logs -s mailpit
```

## Symfony Mailer vs the old core Mail interface

For Drupal 10.3+ and 11.x, **always use `symfony_mailer`** — the core
`MailManager` is in long-term maintenance only. `symfony_mailer` gives you:

- Real SMTP, Amazon SES, Postmark transports without contrib helpers.
- Templated emails as Twig (per-message override-able by theme).
- DSN-based transport config (`smtp://mailpit:1025`) — same format dev/prod.

## Why mail.ini

`.ddev/php/mail.ini` forces PHP's `sendmail_path` to the container's
mhsendmail binary, which speaks SMTP to Mailpit. This catches the rare
modules that still call `mail()` directly (some old contrib + custom code).
Without it, those emails are silently dropped.
