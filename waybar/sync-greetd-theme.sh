#!/bin/bash
# Синхронизирует фон и цвета экрана входа (greetd + regreet)
# с текущими обоями и pywal-палитрой.

REGREET_CONF="/etc/greetd/regreet.toml"
GREETD_THEME_DIR="/etc/greetd/theme"
WAL_COLORS="$HOME/.cache/wal/colors.sh"
WALLPAPER_FILE="$HOME/.cache/current_wallpaper"

exec 2>/dev/null # Скрываем логи

if [ ! -w "$REGREET_CONF" ] || [ ! -w "$GREETD_THEME_DIR" ]; then
    exit 0 
fi

if [ -f "$WAL_COLORS" ]; then
    source "$WAL_COLORS"
else
    background="#0b0e19"
    foreground="#c2c2c5"
    color4="#8A778F"
    color5="#5999D0"
fi

if [ -f "$WALLPAPER_FILE" ]; then
    WALLPAPER=$(cat "$WALLPAPER_FILE")
fi

if [ -z "$WALLPAPER" ] || [ ! -f "$WALLPAPER" ]; then
    exit 0
fi

# 1. Копируем обои
cp "$WALLPAPER" "$GREETD_THEME_DIR/wall.png" 2>/dev/null

# 2. Генерируем CSS (только убираем дефолтные белые подложки, чтобы видеть обои)
cat > "$GREETD_THEME_DIR/regreet.css" <<EOF
window, main, .background {
    background-color: transparent !important;
    background-image: none !important;
}

/* Принудительный хак для центрального контейнера авторизации */
box#container, box#login_box, dialog {
    background-color: rgba($(printf "%d %d %d" 0x${background:1:2} 0x${background:3:2} 0x${background:5:2} | sed 's/ /, /g'), 0.85) !important;
    color: ${foreground} !important;
    border: 2px solid ${color4} !important;
    border-radius: 16px !important;
}

entry {
    background-color: rgba(255, 255, 255, 0.05) !important;
    color: ${foreground} !important;
    border: 1px solid ${color4} !important;
}
EOF

chmod 644 "$GREETD_THEME_DIR/regreet.css"
chmod 644 "$GREETD_THEME_DIR/wall.png"

# 3. Конфигурация ReGreet (Жестко заставляем его быть темным через TOML параметры)
cat > "$REGREET_CONF" <<EOF
[background]
path = "$GREETD_THEME_DIR/wall.png"
fit = "Cover"

[GTK]
custom_css = "$GREETD_THEME_DIR/regreet.css"
font_name = "JetBrains Mono 12"
# Вот эта строчка заставит ReGreet использовать темные цвета Adwaita встроенным движком
application_prefer_dark_theme = true

[commands]
reboot = [ "loginctl", "reboot" ]
poweroff = [ "loginctl", "poweroff" ]
EOF

chmod 644 "$REGREET_CONF"
