#!/bin/bash
# Выводит иконку текущей темы для waybar custom/theme модуля

GTK3_INI="$HOME/.config/gtk-3.0/settings.ini"

if grep -q "gtk-application-prefer-dark-theme=1" "$GTK3_INI" 2>/dev/null; then
    echo "🌙"
else
    echo "☀️"
fi
