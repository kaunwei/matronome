#!/usr/bin/env bash
set -euo pipefail

# Project root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "=== Building Metronome macOS Release Application Bundle ==="
cd "${ROOT_DIR}"

# 1. Build release executable via Swift Package Manager
echo "[1/4] Building release binary with swift build -c release..."
swift build -c release

# Retrieve the release binary directory
BIN_DIR="$(swift build -c release --show-bin-path)"
EXECUTABLE="${BIN_DIR}/MetronomeApp"

if [[ ! -f "${EXECUTABLE}" ]]; then
    echo "Error: Executable not found at ${EXECUTABLE}" >&2
    exit 1
fi

# 2. Prepare Application Bundle Directory Structure
BUILD_DIR="${ROOT_DIR}/build"
APP_NAME="Metronome.app"
APP_DIR="${BUILD_DIR}/${APP_NAME}"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "[2/4] Assembling .app bundle structure in ${APP_DIR}..."
rm -rf "${APP_DIR}"
mkdir -p "${MACOS_DIR}" "${RESOURCES_DIR}"

# Copy binary into Contents/MacOS
cp "${EXECUTABLE}" "${MACOS_DIR}/MetronomeApp"
chmod +x "${MACOS_DIR}/MetronomeApp"

# 3. Create Info.plist
echo "[3/4] Generating Info.plist..."
cat << 'EOF' > "${CONTENTS_DIR}/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>MetronomeApp</string>
    <key>CFBundleIdentifier</key>
    <string>com.matronome.MetronomeApp</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Metronome</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSMicrophoneUsageDescription</key>
    <string>Microphone access is not required but audio engine operates on macOS Audio subsystem.</string>
</dict>
</plist>
EOF

# Create PkgInfo
echo "APPL????" > "${CONTENTS_DIR}/PkgInfo"

# 4. Create Portable Archive
echo "[4/4] Creating portable archive build/Metronome.zip..."
(
    cd "${BUILD_DIR}"
    rm -f "Metronome.zip"
    zip -r -y -q "Metronome.zip" "${APP_NAME}"
)

echo "=== Successfully built: ==="
echo "Application: ${APP_DIR}"
echo "Zip Archive: ${BUILD_DIR}/Metronome.zip"
