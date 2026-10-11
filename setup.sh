#!/usr/bin/env bash
set -Eeuo pipefail

REPOSITORY_ARCHIVE_URL="https://github.com/danisyam095/sddm-japanese-sunset-glass/archive/refs/heads/main.tar.gz"
SCRIPT_DIR=""
TEMP_DIR=""

cleanup() {
    if [[ -n "$TEMP_DIR" && -d "$TEMP_DIR" ]]; then
        rm -rf -- "$TEMP_DIR"
    fi
}

trap cleanup EXIT

if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
    SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
else
    SCRIPT_DIR="$PWD"
fi

if [[ -s "$SCRIPT_DIR/install.sh" && -s "$SCRIPT_DIR/metadata.desktop" ]]; then
    exec bash "$SCRIPT_DIR/install.sh" "$@"
fi

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    printf '%s\n' \
        'Usage: setup.sh [--dry-run]' \
        'Downloads the public theme archive, then runs its installer.' \
        'For local installation, run ./install.sh from the project directory.'
    exit 0
fi

for tool in curl tar awk find; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        printf 'Error: %s is required to download the theme.\n' "$tool" >&2
        exit 1
    fi
done

archive_url="${SDDM_THEME_ARCHIVE_URL:-$REPOSITORY_ARCHIVE_URL}"
if [[ "$archive_url" != https://* ]]; then
    printf 'Error: the theme archive URL must use HTTPS.\n' >&2
    exit 1
fi

TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/sddm-japanese-sunset-glass.XXXXXX")"
archive="$TEMP_DIR/theme.tar.gz"
source_root="$TEMP_DIR/source"

printf 'Downloading Japanese Sunset Glass from GitHub...\n'
curl --fail --location --silent --show-error --proto '=https' --tlsv1.2 \
    "$archive_url" --output "$archive"

if tar -tzf "$archive" | awk '
    /^\// || /(^|\/)\.\.(\/|$)/ { invalid = 1 }
    END { exit invalid ? 0 : 1 }
'; then
    printf 'Error: the downloaded archive contains an unsafe path.\n' >&2
    exit 1
fi

mkdir "$source_root"
tar --no-same-owner -xzf "$archive" -C "$source_root"
theme_root="$(find "$source_root" -mindepth 1 -maxdepth 2 \
    -type f -name metadata.desktop -print -quit | xargs -r dirname)"

if [[ -z "$theme_root" || ! -s "$theme_root/install.sh" ]]; then
    printf 'Error: the archive does not contain a valid theme installer.\n' >&2
    exit 1
fi

bash "$theme_root/install.sh" "$@"
