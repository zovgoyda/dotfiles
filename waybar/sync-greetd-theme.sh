#!/bin/bash
# Синхронизация темы greetd с pywal

set -e

WAL_COLORS="$HOME/.cache/wal/colors.sh"
GREETD_CONF="/etc/greetd/regreet.toml"
GREETD_THEME="/etc/greetd/theme"

# Проверяем права доступа
if [ ! -w "$GREETD_CONF" ] || [ ! -w "$GREETD_THEME" ]; then
    exit 0
fi

# Загружаем цвета
if [ ! -f "$WAL_COLORS" ]; then
    exit 0
fi

source "$WAL_COLORS"

# Копируем обои
if [ -f "$HOME/.cache/current_wallpaper" ]; then
    wallpaper=$(cat "$HOME/.cache/current_wallpaper")
    if [ -f "$wallpaper" ]; then
        cp "$wallpaper" "$GREETD_THEME/wall.png" 2>/dev/null || true
    fi
fi

# Генерируем CSS для regreet
cat > "$GREETD_THEME/regreet.css" 2>/dev/null << EOF || true
* {
    background-color: ${background:-#0b0e19};
    color: ${foreground:-#c2c2c5};
}

window {
    background-image: url("file://$GREETD_THEME/wall.png");
    background-size: cover;
}

#login_box, dialog {
    background-color: rgba(11, 14, 25, 0.85);
    border: 2px solid ${color4:-#8A778F};
    border-radius: 12px;
}

entry {
    background-color: rgba(255, 255, 255, 0.05);
    color: ${foreground:-#c2c2c5};
    border: 1px solid ${color4:-#8A778F};
    border-radius: 6px;
}

button {
    background-color: ${color4:-#8A778F};
    color: #ffffff;
}

button:hover {
    background-color: ${color5:-#5999D0};
}
EOF

echo "✅ greetd синхронизирован"
