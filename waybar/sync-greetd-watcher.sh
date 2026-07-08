#!/bin/bash
# Мониторит изменения pywal цветов и обоев
# Автоматически синхронизирует greetd/regreet при изменении
# 
# Использование: запусти в фоне
#   bash ~/.config/waybar/sync-greetd-watcher.sh &
# 
# Или добавь в конфиг WM (niri):
#   exec-once = ["~/.config/waybar/sync-greetd-watcher.sh"]

WAL_COLORS="$HOME/.cache/wal/colors.sh"
WALLPAPER_FILE="$HOME/.cache/current_wallpaper"
SYNC_SCRIPT="$HOME/.config/waybar/sync-greetd-theme.sh"

# Проверяем зависимости
if ! command -v inotifywait &> /dev/null; then
    echo "❌ Error: inotify-tools не установлен" >&2
    echo "   Установи: sudo pacman -S inotify-tools" >&2
    echo "   Или:     sudo apt install inotify-tools" >&2
    exit 1
fi

if [ ! -x "$SYNC_SCRIPT" ]; then
    echo "❌ Error: $SYNC_SCRIPT не найден" >&2
    exit 1
fi

echo "🔄 Запускаю watcher для синхронизации greetd/regreet"
echo "   Отслеживаю: $WAL_COLORS"
echo "   Отслеживаю: $WALLPAPER_FILE"
echo "   Нажми Ctrl+C для остановки"
echo ""

# Следим за изменениями файлов
inotifywait -m -e modify "$WAL_COLORS" "$WALLPAPER_FILE" 2>/dev/null |
while read -r path action file; do
    echo "[$(date '+%H:%M:%S')] Обнаружено изменение: $file"
    bash "$SYNC_SCRIPT"
done
