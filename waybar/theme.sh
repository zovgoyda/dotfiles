#!/usr/bin/env bash
# Меняет обои через wofi и генерирует тему для waybar/wofi/greetd
# Выбор обоев через обычный wofi (список файлов), генерирует ~/.config/waybar/colors.css и ~/.config/wofi/style.css на основе pywal

set -euo pipefail

HOME_DIR="$HOME"
SCRIPT_DIR="$HOME_DIR/.config/waybar"
WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME_DIR/wallpapers}"
WAL_BIN="${WAL_BIN:-$(command -v wal || true)}"
WOFI_BIN="${WOFI_BIN:-$(command -v wofi || true)}"
WAYBAR_COLORS="$HOME_DIR/.config/waybar/colors.css"
WOFI_STYLE="$HOME_DIR/.config/wofi/style.css"
CACHE_WALL="$HOME_DIR/.cache/current_wallpaper"

# Fallback colors
bg_default="#0b0e19"
fg_default="#c2c2c5"
border_default="#3B7FC1"
accent_default="#578CBA"
danger_default="#485A6D"

hex_to_rgba() {
  local hex="${1#\#}"
  local alpha="$2"
  if [ ${#hex} -eq 3 ]; then
    hex="${hex:0:1}${hex:0:1}${hex:1:1}${hex:1:1}${hex:2:1}${hex:2:1}"
  fi
  local r=$((16#${hex:0:2}))
  local g=$((16#${hex:2:2}))
  local b=$((16#${hex:4:2}))
  printf 'rgba(%d,%d,%d,%.2f)' "$r" "$g" "$b" "$alpha"
}

if [ ! -d "$WALLPAPER_DIR" ]; then
    echo "❌ Папка обоев не найдена: $WALLPAPER_DIR"
    exit 1
fi

if [ -z "$WOFI_BIN" ]; then
    echo "❌ wofi не найден"
    exit 1
fi

# Находим файлы (чувствительность регистра не важна), поддерживаем пробелы
mapfile -d '' -t wallpapers < <(find "$WALLPAPER_DIR" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) -print0)

if [ ${#wallpapers[@]} -eq 0 ]; then
    echo "❌ Обои не найдены в $WALLPAPER_DIR"
    exit 1
fi

# Список basename для показа в wofi
mapfile -t basenames < <(for p in "${wallpapers[@]}"; do basename "$p"; done)

chosen=$(printf '%s\n' "${basenames[@]}" | $WOFI_BIN --dmenu --prompt="Выбрать обои" --hide-scroll --width=640 --height=400 --location=center)

if [ -z "$chosen" ]; then
    exit 0
fi

# Найти полный путь (первое совпадение)
wallpaper=""
for p in "${wallpapers[@]}"; do
  if [ "$(basename "$p")" = "$chosen" ]; then
    wallpaper="$p"
    break
  fi
done

if [ -z "$wallpaper" ]; then
  echo "❌ Не найден файл: $chosen"
  exit 1
fi

# Запускаем pywal если доступен
if [ -n "$WAL_BIN" ] && [ -x "$WAL_BIN" ]; then
  "$WAL_BIN" -i "$wallpaper" -q || true
fi

# Подгружаем цвета из pywal
WAL_COLORS="$HOME_DIR/.cache/wal/colors.sh"
[ -f "$WAL_COLORS" ] && source "$WAL_COLORS" || true

bg="${background:-$bg_default}"
fg="${foreground:-$fg_default}"
border_col="${color4:-$border_default}"
accent="${color5:-$accent_default}"
danger="${color1:-$danger_default}"

# Создаём rgba для hover (безопасно для wofi)
hover_bg=$(hex_to_rgba "${border_col#\#}" 0.06)
hover_bg_sel=$(hex_to_rgba "${border_col#\#}" 0.08)

# Пишем waybar colors.css (абсолютный путь, чтобы waybar точно видел)
mkdir -p "$(dirname "$WAYBAR_COLORS")"
cat > "$WAYBAR_COLORS" <<EOF
@define-color bg ${bg};
@define-color fg ${fg};
@define-color border ${border_col};
@define-color accent ${accent};
@define-color danger ${danger};
EOF

# Пишем wofi style.css (в конфиг пользователя) — избегаем alpha() вызовов
mkdir -p "$(dirname "$WOFI_STYLE")"
cat > "$WOFI_STYLE" <<EOF
window { background-color: transparent; border: none; }
#outer-box { background-color: ${bg}; border: 2px solid ${border_col}; border-radius: 16px; padding: 12px; }
#input { background-color: ${fg}; color: ${fg}; border: 2px solid ${border_col}; border-radius: 12px; margin-bottom: 8px; padding: 10px 12px; font-size: 14px; }
#entry { border-radius: 8px; padding: 8px; margin: 6px; background-color: transparent; border: 2px solid transparent; }
#entry:hover { border: 2px solid ${border_col}; background-color: ${hover_bg}; }
#entry:selected { border: 2px solid ${border_col}; background-color: ${hover_bg_sel}; }
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
SYNC_SCRIPT="$HOME_DIR/.config/waybar/sync-greetd-theme.sh"
if [ -f "$SYNC_SCRIPT" ] && [ -x "$SYNC_SCRIPT" ]; then
  "$SYNC_SCRIPT" 2>/dev/null || true
fi

notify-send "Тема" "Применены обои: $(basename "$wallpaper")" 2>/dev/null
