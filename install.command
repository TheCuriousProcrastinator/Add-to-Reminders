#!/bin/zsh
set -e

ROOT="$(cd "$(dirname "$0")" && pwd)"
HELPER="$ROOT/mac-helper"

HOST_NAME="com.alex.addtoreminders"
EXTENSION_ID="fdkkbdcnkigfhiabomhklbfapojbpdol"

INSTALL_ROOT="$HOME/Library/Application Support/AddToReminders"
APP="$INSTALL_ROOT/AddToRemindersHost.app"

NATIVE_HOST_DIR="$HOME/Library/Application Support/Google/Chrome/NativeMessagingHosts"
NATIVE_HOST_MANIFEST="$NATIVE_HOST_DIR/$HOST_NAME.json"

echo
echo "Add to Reminders installer"
echo "=========================="
echo

mkdir -p "$HELPER/bin"

cd "$HELPER"

echo "Building native helper..."

rm -f RichReminder.o

clang \
  -fobjc-arc \
  -O \
  -c RichReminder.m \
  -o RichReminder.o \
  -F/System/Library/PrivateFrameworks

xcrun swiftc \
  main.swift \
  RichReminder.o \
  -o bin/add-to-reminders-host \
  -framework EventKit \
  -framework Foundation \
  -framework AppKit \
  -F/System/Library/PrivateFrameworks \
  -framework ReminderKit \
  -lsqlite3 \
  -Xlinker -sectcreate \
  -Xlinker __TEXT \
  -Xlinker __info_plist \
  -Xlinker "$HELPER/Info.plist"

codesign \
  --force \
  --sign - \
  --identifier com.alex.addtoreminders.host \
  bin/add-to-reminders-host

echo "Building host app..."

rm -rf "$APP"

mkdir -p \
  "$APP/Contents/MacOS"

cp \
  bin/add-to-reminders-host \
  "$APP/Contents/MacOS/add-to-reminders-host"

chmod +x \
  "$APP/Contents/MacOS/add-to-reminders-host"

cp \
  Info.plist \
  "$APP/Contents/Info.plist"

PLIST="$APP/Contents/Info.plist"

for key in \
  CFBundleIdentifier \
  CFBundleName \
  CFBundleDisplayName \
  CFBundleExecutable \
  CFBundlePackageType \
  CFBundleVersion \
  CFBundleShortVersionString \
  LSUIElement
do
  /usr/libexec/PlistBuddy \
    -c "Delete :$key" \
    "$PLIST" \
    2>/dev/null || true
done

/usr/libexec/PlistBuddy \
  -c "Add :CFBundleIdentifier string com.alex.addtoreminders.host" \
  "$PLIST"

/usr/libexec/PlistBuddy \
  -c "Add :CFBundleName string AddToRemindersHost" \
  "$PLIST"

/usr/libexec/PlistBuddy \
  -c "Add :CFBundleDisplayName string Add to Reminders Host" \
  "$PLIST"

/usr/libexec/PlistBuddy \
  -c "Add :CFBundleExecutable string add-to-reminders-host" \
  "$PLIST"

/usr/libexec/PlistBuddy \
  -c "Add :CFBundlePackageType string APPL" \
  "$PLIST"

/usr/libexec/PlistBuddy \
  -c "Add :CFBundleVersion string 1" \
  "$PLIST"

/usr/libexec/PlistBuddy \
  -c "Add :CFBundleShortVersionString string 1.0" \
  "$PLIST"

/usr/libexec/PlistBuddy \
  -c "Add :LSUIElement bool true" \
  "$PLIST"

codesign \
  --force \
  --deep \
  --sign - \
  "$APP"

echo "Installing Chrome native-messaging manifest..."

mkdir -p "$NATIVE_HOST_DIR"

cat > "$NATIVE_HOST_MANIFEST" <<JSON
{
  "name": "$HOST_NAME",
  "description": "Add websites from Chrome to Apple Reminders",
  "path": "$APP/Contents/MacOS/add-to-reminders-host",
  "type": "stdio",
  "allowed_origins": [
    "chrome-extension://$EXTENSION_ID/"
  ]
}
JSON

echo
echo "Installed:"
echo "$APP"
echo
echo "Native host:"
echo "$NATIVE_HOST_MANIFEST"
echo
echo "NEXT MANUAL STEP"
echo "----------------"
echo "1. Open System Settings > Privacy & Security > Full Disk Access"
echo "2. Add:"
echo "   $APP"
echo "3. Turn it ON"
echo
echo "Then load this folder as an unpacked Chrome extension:"
echo "   $ROOT/chrome-extension"
echo
echo "Expected extension ID:"
echo "   $EXTENSION_ID"
echo
echo "Installation complete."
