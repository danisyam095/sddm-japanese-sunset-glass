#!/usr/bin/env bash
set -Eeuo pipefail

THEME_NAME="sddm-japanese-sunset-glass"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
SOURCE_DIR="$SCRIPT_DIR"
THEME_ROOT="${SDDM_THEME_ROOT:-/usr/share/sddm/themes}"
THEME_DEST="$THEME_ROOT/$THEME_NAME"
CONFIG_FILE="${SDDM_CONFIG_FILE:-}"
BACKUP_ROOT="${SDDM_BACKUP_ROOT:-/var/backups/$THEME_NAME}"
DRY_RUN=0
TEMP_DIR=""
STAGE_DIR=""
BACKUP_DIR=""
CONFIG_EXISTED=0
THEME_EXISTED=0
CONFIG_CHANGED=0
THEME_CHANGED=0

usage() {
    cat <<'EOF'
Usage: install.sh [--dry-run] [--help]

Install the Japanese Sunset Glass theme for an existing SDDM installation.
The installer does not install packages, enable or start services, or switch
display managers.

Optional environment overrides:
  SDDM_THEME_ROOT    SDDM themes directory (default: /usr/share/sddm/themes)
  SDDM_CONFIG_FILE   SDDM config file (default: /etc/sddm.conf if present,
                     otherwise /etc/sddm.conf.d/10-japanese-sunset-glass.conf)
  SDDM_BACKUP_ROOT   Backup directory (default: /var/backups/sddm-japanese-sunset-glass)
EOF
}

say_error() {
    printf 'Error: %s\n' "$*" >&2
}

confirm() {
    local answer
    if [[ ! -t 0 ]]; then
        say_error "confirmation requires an interactive terminal"
        return 1
    fi
    read -r -p "$1 [y/N] " answer
    [[ "$answer" == "y" || "$answer" == "Y"
       || "$answer" == "yes" || "$answer" == "YES" ]]
}

run_privileged() {
    if (( EUID == 0 )); then
        "$@"
    elif command -v sudo >/dev/null 2>&1; then
        sudo -- "$@"
    elif command -v doas >/dev/null 2>&1; then
        doas "$@"
    else
        say_error "root privileges are required; run as root or install sudo/doas"
        return 1
    fi
}

cleanup() {
    if [[ -n "$TEMP_DIR" && -d "$TEMP_DIR" ]]; then
        rm -rf -- "$TEMP_DIR"
    fi
    if [[ -n "$STAGE_DIR" && -d "$STAGE_DIR" ]]; then
        run_privileged rm -rf -- "$STAGE_DIR"
    fi
}

rollback() {
    trap - ERR
    printf 'Installation failed; restoring the previous theme/configuration where possible.\n' >&2

    if (( CONFIG_CHANGED )); then
        if (( CONFIG_EXISTED )); then
            run_privileged cp -a "$BACKUP_DIR/sddm.conf" "$CONFIG_FILE" || true
        else
            run_privileged rm -f -- "$CONFIG_FILE" || true
        fi
    fi

    if (( THEME_CHANGED )); then
        run_privileged rm -rf -- "$THEME_DEST" || true
        if (( THEME_EXISTED )); then
            run_privileged cp -a "$BACKUP_DIR/theme.previous" "$THEME_DEST" || true
        fi
    fi
}

on_error() {
    local status="$1"
    if [[ -n "$BACKUP_DIR" ]] && (( CONFIG_CHANGED || THEME_CHANGED )); then
        rollback
    fi
    exit "$status"
}

trap cleanup EXIT
trap 'on_error "$?"' ERR

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=1 ;;
        --help|-h) usage; exit 0 ;;
        *) say_error "unknown option: $arg"; usage; exit 2 ;;
    esac
done

if [[ ! -s "$SOURCE_DIR/metadata.desktop" ]]; then
    say_error "run install.sh from the extracted theme directory"
    exit 1
fi

for required in metadata.desktop theme.conf Main.qml components/LoginPanel.qml \
                components/ClockDate.qml components/PowerActions.qml \
                assets/background.png assets/avatar-placeholder.svg showcase.png; do
    if [[ ! -s "$SOURCE_DIR/$required" ]]; then
        say_error "required theme file is missing or empty: $required"
        exit 1
    fi
done

if ! grep -q '^QtVersion=6$' "$SOURCE_DIR/metadata.desktop"; then
    say_error "this theme requires an SDDM greeter built with Qt 6"
    exit 1
fi

if ! command -v sddm-greeter-qt6 >/dev/null 2>&1; then
    say_error "sddm-greeter-qt6 was not found; install an SDDM Qt 6 greeter using your distribution"
    exit 1
fi

if [[ -z "$CONFIG_FILE" ]]; then
    if [[ -f /etc/sddm.conf ]]; then
        CONFIG_FILE="/etc/sddm.conf"
    else
        CONFIG_FILE="/etc/sddm.conf.d/10-japanese-sunset-glass.conf"
    fi
fi

if [[ -e "$THEME_DEST" ]]; then
    THEME_EXISTED=1
