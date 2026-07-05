#!/usr/bin/env bash

# 1. Подгружаем цвета Pywal
WAL_COLORS="$HOME/.cache/wal/colors.sh"
if [ -f "$WAL_COLORS" ]; then
    source "$WAL_COLORS"
else
    background="#2e1a47"
    color4="#4a2c73"
    color5="#4a2c73"
fi

# 2. Создаем временный файл стилей для wofi
WOFI_STYLE=$(mktemp)
cat <<EOF > "$WOFI_STYLE"
window {
    background-color: $background;
}
#entry:selected {
    background-color: $color4;
}
#text:selected {
    color: $color5;
}
EOF

# 3. Логика cliphist + wofi с применением стиля
if [ -z "$@" ]; then
    # Показываем меню wofi со стилями, выбранный элемент передается этому же скрипту
    cliphist list | wofi --dmenu --style "$WOFI_STYLE" | xargs -I {} "$0" "{}"
else
    # Декодируем и копируем в буфер обмена
    echo "$@" | cliphist decode | wl-copy
fi

# 4. Удаляем временный файл стиля
rm "$WOFI_STYLE"
