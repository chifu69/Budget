# Third-party notices

Budget Local v0.1.0 is a customization layer for **Actual Budget v26.10.0**.
Actual Budget is licensed under the MIT License. The upstream notice is preserved in `LICENSE-UPSTREAM.txt`, and the complete upstream source keeps its own license files after bootstrap.

The local receipt scanner uses **Tesseract.js 6.0.1** and **tesseract.js-core 6.1.2**, distributed under their upstream open-source licenses. English trained data is pinned to `@tesseract.js-data/eng@1.0.0`. The bootstrap downloads these version-pinned assets over HTTPS into the PWA's own `/public/ocr` directory so the scanner does not depend on a remote OCR service at runtime.

Upstream projects:
- Actual Budget: https://github.com/actualbudget/actual
- Tesseract.js: https://github.com/naptha/tesseract.js
- Tesseract.js Core: https://github.com/naptha/tesseract.js-core
- Tesseract language data: https://github.com/naptha/tessdata
