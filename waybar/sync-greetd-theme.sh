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

# 2. Генерируем кастомный CSS для принудительного применения цветов Pywal и темной темы
cat > "$GREETD_THEME_DIR/regreet.css" <<EOF
/* Принудительный темный режим для всех элементов */
window, dialog, box, label, entry, button {
    color: ${foreground};
}

/* Окно логина (карточка по центру) */
.card, dialog {
    background-color: alpha(${background}, 0.85);
    border: 2px solid ${color4};
    border-radius: 16px;
    padding: 25px;
}

/* Поля ввода */
entry {
    background-color: alpha(${foreground}, 0.06);
    border: 2px solid ${color4};
    border-radius: 10px;
}
entry:focus {
    border-color: ${color5};
}

/* Кнопки */
button {
    background-color: alpha(${color5}, 0.2);
    border: 1px solid ${color5};
    border-radius: 8px;
}
button:hover {
    background-color: alpha(${color5}, 0.4);
}
EOF

# 3. Генерируем конфигурацию ReGreet с правильными командами dinit (loginctl)
cat > "$REGREET_CONF" <<EOF
[background]
path = "$GREETD_THEME_DIR/wall.png"
fit = "Cover"

[GTK]
# Накладываем наш CSS-файл с цветами поверх стандартной темы
custom_css = "$GREETD_THEME_DIR/regreet.css"
font_name = "JetBrains Mono 12"

[commands]
# Исправлено на loginctl для dinit/artix
reboot = [ "loginctl", "reboot" ]
poweroff = [ "loginctl", "poweroff" ]
EOF
