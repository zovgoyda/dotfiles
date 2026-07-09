#!/bin/bash
# Меняет обои и генерирует тему на всё окружение через pywal

set -e

# ==================== КОНФИГ ====================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR%/*}"
HOME_DIR="${CONFIG_DIR%/*}"

WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME_DIR/wallpapers}"
WAL_BIN="${WAL_BIN:-$(command -v wal 2>/dev/null || true)}"
THUMB_DIR="$HOME_DIR/.cache/theme_thumbs"
WAL_COLORS="$HOME_DIR/.cache/wal/colors.sh"
THUMB_SIZE=220

mkdir -p "$HOME_DIR/.cache" "$THUMB_DIR"
[ -f "$HOME_DIR/.cache/current_wallpaper" ] || touch "$HOME_DIR/.cache/current_wallpaper"

# ==================== ФУНКЦИИ ====================
error_exit() {
    echo "❌ Ошибка: $1" >&2
    exit 1
}

# ==================== ПРОВЕРКИ ====================
if [ -z "$WAL_BIN" ] || [ ! -x "$WAL_BIN" ]; then
    error_exit "pywal не найден. Установи: paru -S python-pywal или sudo apt install python3-pywal"
fi

if [ ! -d "$WALLPAPER_DIR" ]; then
    error_exit "Папка обоев не найдена: $WALLPAPER_DIR. Создай папку и положи туда обои (jpg/png/webp)"
fi

# Проверяем есть ли обои
shopt -s nullglob nocaseglob
wallpapers=("$WALLPAPER_DIR"/*.{jpg,jpeg,png,webp})

if [ ${#wallpapers[@]} -eq 0 ]; then
    error_exit "Обои не найдены в $WALLPAPER_DIR. Положи хотя бы одно изображение."
fi

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

# ==================== СОЗДАЁМ СТИЛЬ WOFI ====================
WOFI_STYLE=$(mktemp)
cat > "$WOFI_STYLE" << 'CSS'
window {
    background-color: transparent;
    border: none;
}
#outer-box {
    background-color: alpha(var(--bg, #2e1a47), 0.97);
    border: 2px solid var(--color4, #4a2c73);
    border-radius: 20px;
    padding: 8px;
}
#input {
    background-color: alpha(var(--bg, #2e1a47), 0.85);
    color: #ffffff;
    border: 2px solid var(--color4, #4a2c73);
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
    border: 2px solid var(--color4, #4a2c73);
    background-color: alpha(var(--color4, #4a2c73), 0.2);
}
#entry:selected {
    border: 2px solid var(--color5, #4a2c73);
    background-color: alpha(var(--color5, #4a2c73), 0.3);
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

CONVERT_BIN=$(command -v convert || command -v magick || true)

# ==================== ВЫБОР ОБОЕВ ====================
choice=$(
    for img in "$WALLPAPER_DIR"/*.{jpg,jpeg,png,webp}; do
        [ -f "$img" ] || continue
        name=$(basename "$img")
        thumb="$THUMB_DIR/$name.png"

        if [ -n "$CONVERT_BIN" ] && command -v "$CONVERT_BIN" &>/dev/null; then
            if [ ! -f "$thumb" ] || [ "$img" -nt "$thumb" ]; then
                "$CONVERT_BIN" "$img" -thumbnail "${THUMB_SIZE}x${THUMB_SIZE}" "$thumb" 2>/dev/null || true
            fi
            if [ -f "$thumb" ]; then
                echo "$name|$thumb"
            else
                echo "$name|$img"
            fi
        else
            echo "$name|$img"
        fi
    done | wofi --dmenu --style="$WOFI_STYLE" --width=1000 --height=600 --columns=4 \
                 --hide-scroll --prompt="Выбери обои: " --allow-markup
)

rm -f "$WOFI_STYLE"

if [ -z "$choice" ]; then
    exit 0
fi

# Получаем полный путь обоев
choice_name="${choice%%|*}"
wallpaper=""
for img in "$WALLPAPER_DIR"/*.{jpg,jpeg,png,webp}; do
    [ -f "$img" ] || continue
    if [ "$(basename "$img")" = "$choice_name" ]; then
        wallpaper="$img"
        break
    fi
done

if [ -z "$wallpaper" ] || [ ! -f "$wallpaper" ]; then
    error_exit "Обои не найдены: $choice_name"
fi

echo "🎨 Применяю тему для: $(basename "$wallpaper")..."

# ==================== ПРИМЕНЯЕМ ТЕМУ ====================
"$WAL_BIN" -i "$wallpaper" -q

# Сохраняем путь обоев
echo "$wallpaper" > "$HOME_DIR/.cache/current_wallpaper"

# Применяем обои на рабочий стол
swaybg -o '*' -i "$wallpaper" >/dev/null 2>&1 &
SWAYBG_PID=$!

# Даём время для обновления pywal кэша
sleep 0.5

# Синхронизируем greetd если есть скрипт
SYNC_SCRIPT="$SCRIPT_DIR/sync-greetd-theme.sh"
if [ -f "$SYNC_SCRIPT" ] && [ -x "$SYNC_SCRIPT" ]; then
    bash "$SYNC_SCRIPT" 2>/dev/null || true
fi

# Перезагружаем waybar
killall waybar 2>/dev/null || true
sleep 0.3
waybar >/dev/null 2>&1 &

# Показываем уведомление
if command -v notify-send &>/dev/null; then
    notify-send "🎨 Тема" "✅ Обновлены обои и цвета\n$(basename "$wallpaper")"
fi

echo "✅ Тема применена: $(basename "$wallpaper")"

wait $SWAYBG_PID 2>/dev/null || true
