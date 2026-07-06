#!/bin/bash
# Синхронизирует фон и цвета экрана входа (greetd + gtkgreet)
# с текущими обоями и pywal-палитрой. Без sudo — папка темы принадлежит
# текущему пользователю (см. install.sh, GREETD_THEME_DIR=/etc/greetd/theme).

GREETD_THEME_DIR="/etc/greetd/theme"
WAL_COLORS="$HOME/.cache/wal/colors.sh"
WALLPAPER_FILE="$HOME/.cache/current_wallpaper"

if [ ! -d "$GREETD_THEME_DIR" ]; then
    notify-send "greetd" "Тема не найдена в $GREETD_THEME_DIR. Запусти install.sh заново." 2>/dev/null
    exit 1
fi

if [ ! -w "$GREETD_THEME_DIR" ]; then
    notify-send "greetd" "Нет прав на запись в $GREETD_THEME_DIR (нужно один раз выполнить install.sh)" 2>/dev/null
    exit 1
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
    notify-send "greetd" "Обои не найдены, синхронизация пропущена" 2>/dev/null
    exit 1
fi

cp "$WALLPAPER" "$GREETD_THEME_DIR/wall.png"

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

notify-send "greetd" "Тема экрана входа синхронизирована" 2>/dev/null
