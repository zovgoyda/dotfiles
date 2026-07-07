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

# 2. Генерируем CSS с принудительными точными GTK4/Adwaita селекторами
cat > "$GREETD_THEME_DIR/regreet.css" <<EOF
/* Главное окно и задний фон */
window, main {
    background-color: transparent;
    color: ${foreground};
}

/* Табличка/карточка по центру (главный контейнер ReGreet) */
/* В GTK4 ReGreet использует кастомный селектор или .background для контейнеров */
.card, dialog, box#container, box#login_box, grid {
    background-color: rgba($(printf "%d %d %d" 0x${background:1:2} 0x${background:3:2} 0x${background:5:2} | sed 's/ /, /g'), 0.85) !important;
    color: ${foreground} !important;
    border: 2px solid ${color4} !important;
    border-radius: 16px !important;
    padding: 20px;
}

/* Поля ввода (Логин / Пароль) */
entry, textview {
    background-color: rgba(255, 255, 255, 0.07) !important;
    color: ${foreground} !important;
    border: 1px solid ${color4} !important;
    border-radius: 8px !important;
}

entry:focus {
    border-color: ${color5} !important;
}

/* Текст внутри карточки */
label, title {
    color: ${foreground} !important;
}

/* Кнопки */
button {
    background-color: rgba($(printf "%d %d %d" 0x${color5:1:2} 0x${color5:3:2} 0x${color5:5:2} | sed 's/ /, /g'), 0.2) !important;
    color: ${foreground} !important;
    border: 1px solid ${color5} !important;
    border-radius: 8px !important;
}
button:hover {
    background-color: rgba($(printf "%d %d %d" 0x${color5:1:2} 0x${color5:3:2} 0x${color5:5:2} | sed 's/ /, /g'), 0.4) !important;
}
EOF

# ОЧЕНЬ ВАЖНО: Разрешаем пользователю greeter читать наш сгенерированный CSS
chmod 644 "$GREETD_THEME_DIR/regreet.css"
chmod 644 "$GREETD_THEME_DIR/wall.png"

# 3. Генерируем конфигурацию ReGreet 
cat > "$REGREET_CONF" <<EOF
[background]
path = "$GREETD_THEME_DIR/wall.png"
fit = "Cover"

[GTK]
# Отключаем принудительно Adwaita-light, подключая наш CSS
custom_css = "$GREETD_THEME_DIR/regreet.css"
font_name = "JetBrains Mono 12"

[commands]
reboot = [ "loginctl", "reboot" ]
poweroff = [ "loginctl", "poweroff" ]
EOF

chmod 644 "$REGREET_CONF"
