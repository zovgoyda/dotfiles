#!/usr/bin/env bash
# Меняет обои через wofi и генерирует тему для waybar/wofi/greetd
# Выбор обоев через обычный wofi (список файлов), генерирует waybar/colors.css и wofi/style.css на основе pywal

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME_DIR="$HOME"
WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME_DIR/wallpapers}"
WAL_BIN="${WAL_BIN:-$(command -v wal || true)}"
WOFI_BIN="${WOFI_BIN:-$(command -v wofi || true)}"
WAYBAR_COLORS="$SCRIPT_DIR/colors.css"
WOFI_STYLE="$HOME_DIR/.config/wofi/style.css"
CACHE_WALL="$HOME_DIR/.cache/current_wallpaper"

# Fallback colors
bg_default="#0b0e19"
fg_default="#c2c2c5"
border_default="#3B7FC1"
accent_default="#578CBA"
danger_default="#485A6D"

if [ ! -d "$WALLPAPER_DIR" ]; then
    echo "❌ Папка обоев не найдена: $WALLPAPER_DIR"
    exit 1
fi

if [ -z "$WOFI_BIN" ]; then
    echo "❌ wofi не найден"
    exit 1
fi

# Собираем список обоев (полные пути)
shopt -s nullglob
mapfile -t wallpapers < <(printf "%s\n" "$WALLPAPER_DIR"/*.{jpg,jpeg,png,webp} 2>/dev/null)
if [ ${#wallpapers[@]} -eq 0 ]; then
    echo "❌ Обои не найдены в $WALLPAPER_DIR"
    exit 1
fi

# Показываем wofi с basename, но возвращаем полный путь через индекс
choices=$(printf "%s\n" "${wallpapers[@]}" | xargs -I{} basename "{}")
chosen_basename=$(printf "%s\n" "$choices" | $WOFI_BIN --dmenu --prompt="Выбрать обои" --hide-scroll --columns=1 --width=640 --height=400 --location=center)

if [ -z "$chosen_basename" ]; then
    exit 0
fi

# Найдём полный путь по basename (первое совпадение)
wallpaper=""
for p in "${wallpapers[@]}"; do
    if [ "$(basename "$p")" = "$chosen_basename" ]; then
        wallpaper="$p"
        break
    fi
done

if [ -z "$wallpaper" ]; then
    echo "❌ Не удалось найти файл: $chosen_basename"
    exit 1
fi

# Запускаем pywal если доступен
if [ -n "$WAL_BIN" ] && [ -x "$WAL_BIN" ]; then
    "$WAL_BIN" -i "$wallpaper" -q || true
fi

# Пытаемся загрузить цвета из pywal
WAL_COLORS="$HOME_DIR/.cache/wal/colors.sh"
if [ -f "$WAL_COLORS" ]; then
    # shellcheck disable=SC1090
    source "$WAL_COLORS" || true
fi

bg="${background:-$bg_default}"
fg="${foreground:-$fg_default}"
border_col="${color4:-$border_default}"
accent="${color5:-$accent_default}"
danger="${color1:-$danger_default}"

# Пишем waybar colors.css
cat > "$WAYBAR_COLORS" <<EOF
@define-color bg ${bg};
@define-color fg ${fg};
@define-color border ${border_col};
@define-color accent ${accent};
@define-color danger ${danger};
EOF

# Пишем wofi style.css (в конфиг пользователя)
mkdir -p "$(dirname "$WOFI_STYLE")"
cat > "$WOFI_STYLE" <<EOF
window { background-color: transparent; border: none; }
#outer-box { background-color: alpha(${bg}, 0.98); border: 2px solid ${border_col}; border-radius: 16px; padding: 12px; }
#input { background-color: alpha(${fg}, 0.06); color: ${fg}; border: 2px solid ${border_col}; border-radius: 12px; margin-bottom: 8px; padding: 10px 12px; font-size: 14px; }
#entry { border-radius: 8px; padding: 8px; margin: 6px; background-color: transparent; border: 2px solid transparent; }
#entry:hover { border: 2px solid ${border_col}; background-color: alpha(${border_col}, 0.06); }
#entry:selected { border: 2px solid ${border_col}; background-color: alpha(${border_col}, 0.08); }
#text { color: ${fg}; }
#img, image { border-radius: 6px; }
EOF

# Сохраняем путь обоев
echo "$wallpaper" > "$CACHE_WALL"

# Применяем обои
if command -v swaybg >/dev/null 2>&1; then
    swaybg -o '*' -i "$wallpaper" >/dev/null 2>&1 &
elif command -v feh >/dev/null 2>&1; then
    feh --bg-fill "$wallpaper"
fi

# Перезагружаем waybar, чтобы подхватил новые цвета
sleep 0.2
killall waybar 2>/dev/null || true
sleep 0.1
waybar >/dev/null 2>&1 &

# Синхронизация greetd (если есть)
SYNC_SCRIPT="$SCRIPT_DIR/sync-greetd-theme.sh"
if [ -f "$SYNC_SCRIPT" ] && [ -x "$SYNC_SCRIPT" ]; then
    "$SYNC_SCRIPT" 2>/dev/null || true
fi

notify-send "Тема" "Применены обои: $(basename "$wallpaper")" 2>/dev/null
