#!/bin/bash
# Простое меню выключения с иконками
# Поведение:
# - При повторном нажатии закрывает открытое меню (toggle) через PID-файл
# - Показывает 4 одинаковых квадрата с иконками

set -euo pipefail

# Безопасный XDG_RUNTIME_DIR
: ${XDG_RUNTIME_DIR:="/run/user/$(id -u)"}
PIDFILE="$XDG_RUNTIME_DIR/waybar-powermenu.pid"
WOFI_STYLE=$(mktemp)

cleanup() {
    rm -f "$WOFI_STYLE"
}
trap cleanup EXIT

# Если есть PID-файл и процесс живой — завершаем его и выходим (toggle)
if [ -f "$PIDFILE" ]; then
    pid=$(cat "$PIDFILE" 2>/dev/null || true)
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
        kill "$pid" 2>/dev/null || true
        rm -f "$PIDFILE"
        exit 0
    else
        rm -f "$PIDFILE" || true
    fi
fi

# Проверяем наличие wofi
if ! command -v wofi >/dev/null 2>&1; then
    echo "❌ wofi не найден"
    exit 1
fi

# Поддержка цветов из pywal (необязательно)
WAL_COLORS="$HOME/.cache/wal/colors.sh"
if [ -f "$WAL_COLORS" ]; then
    # shellcheck disable=SC1090
    source "$WAL_COLORS" || true
    outer_bg="${background:-rgba(46,26,71,0.95)}"
    border_col="${color5:-#7fc8ff}"
else
    outer_bg="rgba(46,26,71,0.95)"
    border_col="#7fc8ff"
fi

# Создаём CSS для wofi — 4 квадрата одинакового размера
cat > "$WOFI_STYLE" <<EOF
window { background-color: transparent; border: none; }
main { background-color: transparent; }
#outer-box {
    background-color: ${outer_bg};
    border: 2px solid ${border_col};
    border-radius: 12px;
    padding: 12px;
}
#scroll { background-color: transparent; }
#entry {
    background-color: transparent;
    border: 2px solid transparent;
    border-radius: 8px;
    padding: 8px;
    margin: 6px;
    width: 96px;
    height: 96px;
    display: inline-block;
    vertical-align: middle;
    text-align: center;
}
#entry:hover { border: 2px solid ${border_col}; background-color: rgba(127,200,255,0.04); }
#entry:selected { border: 2px solid ${border_col}; background-color: rgba(127,200,255,0.06); }
#img, image { width: 100%; height: 100%; object-fit: contain; border-radius: 6px; }
#text { display: none; }
EOF

# Список пунктов — четырe иконки (используются unicode-иконки fontawesome/nerd-font)
choices=$'\uf011\n\uf01e\n\uf08b\n\uf023'

# Запускаем wofi в фоне, запоминаем PID в файле для toggle-логики
(
    echo -e "$choices" | \
    wofi --dmenu --style="$WOFI_STYLE" \
         --width=520 --height=220 \
         --columns=4 --hide-scroll \
         --prompt="" --location=center | \
    while read -r choice; do
        case "$choice" in
            $'\uf011') loginctl poweroff ;;
            $'\uf01e') loginctl reboot ;;
            $'\uf08b') loginctl terminate-session "$XDG_SESSION_ID" ;;
            $'\uf023') swaylock ;;
        esac
    done
) &

bg_pid=$!
# Сохраняем PID чтобы следующий запуск мог закрыть процесс
mkdir -p "$XDG_RUNTIME_DIR"
echo "$bg_pid" > "$PIDFILE"

# Ожидаем завершения и убираем PID
wait "$bg_pid" || true
rm -f "$PIDFILE" || true
