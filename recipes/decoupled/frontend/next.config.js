/**
 * Next.js config for the decoupled Drupal recipe.
 *
 * - `NEXT_PUBLIC_DRUPAL_BASE_URL` is the public URL of Drupal as seen by the
 *   browser (used for `<Link>` rewrites and client-side fetches).
 * - `NEXT_INTERNAL_DRUPAL_URL` is the in-cluster URL Next.js uses for SSR
 *   fetches — `http://web` resolves to the Drupal container directly,
 *   skipping the router + TLS for speed.
 */

/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  poweredByHeader: false,
  experimental: {
    serverActions: { allowedOrigins: ['*.ddev.site'] },
  },
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: '*.ddev.site',
      },
    ],
  },
  env: {
    DRUPAL_BASE_URL:
      process.env.NEXT_PUBLIC_DRUPAL_BASE_URL ||
      'https://api.drupal-decoupled.ddev.site',
    DRUPAL_INTERNAL_URL:
      process.env.NEXT_INTERNAL_DRUPAL_URL || 'http://web',
  },
};

module.exports = nextConfig;
