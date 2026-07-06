#!/usr/bin/env bash
# Использование:
#   cliphist.sh          — открыть сетку истории буфера обмена
#   cliphist.sh clear    — очистить историю (для второй кнопки/right-click)

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

THUMB_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/cliphist/thumbs"
mkdir -p "$THUMB_DIR"

# --- Режим очистки истории (отдельная "кнопка", напр. right-click в waybar) ---
if [ "$1" = "clear" ]; then
    cliphist wipe
    rm -rf "${THUMB_DIR:?}"/*
    notify-send "Буфер обмена" "История очищена" 2>/dev/null
    exit 0
fi

# --- Внутренний режим: декодирование картинки по id (см. ниже) ---
if [[ "$1" == DECODE_IMG_ID:* ]]; then
    CLIP_ID="${1#DECODE_IMG_ID:}"
    printf "%s" "$CLIP_ID" | cliphist decode | wl-copy
    exit 0
fi

# --- Toggle: если окно уже открыто — закрываем его вместо повторного открытия ---
LOCKFILE="${XDG_RUNTIME_DIR:-/tmp}/cliphist-wofi.pid"
if [ -f "$LOCKFILE" ]; then
    OLD_PID=$(cat "$LOCKFILE" 2>/dev/null)
    if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
        kill "$OLD_PID" 2>/dev/null
        rm -f "$LOCKFILE"
        exit 0
    fi
    rm -f "$LOCKFILE"
fi

# 2. Стиль для wofi — крупные квадратные плитки, чистый минимал
WOFI_STYLE=$(mktemp)
cat <<EOF > "$WOFI_STYLE"
window {
    background-color: alpha(${background}, 0.98);
    border: 1px solid alpha(${color4}, 0.5);
    border-radius: 18px;
    padding: 4px;
}
#outer-box {
    background-color: transparent;
    border: none;
    margin: 0px;
    padding: 10px;
}
#input {
    background-color: alpha(${foreground}, 0.06);
    color: ${foreground};
    border: none;
    border-radius: 12px;
    margin-bottom: 10px;
    padding: 10px 14px;
    font-size: 14px;
}
#scroll {
    margin: 0px;
    padding: 0px;
}
#entry {
    border-radius: 14px;
    padding: 6px;
    margin: 5px;
    background-color: alpha(${foreground}, 0.05);
    border: 1px solid transparent;
    min-width: 230px;
    min-height: 230px;
}
#entry:hover {
    background-color: alpha(${foreground}, 0.09);
    border: 1px solid alpha(${color4}, 0.6);
}
#entry:selected {
    background-color: alpha(${color5}, 0.22);
    border: 1px solid ${color5};
}
#text {
    color: alpha(${foreground}, 0.9);
    font-family: "JetBrains Mono", monospace;
    font-size: 12px;
}
#text:selected {
    color: ${foreground};
}
#img {
    border-radius: 10px;
}
EOF

# Ищем ImageMagick: сначала magick (v7), иначе convert (v6)
CONVERT_BIN=$(command -v magick || command -v convert)

# --- Основной режим: показать сетку истории ---
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
# - находит бинарные изображения, генерирует для них крупные PNG-превью
# - у текстовых записей срезает id (не показываем на экране) и обрезает длинные строки,
#   сохраняя связь id<->текст в MAPFILE_PATH для последующего decode
PROG_PARSER=$(cat <<'EOF'
    /^[0-9]+\s<meta http-equiv=/ { next }
    match($0, /^([0-9]+)\s(\[\[\s)?binary.*(jpg|jpeg|png|bmp|webp)/, grp) {
        id = grp[1]
        image = id"."grp[3]
        thumb = THUMB_DIR "/" image

        exists = ((getline junk < thumb) >= 0)
        close(thumb)

        if (!exists && CONVERT_BIN != "") {
            system("printf '%s' " id " | cliphist decode | " CONVERT_BIN " - -resize '420x420>' " thumb " 2>/dev/null")
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
        if (length(text) > 40) {
            text = substr(text, 1, 40) "…"
        }
        if (id != "") {
            print id "\t" text >> MAPFILE_PATH
        }
        print text
    }
EOF
)

WOFI_OUT=$(mktemp)
wofi -I --dmenu --style "$WOFI_STYLE" --cache-file=/dev/null \
     --width=920 --height=640 --columns=3 --hide-scroll \
     --insensitive --location=center --prompt="Буфер обмена" \
     -Dimage_size=210 < <(gawk -v THUMB_DIR="$THUMB_DIR" -v CONVERT_BIN="$CONVERT_BIN" -v MAPFILE_PATH="$MAPFILE_PATH" "$PROG_PARSER" <<< "$CLIPHIST_LIST") \
     > "$WOFI_OUT" &
WOFI_PID=$!
echo "$WOFI_PID" > "$LOCKFILE"
wait "$WOFI_PID" 2>/dev/null
rm -f "$LOCKFILE"
CHOICE=$(cat "$WOFI_OUT")
rm -f "$WOFI_OUT"

[ -z "$CHOICE" ] && rm -f "$WOFI_STYLE" "$MAPFILE_PATH" && exit 0

if [ "${CHOICE::4}" = "img:" ]; then
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

rm -f "$WOFI_STYLE" "$MAPFILE_PATH"
