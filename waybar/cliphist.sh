#!/usr/bin/env bash

# 1. Подгружаем цвета Pywal (с фолбэком на цвета из wofi/colors.css)
WAL_COLORS="$HOME/.cache/wal/colors.sh"
if [ -f "$WAL_COLORS" ]; then
    source "$WAL_COLORS"
else
    background="#0b0e19"
    foreground="#c2c2c5"
    color4="#8A778F"
    color5="#5999D0"
fi

# 2. Стиль для wofi
WOFI_STYLE=$(mktemp)
cat <<EOF > "$WOFI_STYLE"
window {
    background-color: alpha(${background}, 0.97);
    border: 2px solid ${color4};
    border-radius: 16px;
    padding: 6px;
}
#outer-box {
    background-color: transparent;
    border: none;
    margin: 0px;
    padding: 4px;
}
#input {
    background-color: alpha(${background}, 0.85);
    color: ${foreground};
    border: 2px solid ${color4};
    border-radius: 10px;
    margin: 6px;
    padding: 8px 12px;
    font-size: 13px;
}
#scroll {
    margin: 0px;
    padding: 0px;
}
#entry {
    border-radius: 8px;
    padding: 6px 10px;
    margin: 2px 6px;
    background-color: transparent;
    border: 2px solid transparent;
    min-height: 32px;
}
#entry:hover {
    border: 2px solid ${color4};
    background-color: alpha(${color4}, 0.15);
}
#entry:selected {
    border: 2px solid ${color5};
    background-color: alpha(${color5}, 0.25);
}
#text {
    color: ${foreground};
    font-family: "JetBrains Mono", monospace;
    font-size: 13px;
}
#text:selected {
    color: ${foreground};
}
#img {
    border-radius: 6px;
    margin-right: 8px;
}
EOF

# Папка для кэширования миниатюр изображений
THUMB_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/cliphist/thumbs"
mkdir -p "$THUMB_DIR"

# Основная логика вызова меню
if [ -z "$1" ]; then
    CLIPHIST_LIST=$(cliphist list)

    # Очищаем старый кэш миниатюр, которых больше нет в истории cliphist
    for thumb in "$THUMB_DIR"/*; do
        [ -e "$thumb" ] || continue
        clip_id="${thumb##*/}"
        clip_id="${clip_id%.*}"
        if ! grep -q "^$clip_id[[:space:]]" <<< "$CLIPHIST_LIST"; then
            rm "$thumb"
        fi
    done

    # Парсер: находит бинарные изображения и генерирует для них PNG-иконки,
    # а длинные текстовые строки обрезает, чтобы не было переноса на 2 строки
    PROG_PARSER=$(cat <<'EOF'
    /^[0-9]+\s<meta http-equiv=/ { next }
    match($0, /^([0-9]+)\s(\[\[\s)?binary.*(jpg|jpeg|png|bmp|webp)/, grp) {
        image = grp[1]"."grp[3]
        system("[ -f " THUMB_DIR "/" image " ] || echo " grp[1] " | cliphist decode | magick - -resize '128x128>' " THUMB_DIR "/" image)
        print "img:" THUMB_DIR "/" image
        next
    }
    {
        line = $0
        if (length(line) > 90) {
            line = substr(line, 1, 90) "…"
        }
        print line
    }
EOF
    )

    # Запуск wofi с поддержкой картинок
    CHOICE=$(gawk -v THUMB_DIR="$THUMB_DIR" "$PROG_PARSER" <<< "$CLIPHIST_LIST" | \
             wofi -I --dmenu --style "$WOFI_STYLE" --cache-file=/dev/null \
                  --width=700 --height=450 --columns=1 --hide-scroll \
                  --insensitive --location=center --prompt="Буфер обмена" \
                  -Dimage_size=64)

    [ -z "$CHOICE" ] && rm "$WOFI_STYLE" && exit 0

    if [ "${CHOICE::4}" = "img:" ]; then
        THUMB_FILE="${CHOICE:4}"
        CLIP_ID="${THUMB_FILE##*/}"
        CLIP_ID="${CLIP_ID%.*}"
        "$0" "DECODE_IMG_ID:$CLIP_ID"
    else
        # т.к. строка обрезана символом "…", ищем оригинал по id в начале строки
        CLIP_ID="${CHOICE%%$'\t'*}"
        printf "%s" "$CLIP_ID" | cliphist decode | wl-copy
    fi

else
    if [[ "$1" == DECODE_IMG_ID:* ]]; then
        CLIP_ID="${1#DECODE_IMG_ID:}"
        printf "%s" "$CLIP_ID" | cliphist decode | wl-copy
    fi
fi

rm "$WOFI_STYLE"
