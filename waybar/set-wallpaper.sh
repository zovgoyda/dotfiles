#!/bin/bash
CACHE_DIR="$HOME/.cache"
WALLPAPER_FILE="$CACHE_DIR/current_wallpaper"

mkdir -p "$CACHE_DIR"
[ -f "$WALLPAPER_FILE" ] || touch "$WALLPAPER_FILE"

if [ -s "$WALLPAPER_FILE" ]; then
    WALLPAPER=$(cat "$WALLPAPER_FILE")
    if [ -f "$WALLPAPER" ]; then
        exec swaybg -i "$WALLPAPER" -m fill
    fi
fi

# fallback, если обоев ещё не выбирали или файл битый
exec swaybg -c "#2e1a47"
