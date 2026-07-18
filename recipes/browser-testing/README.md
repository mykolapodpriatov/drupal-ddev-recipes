# Browser / E2E testing recipe

Runs Drupal's browser-driven tests locally: PHPUnit `FunctionalJavascript`
(WebDriver) tests and Nightwatch, backed by a headless Chromium in a Selenium
sidecar. This closes the main gap in the local test story — functional tests
that need a real browser rather than the DB-only Kernel/Unit suites.

## When to use this

- You write `FunctionalJavascript` (`WebDriverTestBase`) tests that click,
  wait for AJAX, or assert on JS-rendered DOM.
- You maintain Nightwatch E2E tests and want them running against the same
  local site.
- You want to reproduce a CI browser-test failure locally, watching the
  browser live over noVNC.

## When *not* to use this

- Your suite is only Unit + Kernel + (non-JS) Functional tests — those need no
  browser, so skip the extra Selenium container.

## How it works

`docker-compose.chrome.yaml` adds a `selenium/standalone-chromium` service
(multi-arch, so it runs natively on Apple Silicon). On the shared DDEV network
it is reachable as:

| Endpoint        | URL                          | Notes                              |
|-----------------|------------------------------|------------------------------------|
| WebDriver       | `http://chrome:4444/wd/hub`  | what Mink / Nightwatch talk to     |
| noVNC live view | `http://chrome:7900`         | watch the browser (password `secret`) |

`config.yaml` sets the test env vars the runner reads —
`SIMPLETEST_BASE_URL=http://web` (the browser is in the `chrome` container, so
the base URL must be the web container's network name, **not** localhost),
`SIMPLETEST_DB`, `BROWSERTEST_OUTPUT_DIRECTORY`, plus the `DRUPAL_TEST_*`
mirrors Nightwatch uses.

## Install

```bash
cp -r recipes/browser-testing/.ddev /path/to/project/
cd /path/to/project
ddev restart
```

Drupal core already ships the PHPUnit + Nightwatch tooling; no extra Composer
requirement is needed for core browser tests.

## Running tests

The bundled command exports `MINK_DRIVER_ARGS_WEBDRIVER` (pointing Mink at the
`chrome` sidecar) and runs PHPUnit:

```bash
# FunctionalJavascript (browser) testsuite — the default:
ddev run-functional

# Narrow to a module or a single test:
ddev run-functional web/core/modules/system/tests/src/FunctionalJavascript

# Reuse the runner for the non-JS functional testsuite:
ddev run-functional --testsuite=functional
```

`MINK_DRIVER_ARGS_WEBDRIVER` is a JSON array of
`[driver, desiredCapabilities, wdHost]`; the command sets Chromium headless
with `--no-sandbox` so it works inside the container.

Nightwatch reads the `DRUPAL_TEST_*` env vars directly:

```bash
ddev exec "cd web/core && yarn test:nightwatch"
```

## Watching a test run

Open `http://chrome.<project>.ddev.site:7900` (or the port DDEV prints in
`ddev describe`), enter the password `secret`, and you will see the headless
browser drive through the test in real time — invaluable when a
`waitForElement` assertion is flaky.

## Artifacts on failure

Failed `BrowserTestBase` runs dump the page HTML and a screenshot under
`web/sites/simpletest/browser_output/` (created automatically by the command).
Open the HTML file to see exactly what the browser saw when the assertion
failed.
