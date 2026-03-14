#!/bin/bash

# Build for both Intel and Apple Silicon
echo "🚀 Building Universal Binary..."
swift build -c release --arch arm64 --arch x86_64

APP_NAME="DynamicWallpaperApp"
# SwiftPM universal build output location might vary, but usually it merges them or puts in 'apple/Products/Release'
# For simple 'swift build', it's .build/release or .build/apple/Products/Release
# Let's check where it puts it. If --arch is specified, it might be in a different folder.
# But usually .build/apple/Products/Release contains the universal binary if built that way.
# However, standard path is .build/release for host.
# Let's assume standard path for now, but use `swift build --show-bin-path -c release --arch arm64 --arch x86_64` to be sure?
# Actually, just use the one created.
BUILD_DIR="$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path)"
APP_BUNDLE="$APP_NAME.app"
DMG_NAME="$APP_NAME.dmg"

echo "📦 Creating App Bundle Structure..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy executable
cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/"

# Copy Resources (Localization)
if [ -d "Sources/Resources" ]; then
    cp -r Sources/Resources/* "$APP_BUNDLE/Contents/Resources/"
fi

# Copy Icon
if [ -f "AppIcon.icns" ]; then
    cp "AppIcon.icns" "$APP_BUNDLE/Contents/Resources/"
fi

# Create Info.plist
cat > "$APP_BUNDLE/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.example.$APP_NAME</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.2</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSUIElement</key>
    <false/>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
</dict>
</plist>
EOF

echo "✅ App Bundle Created: $APP_BUNDLE"

echo "💿 Creating DMG..."
rm -f "$DMG_NAME"
hdiutil create -volname "$APP_NAME" -srcfolder "$APP_BUNDLE" -ov -format UDZO "$DMG_NAME"

echo "🎉 Done! DMG is ready: $DMG_NAME"
