#!/bin/bash
# Автоматически синхронизирует тему greetd/regreet при изменении
# цветов pywal или обоев (использует inotify для отслеживания файлов)

WAL_COLORS="$HOME/.cache/wal/colors.sh"
WALLPAPER_FILE="$HOME/.cache/current_wallpaper"
SYNC_SCRIPT="$HOME/.config/waybar/sync-greetd-theme.sh"

# Проверяем наличие inotify-tools
if ! command -v inotifywait &> /dev/null; then
    echo "Error: inotify-tools не установлен. Установите его:" >&2
    echo "  sudo pacman -S inotify-tools  # Arch" >&2
    echo "  sudo apt install inotify-tools  # Debian/Ubuntu" >&2
    exit 1
fi

# Проверяем наличие скрипта синхронизации
if [ ! -x "$SYNC_SCRIPT" ]; then
    echo "Error: $SYNC_SCRIPT не найден или не исполняемый" >&2
    exit 1
fi

echo "Запущен watcher для синхронизации greetd/regreet темы..."
echo "Отслеживаем: $WAL_COLORS $WALLPAPER_FILE"

# Следим за изменениями файлов и запускаем скрипт синхронизации
inotifywait -m -e modify "$WAL_COLORS" "$WALLPAPER_FILE" 2>/dev/null |
while read -r path action file; do
    echo "[$(date '+%H:%M:%S')] Обнаружено изменение: $file"
    bash "$SYNC_SCRIPT"
done
