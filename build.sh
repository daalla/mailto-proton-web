#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="Mailto Proton Web"
EXEC_NAME="MailtoProtonWeb"
DIST="$ROOT/dist/${APP_NAME}.app"
CONTENTS="$DIST/Contents"
MACOS="$CONTENTS/MacOS"

rm -rf "$ROOT/dist"
mkdir -p "$MACOS"

SDK="$(xcrun --show-sdk-path)"
ARCH="$(uname -m)"
TARGET="${ARCH}-apple-macos13"

echo "Building for $TARGET (SDK: $SDK)"
swiftc -swift-version 5 -O \
  -sdk "$SDK" \
  -target "$TARGET" \
  -framework AppKit \
  -o "$MACOS/$EXEC_NAME" \
  "$ROOT"/Sources/*.swift

cp "$ROOT/Info.plist" "$CONTENTS/Info.plist"
printf 'APPL????' > "$CONTENTS/PkgInfo"

codesign --force --deep -s - "$DIST"
echo "Signed (ad-hoc): $DIST"

if [[ "${1:-}" == "install" ]]; then
  DEST="${HOME}/Applications/${APP_NAME}.app"
  mkdir -p "${HOME}/Applications"
  rm -rf "$DEST"
  cp -R "$DIST" "$DEST"
  xattr -dr com.apple.quarantine "$DEST" 2>/dev/null || true
  LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
  if [[ -x "$LSREGISTER" ]]; then
    "$LSREGISTER" -f "$DEST"
  fi
  echo "Installed at $DEST"
fi
