#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
HELPER_DIR="$ROOT_DIR/mac-helper"
DIST_DIR="$ROOT_DIR/dist"
WORK_DIR="$(mktemp -d /tmp/add-to-reminders-pkg.XXXXXX)"

PKG_ROOT="$WORK_DIR/root"
COMPONENTS="$WORK_DIR/components.plist"
BUILD_DIR="$WORK_DIR/build"

VERSION="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["version"])' "$ROOT_DIR/chrome-extension/manifest.json")"

APP="$PKG_ROOT/Library/Application Support/AddToReminders/AddToRemindersHost.app"
APP_CONTENTS="$APP/Contents"
APP_BIN="$APP_CONTENTS/MacOS/add-to-reminders-host"

NATIVE_DIR="$PKG_ROOT/Library/Google/Chrome/NativeMessagingHosts"
NATIVE_MANIFEST="$NATIVE_DIR/com.alex.addtoreminders.json"

CHROME_TESTING_NATIVE_DIR="$PKG_ROOT/Library/Google/ChromeForTesting/NativeMessagingHosts"
CHROME_TESTING_NATIVE_MANIFEST="$CHROME_TESTING_NATIVE_DIR/com.alex.addtoreminders.json"

PKG="$DIST_DIR/AddToRemindersHelper-$VERSION.pkg"

cleanup() {
    rm -rf "$WORK_DIR"
}
trap cleanup EXIT

mkdir -p "$BUILD_DIR"
mkdir -p "$APP_CONTENTS/MacOS"
mkdir -p "$NATIVE_DIR"
mkdir -p "$CHROME_TESTING_NATIVE_DIR"
mkdir -p "$DIST_DIR"

cp "$HELPER_DIR/Info.plist" "$BUILD_DIR/Info.plist"

PLIST="$BUILD_DIR/Info.plist"

for key in \
    CFBundleIdentifier \
    CFBundleName \
    CFBundleDisplayName \
    CFBundleExecutable \
    CFBundlePackageType \
    CFBundleVersion \
    CFBundleShortVersionString \
    LSUIElement \
    LSMinimumSystemVersion
do
    /usr/libexec/PlistBuddy \
        -c "Delete :$key" \
        "$PLIST" \
        2>/dev/null || true
done

/usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string com.alex.addtoreminders.host" "$PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleName string AddToRemindersHost" "$PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleDisplayName string Add to Reminders Host" "$PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleExecutable string add-to-reminders-host" "$PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundlePackageType string APPL" "$PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleVersion string 1" "$PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string $VERSION" "$PLIST"
/usr/libexec/PlistBuddy -c "Add :LSUIElement bool true" "$PLIST"
/usr/libexec/PlistBuddy -c "Add :LSMinimumSystemVersion string 14.0" "$PLIST"

echo "Building arm64 helper..."

xcrun clang \
    -target arm64-apple-macos14.0 \
    -fobjc-arc \
    -c "$HELPER_DIR/RichLink.m" \
    -o "$BUILD_DIR/RichLink-arm64.o"

xcrun swiftc \
    -target arm64-apple-macos14.0 \
    "$HELPER_DIR/main.swift" \
    "$BUILD_DIR/RichLink-arm64.o" \
    -import-objc-header "$HELPER_DIR/RichLinkBridge.h" \
    -o "$BUILD_DIR/add-to-reminders-host-arm64" \
    -framework EventKit \
    -framework Foundation \
    -Xlinker -sectcreate \
    -Xlinker __TEXT \
    -Xlinker __info_plist \
    -Xlinker "$PLIST"

echo "Building x86_64 helper..."

xcrun clang \
    -target x86_64-apple-macos14.0 \
    -fobjc-arc \
    -c "$HELPER_DIR/RichLink.m" \
    -o "$BUILD_DIR/RichLink-x86_64.o"

xcrun swiftc \
    -target x86_64-apple-macos14.0 \
    "$HELPER_DIR/main.swift" \
    "$BUILD_DIR/RichLink-x86_64.o" \
    -import-objc-header "$HELPER_DIR/RichLinkBridge.h" \
    -o "$BUILD_DIR/add-to-reminders-host-x86_64" \
    -framework EventKit \
    -framework Foundation \
    -Xlinker -sectcreate \
    -Xlinker __TEXT \
    -Xlinker __info_plist \
    -Xlinker "$PLIST"

echo "Creating Universal 2 binary..."

xcrun lipo \
    -create \
    "$BUILD_DIR/add-to-reminders-host-arm64" \
    "$BUILD_DIR/add-to-reminders-host-x86_64" \
    -output "$APP_BIN"

chmod 755 "$APP_BIN"
cp "$PLIST" "$APP_CONTENTS/Info.plist"

cat > "$NATIVE_MANIFEST" <<'JSON'
{
  "name": "com.alex.addtoreminders",
  "description": "Add websites from Chrome to Apple Reminders",
  "path": "/Library/Application Support/AddToReminders/AddToRemindersHost.app/Contents/MacOS/add-to-reminders-host",
  "type": "stdio",
  "allowed_origins": [
    "chrome-extension://nofdmceaajfglgpldmibhggabdjgbgnf/"
  ]
}
JSON

chmod 644 "$NATIVE_MANIFEST"
cp "$NATIVE_MANIFEST" "$CHROME_TESTING_NATIVE_MANIFEST"
chmod 644 "$CHROME_TESTING_NATIVE_MANIFEST"

codesign \
    --force \
    --deep \
    --sign - \
    "$APP"

pkgbuild \
    --analyze \
    --root "$PKG_ROOT" \
    "$COMPONENTS"

python3 - "$COMPONENTS" <<'PY'
import plistlib
import sys

path = sys.argv[1]

with open(path, "rb") as f:
    data = plistlib.load(f)

found = False

for component in data:
    bundle = component.get("RootRelativeBundlePath", "")
    if bundle.endswith("AddToRemindersHost.app"):
        component["BundleIsRelocatable"] = False
        component["BundleIsVersionChecked"] = False
        component["BundleOverwriteAction"] = "upgrade"
        found = True

if not found:
    raise SystemExit("AddToRemindersHost.app component not found.")

with open(path, "wb") as f:
    plistlib.dump(data, f)
PY

xattr -cr "$PKG_ROOT"
find "$PKG_ROOT" -name '._*' -delete
find "$PKG_ROOT" -name '.DS_Store' -delete

rm -f "$PKG"

COPYFILE_DISABLE=1 pkgbuild \
    --root "$PKG_ROOT" \
    --component-plist "$COMPONENTS" \
    --identifier com.alex.addtoreminders.helper \
    --version "$VERSION" \
    --install-location / \
    --ownership recommended \
    "$PKG"

echo
echo "Built:"
ls -lh "$PKG"

echo
echo "Architectures:"
file "$APP_BIN"

echo
echo "Metadata check:"
pkgutil --payload-files "$PKG" \
    | grep -E '/\._|\.DS_Store' \
    && exit 1 \
    || echo "OK - no metadata junk"

echo
echo "Package ready:"
echo "$PKG"
