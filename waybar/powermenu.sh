#!/usr/bin/env bash
# Power menu for waybar using wofi
# - toggle behavior via PID file
# - shows 4 identical square tiles with icons

set -eo pipefail

: "${XDG_RUNTIME_DIR:=/run/user/$(id -u)}"
PIDFILE="$XDG_RUNTIME_DIR/waybar-powermenu.pid"
WOFI_STYLE=$(mktemp)
trap 'rm -f "$WOFI_STYLE"' EXIT

# Toggle: if PID exists and process alive -> kill and exit
if [ -f "$PIDFILE" ]; then
  oldpid=$(cat "$PIDFILE" 2>/dev/null || true)
  if [ -n "$oldpid" ] && kill -0 "$oldpid" 2>/dev/null; then
    kill "$oldpid" 2>/dev/null || true
    rm -f "$PIDFILE"
    exit 0
  else
    rm -f "$PIDFILE" || true
  fi
fi

# Check wofi
if ! command -v wofi >/dev/null 2>&1; then
  echo "❌ wofi not found" >&2
  exit 1
fi

# Colors (try pywal first)
WAL_COLORS="$HOME/.cache/wal/colors.sh"
if [ -f "$WAL_COLORS" ]; then
  # shellcheck disable=SC1090
  source "$WAL_COLORS" || true
  outer_bg="${background:-#2e1a47}"
  border_col="${color5:-#7fc8ff}"
else
  outer_bg="#2e1a47"
  border_col="#7fc8ff"
fi

# Wofi CSS (use hex colors to avoid alpha() compatibility issues)
cat > "$WOFI_STYLE" <<EOF
window { background-color: transparent; border: none; }
main { background-color: transparent; }
#outer-box { background-color: ${outer_bg}; border: 2px solid ${border_col}; border-radius: 12px; padding: 12px; }
#scroll { background-color: transparent; }
#entry { background-color: transparent; border: 2px solid transparent; border-radius: 8px; padding: 8px; margin: 6px; width: 96px; height: 96px; display: inline-block; vertical-align: middle; text-align: center; font-size: 32px; }
#entry:hover { border: 2px solid ${border_col}; background-color: rgba(127,200,255,0.04); }
#entry:selected { border: 2px solid ${border_col}; background-color: rgba(127,200,255,0.06); }
#img, image { width: 100%; height: 100%; object-fit: contain; border-radius: 6px; }
#text { display: none; }
EOF

# Choices as an array (unicode icons)
choices=( $'\uf011' $'\uf01e' $'\uf08b' $'\uf023' )

# Write PID (script PID) for toggle detection
mkdir -p "$XDG_RUNTIME_DIR"
echo $$ > "$PIDFILE"

# Launch wofi (foreground) and capture selection
selection=$(printf '%s\n' "${choices[@]}" | wofi --dmenu --style="$WOFI_STYLE" --width=520 --height=220 --columns=4 --hide-scroll --prompt="" --location=center)

# Handle empty selection (esc)
if [ -z "$selection" ]; then
  rm -f "$PIDFILE" || true
  exit 0
fi

case "$selection" in
  $'\uf011') loginctl poweroff ;;
  $'\uf01e') loginctl reboot ;;
  $'\uf08b') loginctl terminate-session "${XDG_SESSION_ID:-}" ;;
  $'\uf023') swaylock ;;
esac

rm -f "$PIDFILE" || true
