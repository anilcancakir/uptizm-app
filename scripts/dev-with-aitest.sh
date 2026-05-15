#!/usr/bin/env bash
# dev-with-aitest.sh
#
# Boots Flutter web in DEBUG mode with the V2 ai-test plugin active and the
# Dart VM Service exposed for the ai_test_node MCP server to connect to.
#
# Combined surface:
#   - Flutter app on http://127.0.0.1:3100
#   - Dart VM Service on ws://127.0.0.1:8181/ws (auth disabled for local dev)
#   - Native Flutter Semantics tree mounted in light DOM (Playwright getByRole works)
#   - window.__aiTestReady === true after first frame
#   - ext.aitest.getRoutes registered (callable via VM Service JSON-RPC)
#
# Usage:
#   ./scripts/dev-with-aitest.sh
#
# Once running, in another terminal connect Playwright:
#   cd references/playwright-cli
#   npx playwright test --headed
#
# And/or attach the MCP server (Claude Desktop / Cursor MCP config):
#   { "mcpServers": { "ai-test": { "command": "npx", "args": ["tsx", "<abs path>/references/ai-test/packages/ai_test_node/src/index.ts"] } } }
#
# Replaces the V0/V1 PHP-served-build flow (php -S :3100 -t build/web) for
# ai-test-driven sessions. The PHP flow stays available for non-aitest debug.

set -euo pipefail
cd "$(dirname "$0")/.."
exec flutter run -d chrome \
  --web-port=3100 \
  --vm-service-port=8181 \
  --disable-service-auth-codes \
  --dart-define=AI_TEST=1
