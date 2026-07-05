#!/bin/bash
# Меняет обои и генерирует тему на всё окружение через pywal

WALLPAPER_DIR="/home/goyda/SSD/wallpapers"
WAL_BIN="/home/goyda/.local/bin/wal"
THUMB_DIR="$HOME/.cache/theme_thumbs"
WAL_COLORS="$HOME/.cache/wal/colors.sh"
THUMB_SIZE=220

mkdir -p "$HOME/.cache" "$THUMB_DIR"
[ -f "$HOME/.cache/current_wallpaper" ] || touch "$HOME/.cache/current_wallpaper"

if [ -f "$WAL_COLORS" ]; then
    source "$WAL_COLORS"
else
    background="#2e1a47"
    foreground="#ffffff"
    color4="#4a2c73"
    color5="#4a2c73"
    color1="#ff6b6b"
    color8="#666666"
fi

WOFI_STYLE=$(mktemp)
WOFI_CONF=$(mktemp)
: > "$WOFI_CONF"

cat > "$WOFI_STYLE" << CSS
window {
    background-color: transparent;
    border: none;
}
#outer-box {
    background-color: alpha(${background}, 0.97);
    border: 2px solid ${color4};
    border-radius: 20px;
    padding: 16px;
}
#input {
    background-color: shade(${background}, 0.75);
    color: #ffffff;
    border: 1px solid ${color4};
    border-radius: 12px;
    margin-bottom: 10px;
    padding: 10px;
    font-size: 13px;
}
#entry {
    border-radius: 10px;
    padding: 2px;
    margin: 3px;
    background-color: transparent;
    border: 1px solid transparent;
    min-width: 220px;
}
#entry:hover {
    border: 1px solid alpha(${color4}, 0.7);
}
#entry:selected {
    border: 2px solid ${color5};
}
#text {
    opacity: 0;
    min-height: 0px;
    min-width: 0px;
}
#img, image {
    border-radius: 8px;
}
CSS

CONVERT_BIN=$(command -v convert || command -v magick)

if [ ! -x "$WAL_BIN" ]; then
    notify-send "Ошибка" "pywal не найден по пути $WAL_BIN" 2>/dev/null
    rm "$WOFI_STYLE"
    exit 1
fi

if [ ! -d "$WALLPAPER_DIR" ]; then
    notify-send "Ошибка" "Папка не найдена: $WALLPAPER_DIR" 2>/dev/null
    rm "$WOFI_STYLE"
    exit 1
fi

shopt -s nullglob nocaseglob
choice=$(
    for img in "$WALLPAPER_DIR"/*.jpg "$WALLPAPER_DIR"/*.jpeg "$WALLPAPER_DIR"/*.png "$WALLPAPER_DIR"/*.webp; do
        name=$(basename "$img")
        thumb="$THUMB_DIR/$name.png"

        if [ -n "$CONVERT_BIN" ]; then
            if [ ! -f "$thumb" ] || [ "$img" -nt "$thumb" ]; then
                "$CONVERT_BIN" "$img" \
                    -resize "${THUMB_SIZE}x${THUMB_SIZE}^" -gravity center -extent "${THUMB_SIZE}x${THUMB_SIZE}" \
                    "$thumb" 2>>"$HOME/.cache/theme_thumbs_errors.log"
            fi
            [ -f "$thumb" ] && icon_path="$thumb" || icon_path="$img"
        else
            icon_path="$img"
        fi

        printf 'img:%s:text:%s\n' "$icon_path" "$name"
    done | wofi --conf="$WOFI_CONF" --dmenu --allow-images --define=image_size="${THUMB_SIZE}" --style="$WOFI_STYLE" --width=1250 --height=520 --columns=5 --hide-scroll --location=center --prompt="Выбери обои:"
)
shopt -u nullglob nocaseglob

rm "$WOFI_STYLE" "$WOFI_CONF"
[ -z "$choice" ] && exit 0

NAME=$(echo "$choice" | sed -n 's/^img:.*:text:\(.*\)$/\1/p')
WALLPAPER="$WALLPAPER_DIR/$NAME"

if [ -z "$NAME" ] || [ ! -f "$WALLPAPER" ]; then
    notify-send "Ошибка" "Файл не найден: $WALLPAPER" 2>/dev/null
    exit 1
fi

"$WAL_BIN" -i "$WALLPAPER" -n -q
source "$WAL_COLORS"

echo "$WALLPAPER" > "$HOME/.cache/current_wallpaper"
pkill swaybg 2>/dev/null
swaybg -i "$WALLPAPER" -m fill &
disown

# Генерируем colors.css для waybar
cat > "$HOME/.config/waybar/colors.css" << CSSEOF
@define-color bg ${background};
@define-color fg ${foreground};
@define-color border ${color4};
@define-color accent ${color5};
@define-color danger ${color1};
CSSEOF

# Генерируем style.css для wofi со всеми цветами встроенными (без импорта)
mkdir -p "$HOME/.config/wofi"
cat > "$HOME/.config/wofi/style.css" << CSSEOF
window {
    background-color: transparent;
    border: none;
}

#outer-box {
    background-color: alpha(${background}, 0.97);
    border: 2px solid ${color4};
    border-radius: 20px;
    padding: 16px;
}

#input {
    background-color: alpha(${background}, 0.85);
    color: ${foreground};
    border: 2px solid ${color4};
    border-radius: 12px;
    margin-bottom: 10px;
    padding: 10px 15px;
    font-size: 14px;
}

#entry {
    border-radius: 10px;
    padding: 6px;
    margin: 3px;
    background-color: transparent;
    border: 1px solid transparent;
    min-width: 220px;
}

#entry:hover {
    border: 1px solid ${color4};
    background-color: alpha(${color4}, 0.2);
}

#entry:selected {
    border: 2px solid ${color5};
    background-color: alpha(${color5}, 0.3);
}

#text {
    color: ${foreground};
    font-size: 13px;
}

#img, image {
    border-radius: 8px;
}
CSSEOF

# Генерируем colors.kdl для niri
mkdir -p "$HOME/.config/niri/add"
cat > "$HOME/.config/niri/add/colors.kdl" << KDLEOF
overview {
    backdrop-color "${background}"
}

layout {
    background-color "${background}"
    focus-ring {
        active-color "${color5}"
        inactive-color "${color8}"
    }
}
KDLEOF

pkill waybar 2>/dev/null
waybar &
disown

niri msg action load-config-file 2>/dev/null

if pgrep -x kitty &>/dev/null; then
    kill -SIGUSR1 $(pgrep -x kitty) 2>/dev/null
fi

notify-send "Тема применена" "$(basename "$WALLPAPER")" 2>/dev/null
