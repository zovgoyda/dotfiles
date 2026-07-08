#!/bin/bash
# Синхронизирует фон и цвета экрана входа (greetd + regreet)
# с текущими обоями и pywal-палитрой.

set -e

REGREET_CONF="/etc/greetd/regreet.toml"
GREETD_THEME_DIR="/etc/greetd/theme"
WAL_COLORS="$HOME/.cache/wal/colors.sh"
WALLPAPER_FILE="$HOME/.cache/current_wallpaper"

# Тихо - без ошибок если нет прав
exec 2>/dev/null

# Проверяем доступ к необходимым файлам
if [ ! -w "$REGREET_CONF" ] || [ ! -w "$GREETD_THEME_DIR" ]; then
    exit 0 
fi

# Загружаем цвета pywal (или используем дефолтные)
if [ -f "$WAL_COLORS" ]; then
    source "$WAL_COLORS"
else
    background="#0b0e19"
    foreground="#c2c2c5"
    color4="#8A778F"
    color5="#5999D0"
fi

# Читаем текущие обои
if [ -f "$WALLPAPER_FILE" ]; then
    WALLPAPER=$(cat "$WALLPAPER_FILE")
fi

# Выходим если нет обоев
if [ -z "$WALLPAPER" ] || [ ! -f "$WALLPAPER" ]; then
    exit 0
fi

# ========== 1. КОПИРУЕМ ОБОИ ==========
cp "$WALLPAPER" "$GREETD_THEME_DIR/wall.png" 2>/dev/null || true

# ========== 2. ГЕНЕРИРУЕМ CSS С ПРАВИЛЬНОЙ ПОДСТАНОВКОЙ ПЕРЕМЕННЫХ ==========
# Конвертируем hex цвета в RGB для rgba()
BG_RGB=$(printf "%d, %d, %d" 0x${background:1:2} 0x${background:3:2} 0x${background:5:2})

cat > "$GREETD_THEME_DIR/regreet.css" << CSSEOF
window, main, .background {
    background-color: transparent !important;
    background-image: none !important;
}

/* Контейнер авторизации с цветами из pywal */
box#container, box#login_box, dialog {
    background-color: rgba($BG_RGB, 0.85) !important;
    color: $foreground !important;
    border: 2px solid $color4 !important;
    border-radius: 16px !important;
}

/* Поля ввода */
entry {
    background-color: rgba(255, 255, 255, 0.05) !important;
    color: $foreground !important;
    border: 1px solid $color4 !important;
}
CSSEOF

chmod 644 "$GREETD_THEME_DIR/regreet.css" 2>/dev/null || true
chmod 644 "$GREETD_THEME_DIR/wall.png" 2>/dev/null || true

# ========== 3. ОБНОВЛЯЕМ КОНФИГ REGREET ==========
if [ -f "$REGREET_CONF" ]; then
    # Обновляем фон на рабочем столе в regreet
    sed -i 's|background = .*|background = "file:///etc/greetd/theme/wall.png"|' "$REGREET_CONF" 2>/dev/null || true
    # Обновляем CSS
    sed -i 's|.*css_file.*|    css_file = "/etc/greetd/theme/regreet.css"|' "$REGREET_CONF" 2>/dev/null || true
fi

exit 0
