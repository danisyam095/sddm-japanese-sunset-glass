#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
THEME_DIR="${1:-$SCRIPT_DIR}"

if [[ "${1:-}" == "--check-only" ]]; then
    THEME_DIR="$SCRIPT_DIR"
    check_only=1
else
    check_only=0
fi

required_files=(
    metadata.desktop
    theme.conf
    showcase.png
    Main.qml
    components/LoginPanel.qml
    components/ClockDate.qml
    components/PowerActions.qml
    assets/background.png
    assets/arch-logo.svg
    assets/avatar-placeholder.svg
    assets/icons/lock.svg
    assets/icons/login.svg
    assets/icons/shutdown.svg
    assets/icons/restart.svg
    assets/icons/sleep.svg
    assets/fonts/InstrumentSans-Regular.ttf
    assets/fonts/InstrumentSans-Medium.ttf
)

for file in "${required_files[@]}"; do
    if [[ ! -s "$THEME_DIR/$file" ]]; then
        printf 'Missing or empty theme file: %s\n' "$THEME_DIR/$file" >&2
        exit 1
    fi
done

if ! grep -q '^QtVersion=6$' "$THEME_DIR/metadata.desktop"; then
    printf 'metadata.desktop must select the Qt 6 greeter.\n' >&2
    exit 1
fi

if (( check_only )); then
    printf 'Theme files and metadata are present and non-empty.\n'
    exit 0
fi

if [[ ! -x "$THEME_DIR/scripts/preview.sh" && "$THEME_DIR" == "$SCRIPT_DIR" ]]; then
    printf 'Preview script is not executable; run: chmod +x scripts/preview.sh\n' >&2
    exit 1
fi

GREETER="$(command -v sddm-greeter-qt6 || true)"
if [[ -z "$GREETER" ]]; then
    printf 'sddm-greeter-qt6 is unavailable. Install the SDDM Qt 6 greeter package first.\n' >&2
    exit 1
fi

if [[ -z "${DISPLAY:-}" && -z "${WAYLAND_DISPLAY:-}" ]]; then
    printf 'No graphical display is available. Run this preview from your desktop session.\n' >&2
    exit 1
fi

printf 'Starting SDDM Qt 6 test greeter for: %s\n' "$THEME_DIR"
printf 'Close the preview window to return to the terminal. Test mode does not authenticate or power off.\n'
exec "$GREETER" --test-mode --theme "$THEME_DIR"
