#!/bin/bash
# Builds a universal (Apple Silicon + Intel) NotchKit.app and packages it as a DMG.
#
# Usage: scripts/build-release.sh [version]
#   version   Marketing version to stamp into the app, e.g. 1.2.0.
#             Defaults to the version in project.yml.
#
# Environment:
#   BUILD_NUMBER  CFBundleVersion to stamp into the app (default: 1)
#
# Requires: Xcode 26 or later, xcodegen, create-dmg (brew install xcodegen create-dmg)
#
# The app is ad-hoc signed. It is not notarized, so on first launch macOS asks the
# user to allow it in System Settings > Privacy & Security.
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$(pwd)"
BUILD_DIR="$ROOT/build/release"
DERIVED="$BUILD_DIR/DerivedData"
APP="$DERIVED/Build/Products/Release/NotchKit.app"

for tool in xcodegen create-dmg; do
  command -v "$tool" >/dev/null || { echo "error: $tool is required (brew install $tool)"; exit 1; }
done

echo "==> Generating Xcode project"
xcodegen generate --quiet

echo "==> Building universal Release app"
rm -rf "$DERIVED"
mkdir -p "$BUILD_DIR"
xcodebuild \
  -project NotchKit.xcodeproj \
  -scheme NotchKit \
  -configuration Release \
  -destination "generic/platform=macOS" \
  -derivedDataPath "$DERIVED" \
  ARCHS="arm64 x86_64" \
  ONLY_ACTIVE_ARCH=NO \
  CODE_SIGN_IDENTITY="-" \
  build > "$BUILD_DIR/xcodebuild.log" 2>&1 || {
    grep -E "error:" "$BUILD_DIR/xcodebuild.log" | sort -u
    echo "error: xcodebuild failed, see $BUILD_DIR/xcodebuild.log"
    exit 1
  }
grep -E "BUILD SUCCEEDED" "$BUILD_DIR/xcodebuild.log"

VERSION="${1:-$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP/Contents/Info.plist")}"
BUILD_NUMBER="${BUILD_NUMBER:-1}"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "$APP/Contents/Info.plist"

echo "==> Signing (ad-hoc)"
for framework in MediaRemoteAdapter NotchKitMediaQueue; do
  codesign --force --sign - "$APP/Contents/Resources/$framework.framework"
done
codesign --force --sign - --entitlements App/NotchKit.entitlements "$APP"
codesign --verify --deep --strict "$APP"

echo "==> Checking architectures"
for binary in "$APP/Contents/MacOS/NotchKit" \
  "$APP/Contents/Resources/MediaRemoteAdapter.framework/MediaRemoteAdapter" \
  "$APP/Contents/Resources/NotchKitMediaQueue.framework/NotchKitMediaQueue"; do
  archs="$(lipo -archs "$binary")"
  echo "    $(basename "$binary"): $archs"
  [[ "$archs" == *arm64* && "$archs" == *x86_64* ]] || { echo "error: $binary is not universal"; exit 1; }
done

echo "==> Creating DMG"
DMG="$BUILD_DIR/NotchKit-$VERSION.dmg"
STAGING="$BUILD_DIR/dmg"
rm -rf "$STAGING" "$DMG"
mkdir -p "$STAGING"
cp -R "$APP" "$STAGING/"

create-dmg \
  --volname "NotchKit $VERSION" \
  --volicon "$APP/Contents/Resources/AppIcon.icns" \
  --window-pos 200 120 \
  --window-size 560 340 \
  --icon-size 120 \
  --icon "NotchKit.app" 150 160 \
  --hide-extension "NotchKit.app" \
  --app-drop-link 410 160 \
  --no-internet-enable \
  "$DMG" "$STAGING" >/dev/null

rm -rf "$STAGING"
(cd "$BUILD_DIR" && shasum -a 256 "$(basename "$DMG")" | tee "$(basename "$DMG").sha256")
echo "==> Done: $DMG"
