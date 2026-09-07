# Brand fonts

This folder holds the bundled TTFs so the app renders its typography **offline**
and makes no runtime network request for fonts.

Populate it once, from the repo root:

```bash
bash tools/fetch_fonts.sh
```

Expected files:

| Family | Weights | Used for |
|---|---|---|
| Sora | 400, 600, 700 | headings, titles, numbers |
| Inter | 400, 500, 600, 700 | body text, lists, UI labels |
| JetBrains Mono | 400, 500 | part codes, battery numbers, SKUs |

All three are SIL Open Font License 1.1. `OFL.txt` is written by the script and
must ship with the app.

If the folder is empty the app still runs — `google_fonts` falls back to the
platform font — but the premium type scale will not match the design.
