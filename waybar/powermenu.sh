#!/bin/bash
# Простое меню выключения с иконками

WAL_COLORS="$HOME/.cache/wal/colors.sh"

# Загружаем цвета если есть
if [ -f "$WAL_COLORS" ]; then
    source "$WAL_COLORS"
    bg="${background}"
    fg="${foreground}"
    c1="${color1:-#ff6b6b}"
else
    bg="#2e1a47"
    fg="#ffffff"
    c1="#ff6b6b"
fi

# Создаём CSS
WOFI_STYLE=$(mktemp)
cat > "$WOFI_STYLE" << EOF
window {
    background-color: transparent;
    border: none;
}
main {
    background-color: transparent;
}
#outer-box {
    background-color: rgba(46, 26, 71, 0.9);
    border: 2px solid #7fc8ff;
    border-radius: 16px;
    padding: 20px;
}
#inner-box {
    background-color: transparent;
}
#scroll {
    background-color: transparent;
}
#entry {
    background-color: transparent;
    border: 2px solid transparent;
    border-radius: 8px;
    padding: 15px;
    margin: 5px;
    font-size: 32px;
}
#entry:hover {
    border: 2px solid #7fc8ff;
    background-color: rgba(127, 200, 255, 0.2);
}
#entry:selected {
    border: 2px solid #7fc8ff;
    background-color: rgba(127, 200, 255, 0.3);
}
#text {
    color: #ffffff;
}
EOF

# Иконки
echo -e "\uf011\n\uf01e\n\uf08b\n\uf023" | \
wofi --dmenu --style="$WOFI_STYLE" \
    --width=400 --height=250 \
    --columns=4 --hide-scroll \
    --prompt="" --location=center | \
while read -r choice; do
    case "$choice" in
        $'\uf011') loginctl poweroff ;;
        $'\uf01e') loginctl reboot ;;
        $'\uf08b') loginctl terminate-session "$XDG_SESSION_ID" ;;
        $'\uf023') swaylock ;;
    esac
done

rm -f "$WOFI_STYLE"
