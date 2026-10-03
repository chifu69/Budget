#!/usr/bin/env bash
set -euo pipefail

echo "== Budget Local / Cloudflare build =="
echo "Python: $(python3 --version)"
echo "Node: $(node --version)"
echo "Corepack: $(corepack --version)"

rm -rf actual-budget-local
python3 BUDGET_LOCAL_IPHONE.py --dest actual-budget-local

echo "== Verifying Actual core module =="
UTIL_FILE="actual-budget-local/packages/loot-core/src/shared/util.ts"
test -s "$UTIL_FILE"
grep -q "export function amountToInteger" "$UTIL_FILE"
grep -q "export function last" "$UTIL_FILE"
echo "util.ts OK: $(wc -c < "$UTIL_FILE") bytes"

cd actual-budget-local

echo "== Yarn through Corepack =="
corepack yarn --version

echo "== Installing dependencies =="
corepack yarn install --immutable

echo "== Typecheck =="
echo "Skipping full monorepo typecheck on Cloudflare."
echo "GitHub Actions already performs the authoritative typecheck for this exact commit."

echo "== Building browser PWA =="
corepack yarn build:browser --skip-translations

BUILD_DIR="packages/desktop-client/build"

echo "== Preparing Cloudflare SPA routing =="
# Actual Budget ships a Netlify-style catch-all _redirects rule:
#   /* /index.html 200
# Cloudflare Workers Static Assets rejects that rule as an infinite loop.
# We use Wrangler's native SPA fallback instead (not_found_handling).
rm -f "$BUILD_DIR/_redirects"

echo "== Verifying production files =="
test -f "$BUILD_DIR/index.html"
test -f "$BUILD_DIR/_headers"
test -f "$BUILD_DIR/site.webmanifest"
test -f "$BUILD_DIR/ocr/tesseract.min.js"
test -f "$BUILD_DIR/ocr/worker.min.js"
test -f "$BUILD_DIR/ai/transformers.min.js"
test ! -f "$BUILD_DIR/_redirects"

grep -q "Cross-Origin-Opener-Policy: same-origin" "$BUILD_DIR/_headers"
grep -q "Cross-Origin-Embedder-Policy: require-corp" "$BUILD_DIR/_headers"

echo "== READY FOR CLOUDFLARE =="
echo "Assets: actual-budget-local/packages/desktop-client/build"
echo "SPA fallback: wrangler.jsonc -> not_found_handling=single-page-application"
