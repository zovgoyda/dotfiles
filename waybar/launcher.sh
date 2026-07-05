#!/bin/bash

WOFI_STYLE=$(mktemp)

echo "
window {
    background-color: #2e1a47;
    border: 2px solid #4a2c73;
    border-radius: 24px;
    padding: 20px;
}
#input {
    background-color: #1e1e2e;
    color: #ffffff;
    border: 2px solid #4a2c73;
    border-radius: 12px;
    padding: 10px;
    margin-bottom: 15px;
}
#entry {
    border-radius: 12px;
    padding: 8px;
    margin: 4px;
    min-height: 40px; /* Фиксируем высоту */
}
#entry:selected {
    background-color: #4a2c73;
}
#img {
    /* Принудительно задаем размер иконки */
    min-width: 32px;
    min-height: 32px;
    max-width: 32px;
    padding: 0px;
    margin-right: 12px;
    /* Убираем любые эффекты, которые могут обрезать изображение */
    -gtk-icon-transform: none;
}
#text {
    color: #ffffff;
    font-size: 15px;
}
" > "$WOFI_STYLE"

wofi --show drun --style="$WOFI_STYLE" --width=800 --height=500 --columns=3 --hide-scroll --term=foot --prompt="Поиск..."

rm "$WOFI_STYLE"
