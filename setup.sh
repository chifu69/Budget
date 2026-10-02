#!/usr/bin/env bash
set -euo pipefail

DEST="${1:-actual-budget-local}"
python3 scripts/bootstrap.py --dest "$DEST"

cat <<MSG

Budget Local está preparado en: $DEST

Para instalar y probar:
  cd "$DEST"
  corepack enable
  yarn install --immutable
  yarn start

Para crear el PWA de producción:
  yarn build:browser
MSG
