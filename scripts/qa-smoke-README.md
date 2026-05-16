# qa-smoke.sh

End-to-end MCP-driven smoke script for the Uptizm web app. Exercises the
critical path: login, create monitor, add metric, seed incident, verify
dashboard, navigate to incident drawer, delete monitor, verify cleanup.

## Prerequisites

| Requirement | How to satisfy |
|---|---|
| **uptizm-app running** | `dart run ai_test_flutter:ai_test_flutter start` from the uptizm-app directory |
| **uptizm-api running** | `php artisan serve` from the uptizm-api directory (port 8000) |
| **ai-test session active** | State file must exist at `~/.ai-test/state.json` with a valid `vmServiceUri` |
| **jq >= 1.6** | `brew install jq` (macOS) or `apt-get install jq` (Linux) |
| **node >= 22** | `nvm install 22` or download from nodejs.org |

The test user `aispike@example.com` (password `password`) must be seeded.
The script seeds this user automatically via `php artisan tinker` if not present.

## Usage

```bash
bash scripts/qa-smoke.sh
```

Or, after the full Wave 4 pipeline:

```bash
dart run ai_test_flutter:ai_test_flutter start
bash scripts/qa-smoke.sh
dart run ai_test_flutter:ai_test_flutter stop
```

## Exit codes

| Code | Meaning |
|---|---|
| `0` | All phases passed. |
| `1` | Phase-level failure. Diagnostic is printed to stderr before exit. |
| `2` | Prerequisite missing (jq, node, state file, api unreachable). |

On any non-zero exit the cleanup trap fires automatically: it force-deletes
the smoke monitor and incident from the database so no test data is left behind.

## Phases

| # | Phase | What it does |
|---|---|---|
| 0 | Prerequisite checks | Validates jq, node >= 22, state file, api reachable |
| 1 | Verify session | Confirms `~/.ai-test/state.json` has a valid VM URI |
| 2 | Seed user | Creates `aispike@example.com` via tinker if absent |
| 3 | Login | Navigates `/auth/login`, types credentials, taps Sign In |
| 4 | Create monitor | Navigates `/monitors/create`, fills form, submits, captures UUID |
| 5 | Add metric | Taps Metrics tab, selects Cache hit preset, adds metric |
| 6 | Seed incident | Seeds a `critical/detected/manual` incident via tinker |
| 7 | Dashboard verification | Navigates `/`, checks incidents section visible |
| 8 | Incident drawer | Taps Incidents tab on monitor detail, opens seeded incident |
| 9 | Delete monitor | Edit page, taps Delete Monitor, confirms dialog |
| 10 | Verify cleanup | Checks monitor soft-deleted in DB; audits orphan children |

## Caveats

### DEFECT-18: orphan children after monitor soft-delete

When a monitor is soft-deleted, its `MonitorMetric` and `Incident` child rows
are NOT automatically cascaded. Phase 10 reports the orphan count as a warning
but does NOT fail the smoke, because the cascade fix is out of scope for this
readiness pass.

### DEFECT-1: tap envelope on navigation-triggering taps

Navigation taps (e.g. "Sign In" redirecting to dashboard) previously returned
a JSON-RPC `Server error` envelope because the post-dispatch UI rebuild unmounted
the tapped element. Step 5 of the production-readiness pass (D1 fix) resolves
this by returning OK immediately after pointer dispatch. If the smoke runs against
a pre-D1 build, Phase 3 tap errors will be logged but the script attempts to
continue (the navigation may still succeed).

### MCP client single-call model

`scripts/qa-smoke-mcp-client.mjs` spawns a fresh MCP server process per tool
call. This is intentionally simple and avoids session-state complexity at the
cost of startup latency (~200ms per call). For multi-hour agent sessions, prefer
a persistent MCP server connection via the Claude MCP integration.

### node_modules for the MCP server

The client resolves `tsx` from the ai_test_node `node_modules` directory
(`references/ai-test/packages/ai_test_node/node_modules/.bin/tsx`). Run
`bun install` or `npm install` in that directory if the binary is missing.
