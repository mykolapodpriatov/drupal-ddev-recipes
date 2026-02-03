vcl 4.1;

# Drupal-friendly Varnish 7+ VCL.
#
# Goals:
#   - Cache anonymous traffic aggressively.
#   - Bypass cache for logged-in users (Drupal session cookie present).
#   - Accept tag-based purges from the Drupal "purge" + "varnish_purger" modules
#     via BAN requests carrying X-Invalidate-Tag.
#   - Strip Drupal's X-Drupal-Cache-Tags header from client responses.
#
# import directors / std unused here to keep the file lean; uncomment if you
# add multiple backends.

backend default {
    .host = "web";
    .port = "80";
    .connect_timeout = 5s;
    .first_byte_timeout = 60s;
    .between_bytes_timeout = 30s;
}

# Hosts allowed to issue BAN / PURGE requests. The DDEV docker network is RFC1918.
acl invalidators {
    "localhost";
    "127.0.0.1";
    "172.16.0.0"/12;
    "10.0.0.0"/8;
    "192.168.0.0"/16;
}

sub vcl_recv {
    # Tag-based invalidation from Drupal purge module.
    if (req.method == "BAN") {
        if (!client.ip ~ invalidators) {
            return (synth(403, "BAN not allowed from this IP."));
        }
        if (req.http.X-Invalidate-Tag) {
            ban("obj.http.X-Drupal-Cache-Tags ~ " + req.http.X-Invalidate-Tag);
            return (synth(200, "Ban added for tag " + req.http.X-Invalidate-Tag));
        }
        return (synth(400, "Missing X-Invalidate-Tag header."));
    }

    # URL purge.
    if (req.method == "PURGE") {
        if (!client.ip ~ invalidators) {
            return (synth(403, "PURGE not allowed."));
        }
        return (purge);
    }

    # Pass non-idempotent methods straight through.
    if (req.method != "GET" && req.method != "HEAD") {
        return (pass);
    }

    # Logged-in users (Drupal session) and form-token-bearing requests bypass.
    if (req.http.Cookie ~ "(SESS[a-z0-9]+|SSESS[a-z0-9]+|NO_CACHE)") {
        return (pass);
    }

    # Don't cache admin / user / batch / install / update.
    if (req.url ~ "^/(admin|user|batch|core/install\.php|update\.php|cron)") {
        return (pass);
    }

    # Drop everything cookie-related from incoming requests once we're sure
    # this is an anonymous request — otherwise Varnish keys per-cookie and
    # the hit ratio collapses.
    unset req.http.Cookie;
}

sub vcl_backend_response {
    # Honour Drupal's Cache-Control: max-age — already set correctly by the
    # internal page cache module. Provide a fallback of 60s for public pages
    # if the backend didn't set anything explicit.
    if (beresp.ttl <= 0s) {
        set beresp.ttl = 60s;
    }

    # Keep the response 6h after TTL for `grace` mode (stale-while-revalidate).
    set beresp.grace = 6h;

    # Don't cache responses Drupal explicitly marked uncacheable.
    if (beresp.http.Cache-Control ~ "no-cache|no-store|private") {
        set beresp.uncacheable = true;
        set beresp.ttl = 0s;
        return (deliver);
    }

    # Don't cache 5xx — let the backend stop bleeding.
    if (beresp.status >= 500) {
        set beresp.uncacheable = true;
        set beresp.ttl = 0s;
        return (deliver);
    }
}

sub vcl_deliver {
    # Hide internal headers from clients.
    unset resp.http.X-Drupal-Cache-Tags;
    unset resp.http.X-Drupal-Dynamic-Cache;
    unset resp.http.X-Varnish;
    unset resp.http.Via;

    # Useful HIT/MISS debug header — toggle off in real prod.
    if (obj.hits > 0) {
        set resp.http.X-Cache = "HIT";
        set resp.http.X-Cache-Hits = obj.hits;
    } else {
        set resp.http.X-Cache = "MISS";
    }
}
