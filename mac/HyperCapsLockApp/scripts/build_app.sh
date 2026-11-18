#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$APP_ROOT"

APP_NAME="HyperCapsLock"
BUNDLE_DIR="$APP_ROOT/dist/${APP_NAME}.app"
CONTENTS_DIR="$BUNDLE_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "[1/4] Building release binary..."
swift build -c release

BIN_DIR="$(swift build -c release --show-bin-path)"
BIN_PATH="$BIN_DIR/HyperCapsLockApp"
if [[ ! -f "$BIN_PATH" ]]; then
  echo "Error: Built binary not found at $BIN_PATH" >&2
  exit 1
fi

echo "[2/4] Assembling app bundle..."
rm -rf "$BUNDLE_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
cp "$BIN_PATH" "$MACOS_DIR/HyperCapsLockApp"
cp "$APP_ROOT/Resources/Info.plist" "$CONTENTS_DIR/Info.plist"

echo "[3/4] Generating AppIcon.icns..."
swift "$SCRIPT_DIR/generate_icon.swift" "$RESOURCES_DIR/AppIcon.icns"

echo "[4/4] Signing app bundle..."
IDENTITY_HASH="$(security find-identity -v -p codesigning 2>/dev/null | awk '/Apple Development:/{print $2; exit}')"
if [[ -n "$IDENTITY_HASH" ]]; then
  echo "Signing with Apple Development identity ($IDENTITY_HASH)..."
  codesign --force --deep --sign "$IDENTITY_HASH" "$BUNDLE_DIR"
else
  echo "No Apple Development identity found; using ad-hoc signature..."
  codesign --force --deep --sign - "$BUNDLE_DIR"
fi

codesign --verify --deep --strict "$BUNDLE_DIR"
echo "Done: $BUNDLE_DIR"
