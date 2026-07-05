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
    border-radius: 12px;
    padding: 4px;
    margin: 6px;
    background-color: alpha(${color4}, 0.08);
    border: 2px solid transparent;
    min-width: 190px;
    min-height: 190px;
}
#entry:hover {
    border: 2px solid ${color4};
    background-color: alpha(${color4}, 0.18);
}
#entry:selected {
    border: 2px solid ${color5};
    background-color: alpha(${color5}, 0.28);
}
#text {
    color: ${foreground};
    font-family: "JetBrains Mono", monospace;
    font-size: 12px;
}
#text:selected {
    color: ${foreground};
}
#img {
    border-radius: 8px;
}
/* Кнопка очистки истории — крупнее и заметнее среди плиток */
#entry:nth-child(1) {
    min-width: 190px;
    min-height: 190px;
    background-color: alpha(${color5}, 0.15);
    border: 2px solid alpha(${color5}, 0.4);
}
#entry:nth-child(1):hover {
    background-color: alpha(${color5}, 0.3);
    border: 2px solid ${color5};
}
#entry:nth-child(1) #text {
    font-size: 16px;
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
    border-radius: 8px;
    margin-right: 10px;
}
EOF

# Ищем ImageMagick: сначала magick (v7), иначе convert (v6)
CONVERT_BIN=$(command -v magick || command -v convert)

# Папка для кэширования миниатюр изображений
THUMB_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/cliphist/thumbs"
mkdir -p "$THUMB_DIR"

CLEAR_LABEL="🗑  Очистить историю буфера обмена"

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

    if [ -z "$CONVERT_BIN" ]; then
        notify-send "cliphist" "ImageMagick не найден: превью картинок отключены" 2>/dev/null
    fi

    MAPFILE_PATH=$(mktemp)

    # Парсер:
    # - находит бинарные изображения, генерирует для них PNG-превью покрупнее
    # - у текстовых записей срезает id (чтобы не мозолил глаза) и длинные строки,
    #   сохраняя связь id<->текст в MAPFILE_PATH для последующего decode
    PROG_PARSER=$(cat <<'EOF'
    /^[0-9]+\s<meta http-equiv=/ { next }
    match($0, /^([0-9]+)\s(\[\[\s)?binary.*(jpg|jpeg|png|bmp|webp)/, grp) {
        id = grp[1]
        image = id"."grp[3]
        thumb = THUMB_DIR "/" image

        # быстрая проверка существования файла без лишнего subshell
        exists = ((getline junk < thumb) >= 0)
        close(thumb)

        if (!exists && CONVERT_BIN != "") {
            system("printf '%s' " id " | cliphist decode | " CONVERT_BIN " - -resize '320x320>' " thumb " 2>/dev/null")
            exists = ((getline junk < thumb) >= 0)
            close(thumb)
        }

        if (exists) {
            print "img:" thumb
        } else {
            print $0
        }
        next
    }
    {
        line = $0
        tabpos = index(line, "\t")
        if (tabpos > 0) {
            id = substr(line, 1, tabpos - 1)
            text = substr(line, tabpos + 1)
        } else {
            id = ""
            text = line
        }
        if (length(text) > 36) {
            text = substr(text, 1, 36) "…"
        }
        if (id != "") {
            print id "\t" text >> MAPFILE_PATH
        }
        print text
    }
EOF
    )

    # Запуск wofi с поддержкой картинок; первым пунктом — очистка истории
    CHOICE=$( { [ -n "$CLIPHIST_LIST" ] && printf '%s\n' "$CLEAR_LABEL"; \
                gawk -v THUMB_DIR="$THUMB_DIR" -v CONVERT_BIN="$CONVERT_BIN" -v MAPFILE_PATH="$MAPFILE_PATH" "$PROG_PARSER" <<< "$CLIPHIST_LIST"; } | \
             wofi -I --dmenu --style "$WOFI_STYLE" --cache-file=/dev/null \
                  --width=900 --height=620 --columns=4 --hide-scroll \
                  --insensitive --location=center --prompt="Буфер обмена" \
                  -Dimage_size=170 )

    [ -z "$CHOICE" ] && rm -f "$WOFI_STYLE" "$MAPFILE_PATH" && exit 0

    if [ "$CHOICE" = "$CLEAR_LABEL" ]; then
        cliphist wipe
        rm -rf "${THUMB_DIR:?}"/*
        notify-send "Буфер обмена" "История очищена" 2>/dev/null
    elif [ "${CHOICE::4}" = "img:" ]; then
        THUMB_FILE="${CHOICE:4}"
        CLIP_ID="${THUMB_FILE##*/}"
        CLIP_ID="${CLIP_ID%.*}"
        "$0" "DECODE_IMG_ID:$CLIP_ID"
    else
        CLIP_ID=$(awk -F'\t' -v want="$CHOICE" '{ t=index($0,"\t"); text=substr($0,t+1); if (text==want) { print $1; exit } }' "$MAPFILE_PATH")
        if [ -n "$CLIP_ID" ]; then
            printf "%s" "$CLIP_ID" | cliphist decode | wl-copy
        fi
    fi

    rm -f "$MAPFILE_PATH"

else
    if [[ "$1" == DECODE_IMG_ID:* ]]; then
        CLIP_ID="${1#DECODE_IMG_ID:}"
        printf "%s" "$CLIP_ID" | cliphist decode | wl-copy
    fi
fi

rm -f "$WOFI_STYLE"
