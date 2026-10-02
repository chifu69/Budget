# Budget Local v0.1.0 — iPhone Flat Pack

Esta edición está hecha específicamente para subirla desde iPhone. **Todos los archivos del ZIP están en la raíz; no hay carpetas que tengas que subir.**

Base: Actual Budget v26.10.0 (MIT).

## Qué hace

`BUDGET_LOCAL_IPHONE.py` descarga la versión oficial fijada de Actual Budget, crea la estructura completa automáticamente y aplica nuestras modificaciones:

- Smart Add por texto.
- Cámara/galería para recibos.
- OCR local con Tesseract.js, sin OpenAI ni OCR pagado.
- Revisión en el formulario normal de Actual antes de guardar.
- Bank Sync oculto de la navegación, sin borrar el motor upstream.
- PWA renombrada inicialmente como Budget Local.
- Mantiene budgets, cuentas, transacciones, schedules, reportes y motor financiero de Actual.

## Importante: GitHub Actions

GitHub solo reconoce workflows dentro de `.github/workflows/`. iPhone puede dificultar subir carpetas, así que este pack evita subirlas. Después de subir los archivos de este ZIP a la raíz del repositorio, crea **un solo archivo desde GitHub**:

1. Toca **Add file → Create new file**.
2. En el nombre escribe exactamente: `.github/workflows/build-budget-local.yml`
3. Abre `WORKFLOW_BUILD_BUDGET_LOCAL.yml.txt`, copia todo su contenido y pégalo allí.
4. Commit changes.
5. Ve a **Actions → Build Budget Local → Run workflow**.

No tienes que crear ni subir ninguna carpeta manualmente: al escribir ese nombre con `/`, GitHub crea la ruta por ti.

Al terminar el Action tendrás dos artifacts:

- `Budget-Local-Source-v0.1.0` — código fuente completo modificado.
- `Budget-Local-PWA-v0.1.0` — build web/PWA.

## Privacidad y costo

Smart Add no necesita OpenAI, Firebase, Supabase ni un OCR de pago. El OCR se descarga durante la construcción y luego se sirve desde la propia PWA. El recibo se procesa en el navegador.

## Hosting

Actual usa `SharedArrayBuffer`, por lo que la PWA necesita HTTPS y encabezados COOP/COEP. GitHub sirve muy bien para código y Actions, pero GitHub Pages no es la opción recomendada para ejecutar esta PWA porque no permite controlar esos headers como necesita Actual.

## Archivos de este pack

Todos están en la raíz:

- `BUDGET_LOCAL_IPHONE.py` — instalador/modificador completo en un solo archivo.
- `WORKFLOW_BUILD_BUDGET_LOCAL.yml.txt` — contenido del único workflow que debes crear desde GitHub.
- `README.md` — estas instrucciones.
- `LICENSE-UPSTREAM.txt` — licencia MIT de Actual Budget.
- `THIRD-PARTY-NOTICES.md` — avisos de Actual/Tesseract.
- `MODIFICATIONS.md` — resumen de nuestras modificaciones.
- `UPSTREAM_VERSION` — versión de Actual fijada.

## Seguridad del proceso

El script verifica que la versión descargada sea exactamente Actual Budget 26.10.0. Si cambia la estructura esperada, se detiene en lugar de adivinar.
