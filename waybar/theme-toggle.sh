#!/bin/bash
# Переключает GTK-приложения (и окружение) между тёмной и светлой темой.
# Использование: theme-toggle.sh [dark|light]   (без аргумента — toggle)

GTK3_INI="$HOME/.config/gtk-3.0/settings.ini"
GTK4_INI="$HOME/.config/gtk-4.0/settings.ini"

current() {
    grep -q "gtk-application-prefer-dark-theme=1" "$GTK3_INI" 2>/dev/null && echo "dark" || echo "light"
}

set_mode() {
    local mode="$1"
    local val
    [ "$mode" = "dark" ] && val=1 || val=0

    for f in "$GTK3_INI" "$GTK4_INI"; do
        [ -f "$f" ] || continue
        if grep -q "^gtk-application-prefer-dark-theme=" "$f"; then
            sed -i "s/^gtk-application-prefer-dark-theme=.*/gtk-application-prefer-dark-theme=${val}/" "$f"
        else
            echo "gtk-application-prefer-dark-theme=${val}" >> "$f"
        fi
    done

    # Сообщаем портлам/GNOME-приложениям (libadwaita слушает именно это)
    if command -v gsettings >/dev/null; then
        gsettings set org.gnome.desktop.interface color-scheme "prefer-${mode}" 2>/dev/null
    fi

    notify-send "Тема" "Режим: ${mode}" 2>/dev/null
}

MODE="$1"
if [ -z "$MODE" ]; then
    [ "$(current)" = "dark" ] && MODE="light" || MODE="dark"
fi

set_mode "$MODE"
