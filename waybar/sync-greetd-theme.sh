#!/bin/bash
# Синхронизирует фон и цвета экрана входа (greetd + gtkgreet)
# с текущими обоями и pywal-палитрой.

GREETD_THEME_DIR="/etc/greetd/theme"
WAL_COLORS="$HOME/.cache/wal/colors.sh"
WALLPAPER_FILE="$HOME/.cache/current_wallpaper"

# --- 1. АВТОПОДСТАНОВКА ИМЕНИ ПОЛЬЗОВАТЕЛЯ ---
# Создаём файл .xsession (или .desktop) для gtkgreet, который подставит имя
USER_FILE="$GREETD_THEME_DIR/user.txt"
echo "goyda" > "$USER_FILE" 2>/dev/null

# --- 2. СКРЫВАЕМ ЛОГИ ---
# Все выводы скрипта перенаправляем в /dev/null, кроме ошибок
exec 2>/dev/null  # скрываем ошибки тоже, если нужно

# --- 3. ИСПРАВЛЯЕМ ИМЯ СЕССИИ ---
# Создаём символическую ссылку niri -> niri-session (если niri-session существует)
if command -v niri-session &>/dev/null && [ ! -f /usr/local/bin/niri ]; then
    sudo ln -sf "$(which niri-session)" /usr/local/bin/niri 2>/dev/null
fi

# --- ОСНОВНАЯ ЛОГИКА СКРИПТА (без изменений) ---
if [ ! -d "$GREETD_THEME_DIR" ]; then
    exit 0  # тихий выход без уведомлений
fi

if [ ! -w "$GREETD_THEME_DIR" ]; then
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

cp "$WALLPAPER" "$GREETD_THEME_DIR/wall.png" 2>/dev/null

cat > "$GREETD_THEME_DIR/style.css" <<EOF
window {
    background-image: url("file://$GREETD_THEME_DIR/wall.png");
    background-size: cover;
    background-position: center;
}
box#body {
    background-color: alpha(${background}, 0.85);
    border: 2px solid ${color4};
    border-radius: 20px;
    padding: 40px;
}
label {
    color: ${foreground};
}
entry {
    background-color: alpha(${foreground}, 0.06);
    color: ${foreground};
    border: 2px solid ${color4};
    border-radius: 12px;
    padding: 8px 12px;
}
button {
    background-color: alpha(${color5}, 0.3);
    color: ${foreground};
    border: 2px solid ${color5};
    border-radius: 10px;
    padding: 6px 16px;
}
button:hover {
    background-color: alpha(${color5}, 0.5);
}
EOF

# Убираем все уведомления (notify-send) для полной тишины
# notify-send "greetd" "Тема экрана входа синхронизирована" 2>/dev/null
