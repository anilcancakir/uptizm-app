#!/usr/bin/env bash
# Flavor-aware Flutter web build. Copies the matching .env flavor into the
# asset slot .env reads, then builds release output into build/web/.
#
# Usage:
#   scripts/build-web.sh dev    # reads .env.dev, points app at dev-app.uptizm.com
#   scripts/build-web.sh prod   # reads .env.prod, points app at app.uptizm.com
set -euo pipefail

flavor="${1:-prod}"
case "$flavor" in
  dev|prod) ;;
  *) echo "usage: $0 {dev|prod}" >&2; exit 2 ;;
esac

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
src="$root/.env.$flavor"
dst="$root/.env"

[[ -f "$src" ]] || { echo "missing $src" >&2; exit 1; }

cp "$src" "$dst"
cd "$root"

flutter clean
flutter pub get
flutter build web --release --base-href=/

echo "built $flavor -> $root/build/web"
