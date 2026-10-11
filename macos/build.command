#!/bin/zsh
set -euo pipefail
cd "${0:A:h}"
APP="ChatCount.app"
mkdir -p "$APP/Contents/MacOS"
BUILD_CACHE="${TMPDIR:-/tmp}/chatcount-module-cache"
BUILD_SDK="${CHATCOUNT_BUILD_SDK:-$(xcrun --show-sdk-path)}"
for ARCH in arm64 x86_64; do
    xcrun swiftc -O -sdk "$BUILD_SDK" -module-cache-path "$BUILD_CACHE" -target "$ARCH-apple-macosx13.0" Source/Analysis.swift Source/Localization.swift Source/App.swift -o "$APP/Contents/MacOS/ChatCount-$ARCH"
done
xcrun lipo -create "$APP/Contents/MacOS/ChatCount-arm64" "$APP/Contents/MacOS/ChatCount-x86_64" -output "$APP/Contents/MacOS/ChatCount"
rm "$APP/Contents/MacOS/ChatCount-arm64" "$APP/Contents/MacOS/ChatCount-x86_64"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>ChatCount</string>
<key>CFBundleIdentifier</key><string>local.chatcount.app</string>
<key>CFBundleName</key><string>ChatCount</string>
<key>CFBundleDisplayName</key><string>ChatCount</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>1.0.0</string>
<key>CFBundleVersion</key><string>3</string>
<key>LSMinimumSystemVersion</key><string>13.0</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
xattr -cr "$APP"
codesign --force --sign - "$APP"
echo "Готово: $APP"
