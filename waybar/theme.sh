#!/bin/bash
# Меняет обои и генерирует тему

set -e

# Пути
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME_DIR="$HOME"
WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME_DIR/wallpapers}"
WAL_BIN="${WAL_BIN:-$(command -v wal)}"

# Проверки
if [ ! -x "$WAL_BIN" ]; then
    echo "❌ pywal не найден"
    exit 1
fi

if [ ! -d "$WALLPAPER_DIR" ]; then
    echo "❌ Папка обоев не найдена: $WALLPAPER_DIR"
    exit 1
fi

# Получаем список обоев
shopt -s nullglob
wallpapers=("$WALLPAPER_DIR"/*.{jpg,jpeg,png,webp})

if [ ${#wallpapers[@]} -eq 0 ]; then
    echo "❌ Обои не найдены в $WALLPAPER_DIR"
    exit 1
fi

echo "📋 Доступные обои:"
for i in "${!wallpapers[@]}"; do
    echo "  $((i+1)). $(basename "${wallpapers[$i]}")"
done

echo ""
read -p "🖼️  Выбери номер обоев (1-${#wallpapers[@]}): " choice

if ! [[ $choice =~ ^[0-9]+$ ]] || [ $choice -lt 1 ] || [ $choice -gt ${#wallpapers[@]} ]; then
    echo "❌ Неверный выбор"
    exit 1
fi

wallpaper="${wallpapers[$((choice-1))]}"

echo ""
echo "🔄 Применяю тему для: $(basename "$wallpaper")..."

# Генерируем палитру через pywal
"$WAL_BIN" -i "$wallpaper" -q

# Сохраняем путь
echo "$wallpaper" > "$HOME_DIR/.cache/current_wallpaper"

# Применяем обои
swaybg -o '*' -i "$wallpaper" >/dev/null 2>&1 &

# Перезагружаем waybar
sleep 0.3
killall waybar 2>/dev/null || true
sleep 0.2
waybar >/dev/null 2>&1 &

# Синхронизируем greetd
SYNC_SCRIPT="$SCRIPT_DIR/sync-greetd-theme.sh"
if [ -f "$SYNC_SCRIPT" ] && [ -x "$SYNC_SCRIPT" ]; then
    "$SYNC_SCRIPT" 2>/dev/null || true
fi

echo "✅ Тема применена: $(basename "$wallpaper")"
