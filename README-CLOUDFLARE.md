# Budget Local — Cloudflare Pages package

This package keeps the GitHub repository as the source of truth and uses
Cloudflare Pages only as the HTTPS static host.

## Build command

```bash
bash BUILD-CLOUDFLARE.sh
```

## Output directory

```text
actual-budget-local/packages/desktop-client/build
```

The build verifies that Actual Budget's required `_headers`, SPA `_redirects`,
PWA manifest, and local OCR assets are present before it reports success.
