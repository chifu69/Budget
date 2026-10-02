#!/usr/bin/env bash
set -euo pipefail

echo "== Budget Local / Cloudflare Pages build =="
echo "Python: $(python3 --version)"
echo "Node: $(node --version)"

corepack enable

rm -rf actual-budget-local
python3 BUDGET_LOCAL_IPHONE.py --dest actual-budget-local

cd actual-budget-local

echo "== Installing dependencies =="
yarn install --immutable

echo "== Typecheck =="
yarn typecheck

echo "== Building browser PWA =="
yarn build:browser --skip-translations

BUILD_DIR="packages/desktop-client/build"

echo "== Verifying required production files =="
test -f "$BUILD_DIR/index.html"
test -f "$BUILD_DIR/_headers"
test -f "$BUILD_DIR/_redirects"
test -f "$BUILD_DIR/site.webmanifest"
test -f "$BUILD_DIR/ocr/tesseract.min.js"
test -f "$BUILD_DIR/ocr/worker.min.js"

grep -q "Cross-Origin-Opener-Policy: same-origin" "$BUILD_DIR/_headers"
grep -q "Cross-Origin-Embedder-Policy: require-corp" "$BUILD_DIR/_headers"
grep -q "/index.html" "$BUILD_DIR/_redirects"

echo "== READY FOR CLOUDFLARE PAGES =="
echo "Output directory: actual-budget-local/packages/desktop-client/build"
