#!/usr/bin/env bash
# Downloads the three brand fonts into assets/google_fonts/ so the app renders
# them offline and never makes a network call at runtime.
#
#   bash tools/fetch_fonts.sh
#
# The `google_fonts` package looks in that asset folder first and only falls
# back to the network (or the platform font) if a file is missing, which keeps
# the Play Data Safety form free of any "downloads at runtime" caveat.
set -euo pipefail

cd "$(dirname "$0")/.."
DEST="assets/google_fonts"
mkdir -p "$DEST"

# family:weight:filename — filenames MUST match what google_fonts expects,
# i.e. "<Family>-<Weight>.ttf" with the family name exactly as on fonts.google.com.
FILES=(
  "Sora:400:Sora-Regular.ttf"
  "Sora:600:Sora-SemiBold.ttf"
  "Sora:700:Sora-Bold.ttf"
  "Inter:400:Inter-Regular.ttf"
  "Inter:500:Inter-Medium.ttf"
  "Inter:600:Inter-SemiBold.ttf"
  "Inter:700:Inter-Bold.ttf"
  "JetBrainsMono:400:JetBrainsMono-Regular.ttf"
  "JetBrainsMono:500:JetBrainsMono-Medium.ttf"
)

# Static TTFs straight from the upstream Google Fonts repository.
base_url() {
  case "$1" in
    Sora)          echo "https://raw.githubusercontent.com/google/fonts/main/ofl/sora/static" ;;
    Inter)         echo "https://raw.githubusercontent.com/google/fonts/main/ofl/inter/static" ;;
    JetBrainsMono) echo "https://raw.githubusercontent.com/google/fonts/main/ofl/jetbrainsmono/static" ;;
    *) echo "" ;;
  esac
}

for spec in "${FILES[@]}"; do
  family="${spec%%:*}"
  file="${spec##*:}"
  url="$(base_url "$family")/$file"
  if [[ -s "$DEST/$file" ]]; then
    echo "have    $file"
    continue
  fi
  echo "fetch   $file"
  curl -fsSL "$url" -o "$DEST/$file" || {
    echo "WARNING: could not download $file — the app will fall back to the" >&2
    echo "         platform font for that weight." >&2
    rm -f "$DEST/$file"
  }
done

# Licences must ship with the fonts (all three are SIL OFL 1.1).
cat > "$DEST/OFL.txt" <<'LICENSE'
The fonts in this directory (Sora, Inter, JetBrains Mono) are licensed under
the SIL Open Font License, Version 1.1.

Full licence text: https://scripts.sil.org/OFL

Sora           (c) The Sora Project Authors
Inter          (c) The Inter Project Authors
JetBrains Mono (c) The JetBrains Mono Project Authors
LICENSE

echo
echo "Done. Files in $DEST:"
ls -1 "$DEST"
echo
echo "Now run: flutter pub get && flutter run"
