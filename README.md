# Budget Local v0.1.0

Personal-finance PWA based on **Actual Budget v26.10.0**, with a first local-only Smart Add layer.

## What this pack does

This repository is intentionally small. It is pinned to the official Actual Budget `v26.10.0` source release and applies only our changes on top of it. That keeps the financial engine close to upstream and makes future Actual fixes much easier to merge.

The bootstrap creates a full modified source tree named `actual-budget-local`.

### Changes in v0.1.0

- Adds **Smart Add** to the mobile navigation.
- Adds **Smart Add** to the desktop sidebar.
- Text entry, for example: `Walmart 84.72 category: Groceries account: Checking`.
- Camera/photo receipt capture using the phone's normal web camera picker.
- Local OCR with Tesseract.js. Receipt images are processed in the browser.
- Extracts a likely merchant, date and total from a receipt.
- Opens Actual's existing transaction editor for final review before saving.
- Keeps Actual's financial/database logic as the source of truth.
- Hides Bank Sync from the normal navigation without deleting the upstream implementation.
- Renames the installable PWA to **Budget Local**.
- Adds the OCR language file to the PWA precache so the scanner can work after installation/offline caching.

### Not used by Smart Add

- No OpenAI API.
- No voice service.
- No Firebase.
- No Supabase.
- No paid OCR API.
- No monthly AI service required.

Actual's optional sync-server code remains in the upstream source. Local-only use does not require that server.

## Easiest path: GitHub Actions

1. Create a new empty GitHub repository.
2. Upload the contents of this ZIP to the repository root.
3. Open **Actions** → **Build Budget Local** → **Run workflow**.
4. The workflow downloads the official Actual Budget v26.10.0 source, applies the modification, tests the parser, type-checks Actual and builds the browser PWA.
5. Download either artifact:
   - `Budget-Local-Source-v0.1.0` — full modified source.
   - `Budget-Local-PWA-v0.1.0` — production web/PWA build.

This is also why the ZIP you received is much smaller than the complete Actual Budget monorepo: the exact upstream source is fetched from the official release during the reproducible build instead of duplicating hundreds of megabytes in this customization repository.

## Mac / Linux local setup

Requirements: Git is optional for the bootstrap, Python 3, Node 22.18+ and Corepack.

```bash
chmod +x setup.sh
./setup.sh
cd actual-budget-local
corepack enable
yarn install --immutable
yarn start
```

Production build:

```bash
yarn build:browser --skip-translations
```

The output is under:

```text
packages/desktop-client/build/
```

## Windows

Run PowerShell:

```powershell
./SETUP-WINDOWS.ps1
```

For Actual's Unix-oriented root build scripts, use Git Bash or WSL after the bootstrap.

## Hosting the PWA

Actual's browser database uses `SharedArrayBuffer`. Production hosting therefore needs HTTPS plus these headers:

```text
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: require-corp
```

Actual already ships `packages/desktop-client/public/_headers`, and this mod preserves it. Static hosts that honor `_headers` are a good fit. Plain GitHub Pages is not recommended for the running PWA because it does not give the project control over these required response headers.

GitHub is still ideal for the **source code and Actions build**.

## Smart Add examples

```text
Walmart 84.72
Kroger 52.19 category: Groceries
KUB 167.34 account: Checking
income Payroll 1250.00 account: Checking
Target 43.20 today
```

For a receipt, tap **📷 Escanear recibo**. The first scan may take longer while the local OCR engine initializes. No receipt image is intentionally uploaded by the Smart Add code.

## Safety design

Smart Add never writes a parsed OCR result straight into the ledger. It converts the result into Actual's existing new-transaction form, where the amount, merchant, account, category and date can be checked before saving. The Actual transaction engine then performs the normal save.

## Version lock

This pack intentionally checks for Actual Budget **26.10.0** before applying changes. If upstream changes file structure later, the script stops instead of guessing and potentially damaging the project.

## Files

- `scripts/bootstrap.py` — downloads the pinned upstream source and applies the mod.
- `scripts/apply_mod.py` — deterministic source modifications.
- `scripts/download_ocr_assets.py` — downloads version-pinned OCR runtime assets for local serving.
- `scripts/test_parser.mjs` — parser smoke tests.
- `overlay/` — new Smart Add source files.
- `.github/workflows/build-budget-local.yml` — reproducible GitHub build.
- `LICENSE-UPSTREAM.txt` — Actual Budget MIT notice.
- `THIRD-PARTY-NOTICES.md` — OCR/upstream notices.

## Next changes, intentionally not done yet

This first build avoids ripping out large parts of Actual. Bank Sync is hidden instead of deleted, and the sync-server packages remain intact. After this version runs cleanly on iPhone and desktop, unused pieces can be removed one by one with regression testing.
