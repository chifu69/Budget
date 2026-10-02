# Budget Local v0.1.0 modifications

Base: Actual Budget v26.10.0.

1. New `SmartAdd.tsx` screen.
2. New `smartAddParser.ts` deterministic text/receipt parser.
3. `/smart-add` route.
4. `/smart-review/:transactionId` route that reuses Actual's existing `TransactionEdit` even on wide layouts.
5. Mobile Transaction tab is replaced with Smart Add.
6. Desktop sidebar gains Smart Add.
7. Bank Sync navigation entries are hidden; implementation/routes remain upstream.
8. PWA manifest/title becomes Budget Local.
9. Workbox precache pattern includes `.gz` so local OCR language data can be cached.
10. OCR assets are pinned to Tesseract.js 6.0.1 / core 6.1.2 and local English trained data.

No database schema is modified in this version.
No Actual financial formulas are modified in this version.
No direct OCR-to-database write path is added.