fi
if [[ -f "$CONFIG_FILE" ]]; then
    CONFIG_EXISTED=1
fi

printf '\nJapanese Sunset Glass installation plan\n'
printf '  Theme destination: %s\n' "$THEME_DEST"
printf '  SDDM configuration: %s\n' "$CONFIG_FILE"
printf '  Existing theme: %s\n' "$([[ "$THEME_EXISTED" == 1 ]] && printf yes || printf no)"
printf '  Package manager and service changes: none\n'
printf '  Display manager will not be started or switched.\n'

if (( DRY_RUN )); then
    printf '  Dry run: no files or system configuration will be changed.\n'
    exit 0
fi

confirm "Install the theme and make it the configured SDDM theme?" || {
    printf 'Cancelled without changing files.\n'
    exit 0
}

if (( THEME_EXISTED )); then
    confirm "Replace the existing theme directory after creating a backup?" || {
        printf 'Cancelled; the existing theme was left unchanged.\n'
        exit 0
    }
fi

TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/$THEME_NAME.XXXXXX")"
BACKUP_DIR="$BACKUP_ROOT/$(date -u +%Y%m%dT%H%M%SZ)-$$"
run_privileged mkdir -p "$BACKUP_DIR"

if (( CONFIG_EXISTED )); then
    run_privileged cp -a "$CONFIG_FILE" "$BACKUP_DIR/sddm.conf"
fi
if (( THEME_EXISTED )); then
    run_privileged cp -a "$THEME_DEST" "$BACKUP_DIR/theme.previous"
fi

if [[ -f "$CONFIG_FILE" ]]; then
    awk -v theme="$THEME_NAME" '
        function finish_theme() {
            if (in_theme && !current_written)
                print "Current=" theme
            if (in_theme && !theme_dir_written)
                print "ThemeDir=" theme_root
        }
        /^\[[^]]+\][[:space:]]*$/ {
            finish_theme()
            in_theme = ($0 ~ /^[[:space:]]*\[Theme\][[:space:]]*$/)
            if (in_theme)
                theme_found = 1
            current_written = 0
            theme_dir_written = 0
            print
            next
        }
        in_theme && /^[[:space:]]*Current[[:space:]]*=/ {
            if (!current_written)
                print "Current=" theme
            current_written = 1
            next
        }
        in_theme && /^[[:space:]]*ThemeDir[[:space:]]*=/ {
            if (!theme_dir_written)
                print "ThemeDir=" theme_root
            theme_dir_written = 1
            next
        }
        { print }
        END {
            finish_theme()
            if (!theme_found)
                printf "\n[Theme]\nCurrent=%s\nThemeDir=%s\n", theme, theme_root
        }
    ' theme_root="$THEME_ROOT" "$CONFIG_FILE" > "$TEMP_DIR/sddm.conf"
else
    printf '[Theme]\nCurrent=%s\nThemeDir=%s\n' "$THEME_NAME" "$THEME_ROOT" \
        > "$TEMP_DIR/sddm.conf"
fi

STAGE_DIR="$THEME_ROOT/.$THEME_NAME.installing.$$"
run_privileged mkdir -p "$THEME_ROOT" "$(dirname -- "$CONFIG_FILE")"
run_privileged mkdir -p "$STAGE_DIR"
for item in Main.qml metadata.desktop theme.conf components assets showcase.png; do
    if [[ -e "$SOURCE_DIR/$item" ]]; then
        run_privileged cp -a "$SOURCE_DIR/$item" "$STAGE_DIR/$item"
    fi
done
run_privileged chmod -R a+rX "$STAGE_DIR"

THEME_CHANGED=1
if (( THEME_EXISTED )); then
    run_privileged rm -rf -- "$THEME_DEST"
fi
run_privileged mv -- "$STAGE_DIR" "$THEME_DEST"
STAGE_DIR=""

CONFIG_CHANGED=1
run_privileged install -D -m 0644 "$TEMP_DIR/sddm.conf" "$CONFIG_FILE"

if ! grep -Eq '^[[:space:]]*Current[[:space:]]*=[[:space:]]*sddm-japanese-sunset-glass[[:space:]]*$' "$CONFIG_FILE"; then
    say_error "the SDDM configuration does not select the installed theme"
    false
fi
if ! grep -Fqx "ThemeDir=$THEME_ROOT" "$CONFIG_FILE"; then
    say_error "the SDDM configuration does not point to the installed theme directory"
    false
fi
for required in Main.qml metadata.desktop theme.conf components/LoginPanel.qml assets/background.png; do
    if [[ ! -s "$THEME_DEST/$required" ]]; then
        say_error "installed theme file is missing or empty: $required"
        false
    fi
done

printf '\nInstallation completed.\n'
printf '  Theme: %s\n' "$THEME_DEST"
printf '  Configuration: %s\n' "$CONFIG_FILE"
printf '  Backup: %s\n' "$BACKUP_DIR"
printf '  No package, service, or display-manager changes were made.\n'
printf '  Restart SDDM or reboot only when you are ready to test the login screen.\n'
