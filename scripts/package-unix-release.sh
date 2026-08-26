#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "usage: $0 <binary-name> <archive-name>" >&2
  exit 1
fi

binary_name="$1"
archive_name="$2"
dist_dir="dist/bin"
binary_path="$dist_dir/$binary_name"
archive_path="$dist_dir/$archive_name"

if [ ! -f "$binary_path" ]; then
  echo "missing binary: $binary_path" >&2
  exit 1
fi

staging_dir="$(mktemp -d "${TMPDIR:-/tmp}/codex-acp-release.XXXXXX")"
cleanup() {
  rm -rf "$staging_dir"
}
trap cleanup EXIT

cp "$binary_path" "$staging_dir/$binary_name"
chmod 0755 "$staging_dir/$binary_name"

cat >"$staging_dir/codex-acp" <<EOF
#!/usr/bin/env bash
set -euo pipefail

CODEX_PATH="\${CODEX_PATH:-}"
if [[ -z "\$CODEX_PATH" ]]; then
  CODEX_PATH="\$(command -v codex || true)"
fi

if [[ -z "\$CODEX_PATH" ]]; then
  echo "Could not find the Codex executable." >&2
  echo "Set CODEX_PATH or add codex to PATH." >&2
  echo "Example: CODEX_PATH=/path/to/codex \$0 [arguments]" >&2
  exit 2
fi

if [[ ! -x "\$CODEX_PATH" ]]; then
  echo "CODEX_PATH is not an executable file: \$CODEX_PATH" >&2
  exit 2
fi

script_path="\${BASH_SOURCE[0]}"
while [[ -L "\$script_path" ]]; do
  script_dir="\$(cd -- "\$(dirname -- "\$script_path")" && pwd -P)"
  script_path="\$(readlink -- "\$script_path")"
  [[ "\$script_path" != /* ]] && script_path="\$script_dir/\$script_path"
done
script_dir="\$(cd -- "\$(dirname -- "\$script_path")" && pwd -P)"
exec env CODEX_PATH="\$CODEX_PATH" "\$script_dir/$binary_name" "\$@"
EOF

chmod 0755 "$staging_dir/codex-acp"
rm -f "$archive_path"
(cd "$staging_dir" && zip -q "$OLDPWD/$archive_path" codex-acp "$binary_name")
