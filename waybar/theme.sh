#!/bin/bash
# Меняет обои и генерирует тему на всё окружение через pywal

# ==================== КОНФИГ ====================
# Получаем путь к папке со скриптом
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR%/*}"  # ~/.config
HOME_DIR="${CONFIG_DIR%/*}"     # ~

# Пути - УНИВЕРСАЛЬНЫЕ
WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME_DIR/wallpapers}"
WAL_BIN="${WAL_BIN:-$(command -v wal 2>/dev/null || echo "$HOME_DIR/.local/bin/wal")}"
THUMB_DIR="$HOME_DIR/.cache/theme_thumbs"
WAL_COLORS="$HOME_DIR/.cache/wal/colors.sh"
THUMB_SIZE=220

mkdir -p "$HOME_DIR/.cache" "$THUMB_DIR"
[ -f "$HOME_DIR/.cache/current_wallpaper" ] || touch "$HOME_DIR/.cache/current_wallpaper"

# ==================== ЗАГРУЗКА ЦВЕТОВ ====================
if [ -f "$WAL_COLORS" ]; then
    source "$WAL_COLORS"
else
    background="#2e1a47"
    foreground="#ffffff"
    color4="#4a2c73"
    color5="#4a2c73"
    color1="#ff6b6b"
    color8="#666666"
fi

WOFI_STYLE=$(mktemp)
WOFI_CONF=$(mktemp)
: > "$WOFI_CONF"

cat > "$WOFI_STYLE" << CSS
window {
    background-color: transparent;
    border: none;
}
#outer-box {
    background-color: alpha(${background}, 0.97);
    border: 2px solid ${color4};
    border-radius: 20px;
    padding: 8px;
}
#input {
    background-color: alpha(${background}, 0.85);
    color: #ffffff;
    border: 2px solid ${color4};
    border-radius: 12px;
    margin-bottom: 8px;
    padding: 10px 15px;
    font-size: 14px;
}
#entry {
    border-radius: 6px;
    padding: 0px;
    margin: 0px;
    background-color: transparent;
    border: 2px solid transparent;
    min-width: 220px;
}
#entry:hover {
    border: 2px solid ${color4};
    background-color: alpha(${color4}, 0.2);
}
#entry:selected {
    border: 2px solid ${color5};
    background-color: alpha(${color5}, 0.3);
}
#text {
    opacity: 0;
    min-height: 0px;
    min-width: 0px;
}
#img, image {
    border-radius: 6px;
    margin: 0px;
    padding: 0px;
}
CSS

CONVERT_BIN=$(command -v convert || command -v magick)

# ==================== ПРОВЕРКИ ====================
if [ ! -x "$WAL_BIN" ]; then
    notify-send "Ошибка" "pywal не найден по пути $WAL_BIN\nУстанови через: paru -S python-pywal или sudo apt install python3-pywal" 2>/dev/null
    rm "$WOFI_STYLE"
    exit 1
fi

if [ ! -d "$WALLPAPER_DIR" ]; then
    notify-send "Ошибка" "Папка не найдена: $WALLPAPER_DIR\nПоложи обои туда и попробуй снова" 2>/dev/null
    rm "$WOFI_STYLE"
    exit 1
fi

shopt -s nullglob nocaseglob
choice=$(
    for img in "$WALLPAPER_DIR"/*.jpg "$WALLPAPER_DIR"/*.jpeg "$WALLPAPER_DIR"/*.png "$WALLPAPER_DIR"/*.webp; do
        name=$(basename "$img")
        thumb="$THUMB_DIR/$name.png"

        if [ -n "$CONVERT_BIN" ]; then
            if [ ! -f "$thumb" ] || [ "$img" -nt "$thumb" ]; then
                "$CONVERT_BIN" "$img" -thumbnail "${THUMB_SIZE}x${THUMB_SIZE}" "$thumb" 2>/dev/null
            fi
            echo "$name|$thumb"
        else
            echo "$name|$img"
        fi
    done | wofi --dmenu --style="$WOFI_STYLE" --width=1000 --height=600 --columns=4 \
                 --hide-scroll --prompt="Выбери обои: " --allow-markup
)

rm "$WOFI_STYLE" "$WOFI_CONF"

if [ -z "$choice" ]; then
    exit 0
fi

# Получаем полный путь обоев
choice_name="${choice%%|*}"
wallpaper=""
for img in "$WALLPAPER_DIR"/*.jpg "$WALLPAPER_DIR"/*.jpeg "$WALLPAPER_DIR"/*.png "$WALLPAPER_DIR"/*.webp; do
    if [ "$(basename "$img")" = "$choice_name" ]; then
        wallpaper="$img"
        break
    fi
done

if [ -z "$wallpaper" ]; then
    notify-send "Ошибка" "Обои не найдены" 2>/dev/null
    exit 1
fi

# ==================== ПРИМЕНЯЕМ ТЕМУ ====================
"$WAL_BIN" -i "$wallpaper" -q

# Сохраняем путь обоев
echo "$wallpaper" > "$HOME_DIR/.cache/current_wallpaper"

# Применяем обои на рабочий стол
swaybg -o '*' -i "$wallpaper" &
SWAYBG_PID=$!

# Даём немного времени для обновления pywal кэша
sleep 1

# Синхронизируем greetd если есть скрипт
SYNC_SCRIPT="$SCRIPT_DIR/sync-greetd-theme.sh"
if [ -f "$SYNC_SCRIPT" ] && [ -x "$SYNC_SCRIPT" ]; then
    bash "$SYNC_SCRIPT"
fi

# Перезагружаем waybar
killall waybar 2>/dev/null || true
sleep 0.5
waybar &

# Перезагружаем niri чтобы применить новые цвета
sudo -u $USER systemctl --user restart niri 2>/dev/null || true

# Показываем уведомление
notify-send "🎨 Тема" "Обновлены обои и цвета\n$(basename "$wallpaper")" 2>/dev/null

wait $SWAYBG_PID 2>/dev/null
