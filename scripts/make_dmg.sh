#!/bin/bash
# Builds Yamaha Controller in Release and packages it as a DMG.
# Usage: ./scripts/make_dmg.sh
# Output: dist/Yamaha Controller.dmg

set -euo pipefail

APP_NAME="Yamaha Controller"
BUNDLE_ID="com.yamaha-controller"
SCHEME="YamahaController"
PROJECT="YamahaController.xcodeproj"
BUILD_DIR="$(pwd)/build"
DIST_DIR="$(pwd)/dist"
DMG_STAGING="$(pwd)/build/dmg_staging"
DMG_PATH="${DIST_DIR}/${APP_NAME}.dmg"

# ── 0. Clean previous artifacts ──────────────────────────────────────────────
rm -rf "${BUILD_DIR}" "${DIST_DIR}"
mkdir -p "${BUILD_DIR}" "${DIST_DIR}" "${DMG_STAGING}"

echo "▸ Building ${APP_NAME} (Release)…"

# ── 1. Build ──────────────────────────────────────────────────────────────────
xcodebuild \
  -project "${PROJECT}" \
  -scheme "${SCHEME}" \
  -configuration Release \
  -derivedDataPath "${BUILD_DIR}/DerivedData" \
  -archivePath "${BUILD_DIR}/${APP_NAME}.xcarchive" \
  archive \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  | xcpretty 2>/dev/null || true

# Fallback: run again without xcpretty if it's not installed
if [ ! -d "${BUILD_DIR}/${APP_NAME}.xcarchive" ]; then
  xcodebuild \
    -project "${PROJECT}" \
    -scheme "${SCHEME}" \
    -configuration Release \
    -derivedDataPath "${BUILD_DIR}/DerivedData" \
    -archivePath "${BUILD_DIR}/${APP_NAME}.xcarchive" \
    archive \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO
fi

APP_PATH="${BUILD_DIR}/${APP_NAME}.xcarchive/Products/Applications/${APP_NAME}.app"

if [ ! -d "${APP_PATH}" ]; then
  echo "✗ Build failed — .app not found at ${APP_PATH}"
  exit 1
fi

echo "✓ Build succeeded: ${APP_PATH}"

# ── 2. Stage DMG contents ─────────────────────────────────────────────────────
cp -R "${APP_PATH}" "${DMG_STAGING}/"
ln -s /Applications "${DMG_STAGING}/Applications"

# ── 3. Create writable image, set layout, convert to compressed read-only ─────
echo "▸ Creating DMG…"

TEMP_DMG="${BUILD_DIR}/temp.dmg"
VOLUME_NAME="${APP_NAME}"

# Create writable temp image
hdiutil create \
  -volname "${VOLUME_NAME}" \
  -srcfolder "${DMG_STAGING}" \
  -ov \
  -format UDRW \
  "${TEMP_DMG}"

# Mount the writable image
MOUNT_DIR=$(hdiutil attach "${TEMP_DMG}" -readwrite -noverify -noautoopen | \
  grep -E '^/dev/' | tail -n1 | awk '{print $NF}')

echo "  Mounted at: ${MOUNT_DIR}"

# Set icon positions and background using AppleScript
osascript <<APPLESCRIPT
tell application "Finder"
  tell disk "${VOLUME_NAME}"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set bounds of container window to {400, 100, 920, 440}
    set viewOptions to the icon view options of container window
    set arrangement of viewOptions to not arranged
    set icon size of viewOptions to 100
    set position of item "${APP_NAME}.app" of container window to {130, 170}
    set position of item "Applications" of container window to {390, 170}
    update without registering applications
    delay 1
    close
  end tell
end tell
APPLESCRIPT

# Allow Finder to settle
sync
hdiutil detach "${MOUNT_DIR}" -quiet

# Convert to compressed read-only DMG
hdiutil convert "${TEMP_DMG}" \
  -format UDZO \
  -imagekey zlib-level=9 \
  -o "${DMG_PATH}"

rm -f "${TEMP_DMG}"

echo "✓ DMG created: ${DMG_PATH}"
echo "  Size: $(du -sh "${DMG_PATH}" | cut -f1)"
