#!/usr/bin/env bash
set -Eeuo pipefail

APP_ROOT="$HOME/KydrasEcho"
OWNER="$(gh api user -q .login 2>/dev/null || echo "${USER}")"
REPO_NAME="KydrasEcho"
VERSION="${VERSION:-v0.1.0}"
PKG_NAME="kydras-echo-${VERSION}-linux-x64"
OUTDIR="$APP_ROOT/.release"
ARCHIVE="$OUTDIR/${PKG_NAME}.tar.gz"

cd "$APP_ROOT"

# Ensure release for tag exists
if ! gh release view "$VERSION" >/dev/null 2>&1; then
  if git ls-remote --tags origin | grep -q "refs/tags/${VERSION}$"; then
    gh release create "$VERSION" -t "Kydras Echo ${VERSION}" -n "Release ${VERSION}"
  else
    gh release create "$VERSION" --target main -t "Kydras Echo ${VERSION}" -n "Release ${VERSION}"
  fi
fi

# Build clean archive
rm -rf "$OUTDIR"; mkdir -p "$OUTDIR"
TMPDIR="$(mktemp -d)"; trap 'rm -rf "$TMPDIR"' EXIT
rsync -a "$APP_ROOT"/ "$TMPDIR/$PKG_NAME"/ \
  --delete \
  --exclude ".git/" --exclude ".github/" --exclude ".venv/" \
  --exclude "__pycache__/" --exclude "node_modules/" \
  --exclude "dist/" --exclude "build/" \
  --exclude "*.log" --exclude "*.pyc"

tar -C "$TMPDIR" -czf "$ARCHIVE" "$PKG_NAME"

# Checksums (+ optional GPG)
( cd "$OUTDIR" && sha256sum "${PKG_NAME}.tar.gz" > "${PKG_NAME}.sha256" )
( cd "$OUTDIR" && sha512sum "${PKG_NAME}.tar.gz" > "${PKG_NAME}.sha512" )
if command -v gpg >/dev/null 2>&1; then
  ( cd "$OUTDIR" && gpg --batch --yes --armor \
      --output "${PKG_NAME}.tar.gz.asc" \
      --detach-sign "${PKG_NAME}.tar.gz" ) || true
fi

# Upload assets
ASSETS=( "$OUTDIR/${PKG_NAME}.tar.gz" "$OUTDIR/${PKG_NAME}.sha256" "$OUTDIR/${PKG_NAME}.sha512" )
[[ -f "$OUTDIR/${PKG_NAME}.tar.gz.asc" ]] && ASSETS+=( "$OUTDIR/${PKG_NAME}.tar.gz.asc" )
gh release upload "$VERSION" "${ASSETS[@]}" --clobber

# Show result
echo
echo "[✓] Release assets now:"
gh release view "$VERSION" --json assets --jq '.assets[].name'
echo
echo "[→] Open release:"
echo "    https://github.com/${OWNER}/${REPO_NAME}/releases/tag/${VERSION}"
echo "[i] Local assets in: $OUTDIR"
