#!/usr/bin/env bash
# scripts/generate-screenshots.sh
#
# Generates App Store screenshots using the iOS simulator.
# Runs the app in three reference simulators (6.7", 6.5", 5.5"), navigates
# through the polish path, and captures PNGs into build/screenshots/.
#
# Requires: Xcode installed, xcrun simctl, jq (optional).
#
# Usage:
#   ./scripts/generate-screenshots.sh           # all sizes
#   ./scripts/generate-screenshots.sh 6.7       # only 6.7"
#
# Note: this is a MANUAL capture script. It boots the simulator, installs
# the Debug build, and launches the app with -UITestResetState so you start
# on the onboarding. You then navigate manually and trigger captures via
# keyboard (Enter in the terminal) — one capture per screen.

set -euo pipefail

DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
export DEVELOPER_DIR

BUNDLE_ID="cz.martinkoci.breath"
SCHEME="Breath"
OUT_DIR="build/screenshots"

# Device matrix: label -> device type
declare -a DEVICES_67=("iPhone 17 Pro Max")  # 6.7" / 6.9"
declare -a DEVICES_65=("iPhone 14 Plus")     # 6.5"
declare -a DEVICES_55=("iPhone 8 Plus")      # 5.5" (legacy, if you want)

FILTER="${1:-all}"

mkdir -p "$OUT_DIR"

boot_device() {
    local device_name="$1"
    echo "==> Booting $device_name..."
    local udid
    udid=$(xcrun simctl list devices available | grep -F "$device_name (" | head -n 1 | grep -oE '[A-F0-9-]{36}' || true)
    if [[ -z "$udid" ]]; then
        echo "    Device '$device_name' not found. Skipping."
        return 1
    fi
    xcrun simctl boot "$udid" 2>/dev/null || true
    xcrun simctl bootstatus "$udid" -b >/dev/null
    echo "$udid"
}

build_app() {
    echo "==> Building $SCHEME (Debug) for simulator..."
    xcodebuild -scheme "$SCHEME" \
        -destination "generic/platform=iOS Simulator" \
        -configuration Debug \
        -derivedDataPath build/derived \
        build -quiet
}

install_and_launch() {
    local udid="$1"
    local app_path
    app_path=$(find build/derived/Build/Products -name "${SCHEME}.app" -type d | head -n 1)
    if [[ -z "$app_path" ]]; then
        echo "    App bundle not found after build." >&2
        return 1
    fi
    xcrun simctl install "$udid" "$app_path"
    xcrun simctl terminate "$udid" "$BUNDLE_ID" 2>/dev/null || true
    xcrun simctl launch "$udid" "$BUNDLE_ID" -UITestResetState YES >/dev/null
}

capture_for_device() {
    local device_name="$1"
    local label="$2"
    local udid
    udid=$(boot_device "$device_name") || return 0

    install_and_launch "$udid"

    local safe_name
    safe_name=$(echo "$device_name" | tr ' ' '_')
    local i=1
    local screens=(
        "01_onboarding"
        "02_configuration"
        "03_session_breathing"
        "04_session_retention"
        "05_stats"
        "06_paywall"
    )

    for name in "${screens[@]}"; do
        echo ""
        echo "    [$label] Navigate to: $name"
        echo "    Press ENTER in this terminal when the screen is ready..."
        read -r _
        local out="$OUT_DIR/${label}_${safe_name}_${name}.png"
        xcrun simctl io "$udid" screenshot "$out"
        echo "    saved → $out"
        i=$((i + 1))
    done
}

build_app

case "$FILTER" in
    6.7|all)
        for d in "${DEVICES_67[@]}"; do capture_for_device "$d" "6.7"; done
        ;;&
    6.5|all)
        for d in "${DEVICES_65[@]}"; do capture_for_device "$d" "6.5"; done
        ;;&
    5.5|all)
        for d in "${DEVICES_55[@]}"; do capture_for_device "$d" "5.5"; done
        ;;
    *)
        echo "Unknown filter: $FILTER (expected: 6.7 | 6.5 | 5.5 | all)"
        exit 1
        ;;
esac

echo ""
echo "==> Done. Screenshots in $OUT_DIR/"
ls -1 "$OUT_DIR"/
