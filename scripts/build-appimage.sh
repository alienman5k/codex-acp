#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 3 ]; then
  echo "usage: $0 <binary-path> <appimagetool-path> <output-path>" >&2
  exit 1
fi

binary_path="$1"
appimagetool_path="$2"
output_path="$3"

appdir="$(mktemp -d "${TMPDIR:-/tmp}/codex-acp-appdir.XXXXXX")/CodexACP.AppDir"
mkdir -p "$appdir/usr/bin"

cp "$binary_path" "$appdir/usr/bin/codex-acp"
chmod 0755 "$appdir/usr/bin/codex-acp"

cat >"$appdir/AppRun" <<'EOF'
#!/bin/sh
HERE="$(dirname "$(readlink -f "$0")")"
exec "$HERE/usr/bin/codex-acp" "$@"
EOF
chmod 0755 "$appdir/AppRun"

cat >"$appdir/codex-acp.desktop" <<'EOF'
[Desktop Entry]
Name=codex-acp
Exec=codex-acp
Icon=codex-acp
Type=Application
Categories=Development;
Terminal=true
EOF

base64 -d >"$appdir/codex-acp.png" <<'EOF'
iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a
9t8AAAAASUVORK5CYII=
EOF

chmod 0755 "$appimagetool_path"
ARCH=x86_64 "$appimagetool_path" --appimage-extract-and-run "$appdir" "$output_path"
