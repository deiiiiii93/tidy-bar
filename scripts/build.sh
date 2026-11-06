#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
export CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$PWD/.build/module-cache"
BUILD_OPTIONS=(-c release --disable-sandbox --cache-path "$PWD/.build/cache" --manifest-cache local -debug-info-format none)
swift build "${BUILD_OPTIONS[@]}"
BIN_DIR="$(swift build "${BUILD_OPTIONS[@]}" --show-bin-path)"
APP="$PWD/dist/Tidy Bar.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" .build/AppIcon.iconset
# Replace the inode so rebuilding does not overwrite a running executable.
cp "$BIN_DIR/TidyBar" "$APP/Contents/MacOS/TidyBar.next"
mv -f "$APP/Contents/MacOS/TidyBar.next" "$APP/Contents/MacOS/TidyBar"
cp Resources/Info.plist "$APP/Contents/Info.plist"
"$BIN_DIR/TidyBar" --export-icon "$PWD/Resources/AppIcon.png"
for size in 16 32 128 256 512; do
    sips -z "$size" "$size" Resources/AppIcon.png --out ".build/AppIcon.iconset/icon_${size}x${size}.png" >/dev/null
    double=$((size * 2))
    sips -z "$double" "$double" Resources/AppIcon.png --out ".build/AppIcon.iconset/icon_${size}x${size}@2x.png" >/dev/null
done
python3 scripts/make_icns.py .build/AppIcon.iconset "$APP/Contents/Resources/AppIcon.icns"
codesign --force --sign - "$APP"
codesign --verify --deep --strict "$APP"
echo "Built: $APP"
