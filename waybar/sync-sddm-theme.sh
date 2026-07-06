#!/bin/bash
# Синхронизирует фон и цвета экрана входа SDDM (where-is-my-sddm-theme)
# с текущими обоями и pywal-палитрой. Без sudo — папка темы принадлежит
# текущему пользователю (см. install.sh, ThemeDir=/usr/local/share/sddm-themes).

SDDM_THEME_DIR="/usr/local/share/sddm-themes/where_is_my_sddm_theme"
WAL_COLORS="$HOME/.cache/wal/colors.sh"
WALLPAPER_FILE="$HOME/.cache/current_wallpaper"

if [ ! -d "$SDDM_THEME_DIR" ]; then
    notify-send "SDDM" "Тема не найдена в $SDDM_THEME_DIR. Запусти install.sh заново." 2>/dev/null
    exit 1
fi

if [ ! -w "$SDDM_THEME_DIR" ]; then
    notify-send "SDDM" "Нет прав на запись в $SDDM_THEME_DIR (нужно один раз выполнить install.sh)" 2>/dev/null
    exit 1
fi

if [ -f "$WAL_COLORS" ]; then
    source "$WAL_COLORS"
else
    background="#0b0e19"
    foreground="#c2c2c5"
    color5="#5999D0"
fi

if [ -f "$WALLPAPER_FILE" ]; then
    WALLPAPER=$(cat "$WALLPAPER_FILE")
fi

if [ -z "$WALLPAPER" ] || [ ! -f "$WALLPAPER" ]; then
    notify-send "SDDM" "Обои не найдены, синхронизация пропущена" 2>/dev/null
    exit 1
fi

cp "$WALLPAPER" "$SDDM_THEME_DIR/wall.png"
cat > "$SDDM_THEME_DIR/theme.conf" <<EOF
[General]
background=wall.png
backgroundMode=fill
backgroundFillMode=fill
basicTextColor=${foreground}
passwordInputBackground=${background}
passwordTextColor=${foreground}
passwordCursorColor=${color5}
EOF

notify-send "SDDM" "Тема экрана входа синхронизирована" 2>/dev/null

