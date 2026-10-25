#!/bin/zsh
# Builds the padcheck CLI and the PadCheck.app bundle into ./build.
set -euo pipefail
cd "${0:A:h}"

mkdir -p build
swiftc -O -swift-version 5 Core/*.swift CLI/main.swift -o build/padcheck

app=build/PadCheck.app
rm -rf "$app"
mkdir -p "$app/Contents/MacOS"
swiftc -O -swift-version 5 -parse-as-library Core/*.swift App/*.swift -o "$app/Contents/MacOS/PadCheck"
cat > "$app/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>PadCheck</string>
    <key>CFBundleDisplayName</key><string>PadCheck</string>
    <key>CFBundleIdentifier</key><string>com.takasurazeem.PadCheck</string>
    <key>CFBundleExecutable</key><string>PadCheck</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.2.0</string>
    <key>CFBundleVersion</key><string>5</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>LSApplicationCategoryType</key><string>public.app-category.utilities</string>
    <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST
codesign --force --sign - "$app"

echo "Built build/padcheck and $app"
