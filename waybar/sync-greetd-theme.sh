#!/bin/bash
# Синхронизирует фон и цвета экрана входа (greetd + regreet)
# с текущими обоями и pywal-палитрой.

REGREET_CONF="/etc/greetd/regreet.toml"
GREETD_THEME_DIR="/etc/greetd/theme"
WAL_COLORS="$HOME/.cache/wal/colors.sh"
WALLPAPER_FILE="$HOME/.cache/current_wallpaper"

exec 2>/dev/null # Скрываем логи

if [ ! -w "$REGREET_CONF" ] || [ ! -w "$GREETD_THEME_DIR" ]; then
    exit 0 # Тихий выход, если нет прав
fi

if [ -f "$WAL_COLORS" ]; then
    source "$WAL_COLORS"
else
    background="#0b0e19"
    foreground="#c2c2c5"
fi

if [ -f "$WALLPAPER_FILE" ]; then
    WALLPAPER=$(cat "$WALLPAPER_FILE")
fi

if [ -z "$WALLPAPER" ] || [ ! -f "$WALLPAPER" ]; then
    exit 0
fi

# Копируем обои в доступное для greeter место
cp "$WALLPAPER" "$GREETD_THEME_DIR/wall.png" 2>/dev/null

# Генерируем конфигурацию ReGreet с поддержкой GTK темы и обоев
cat > "$REGREET_CONF" <<EOF
[background]
path = "$GREETD_THEME_DIR/wall.png"
fit = "Cover"

[GTK]
# Используем темную тему, которая у вас прописана
theme_name = "adw-gtk3-dark"
icon_theme_name = "Adwaita"
font_name = "JetBrains Mono 12"

[commands]
# Команда завершения работы
reboot = [ "systemctl", "reboot" ]
poweroff = [ "systemctl", "poweroff" ]
EOF
