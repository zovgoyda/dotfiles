#!/bin/bash

WOFI_STYLE=$(mktemp)

WAL_COLORS="$HOME/.cache/wal/colors.sh"
if [ -f "$WAL_COLORS" ]; then
    source "$WAL_COLORS"
else
    background="#2e1a47"
    color4="#4a2c73"
    color5="#4a2c73"
fi

# ==================== АДАПТИВНЫЕ РАЗМЕРЫ ====================
# Получаем разрешение экрана
SCREEN_WIDTH=$(xrandr 2>/dev/null | grep " connected" | head -1 | grep -oP '\d+x\d+' | cut -d'x' -f1 || echo "3440")

# Масштабируем размеры меню в зависимости от разрешения
MENU_WIDTH=$(echo "scale=0; $SCREEN_WIDTH * 0.2" | bc)
MENU_HEIGHT=$(echo "scale=0; $SCREEN_WIDTH * 0.06" | bc)
ITEM_SIZE=$(echo "scale=0; $MENU_WIDTH * 0.8" | bc)

[ "$MENU_WIDTH" -lt 200 ] && MENU_WIDTH=200
[ "$MENU_HEIGHT" -lt 120 ] && MENU_HEIGHT=120
[ "$ITEM_SIZE" -lt 100 ] && ITEM_SIZE=100

echo "
window {
    background-color: transparent;
    background-image: none;
    box-shadow: none;
    border: none;
    padding: 0px;
    margin: 0px;
}
decoration {
    background-color: transparent;
    background-image: none;
    box-shadow: none;
    border: none;
    border-radius: 0px;
}
#input {
    min-height: 0px;
    min-width: 0px;
    padding: 0px;
    margin: 0px;
    border: none;
    background-color: transparent;
    background-image: none;
    color: transparent;
    caret-color: transparent;
}
#input image {
    opacity: 0;
    min-width: 0px;
    min-height: 0px;
    -gtk-icon-transform: scale(0);
}
#outer-box {
    background-color: transparent;
    background-image: none;
    box-shadow: none;
    margin: 0px;
    padding: 0px;
    border: none;
}
#inner-box {
    background-color: transparent;
    background-image: none;
    box-shadow: none;
    margin: 0px;
    padding: 0px;
    border: none;
}
#scroll {
    background-color: transparent;
    background-image: none;
    box-shadow: none;
    margin: 0px;
    padding: 0px;
    border: none;
}
#entry {
    background-color: ${background};
    background-image: none;
    box-shadow: none;
    border: 2px solid ${color4};
    border-radius: 16px;
    padding: 8px;
    margin: 6px;
    min-width: ${ITEM_SIZE}px;
    max-width: ${ITEM_SIZE}px;
    min-height: ${ITEM_SIZE}px;
}
#entry:selected {
    background-color: ${color5};
}
#text {
    font-family: FontAwesome;
    font-size: 36px;
    color: #ffffff;
}
#text:selected {
    color: #ffffff;
}
" > "$WOFI_STYLE"

ICON_POWER=$(printf '\xEF\x80\x91')
ICON_REBOOT=$(printf '\xEF\x8B\xB9')
ICON_LOGOUT=$(printf '\xEF\x82\x8B')
ICON_LOCK=$(printf '\xEF\x80\xA3')

choice=$(printf '%s\n%s\n%s\n%s\n' "$ICON_POWER" "$ICON_REBOOT" "$ICON_LOGOUT" "$ICON_LOCK" | \
    wofi --dmenu --style="$WOFI_STYLE" --width=$MENU_WIDTH --height=$MENU_HEIGHT --columns=4 --hide-scroll --prompt="" --location=center)

case "$choice" in
    "$ICON_POWER")
        loginctl poweroff
        ;;
    "$ICON_REBOOT")
        loginctl reboot
        ;;
    "$ICON_LOGOUT")
        loginctl terminate-session "$XDG_SESSION_ID"
        ;;
    "$ICON_LOCK")
        swaylock
        ;;
esac

rm "$WOFI_STYLE"
