#!/usr/bin/env bash

# 1. Подгружаем цвета Pywal
WAL_COLORS="$HOME/.cache/wal/colors.sh"
if [ -f "$WAL_COLORS" ]; then
    source "$WAL_COLORS"
else
    background="#2e1a47"
    color4="#4a2c73"
    color5="#4a2c73"
fi

# 2. Создаем временный файл стилей для wofi
WOFI_STYLE=$(mktemp)
cat <<EOF > "$WOFI_STYLE"
window {
    background-color: $background;
}
#entry:selected {
    background-color: $color4;
}
#text:selected {
    color: $color5;
}
EOF

# Папка для кэширования миниатюр изображений
THUMB_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/cliphist/thumbs"
mkdir -p "$THUMB_DIR"

# Основная логика вызова меню
if [ -z "$@" ]; then
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

    # Парсер: находит бинарные изображения и генерирует для них PNG-иконки
    PROG_PARSER=$(cat <<'EOF'
    /^[0-9]+\s<meta http-equiv=/ { next }
    match($0, /^([0-9]+)\s(\[\[\s)?binary.*(jpg|jpeg|png|bmp|webp)/, grp) {
        image = grp[1]"."grp[3]
        system("[ -f " THUMB_DIR "/" image " ] || echo " grp[1] " | cliphist decode | magick - -resize '128x128>' " THUMB_DIR "/" image)
        print "img:" THUMB_DIR "/" image
        next
    }
    1
EOF
    )

    # Запуск wofi с поддержкой картинок (-I включает отображение иконок)
    CHOICE=$(gawk -v THUMB_DIR="$THUMB_DIR" "$PROG_PARSER" <<< "$CLIPHIST_LIST" | \
             wofi -I --dmenu --style "$WOFI_STYLE" --cache-file=/dev/null -Dimage_size=80 -Dynamic_lines=true)
    
    # Если нажали ESC (ничего не выбрано), плавно завершаем скрипт
    [ -z "$CHOICE" ] && rm "$WOFI_STYLE" && exit 0

    # Проверяем, выбрали ли мы картинку или обычный текст
    if [ "${CHOICE::4}" = "img:" ]; then
        THUMB_FILE="${CHOICE:4}"
        CLIP_ID="${THUMB_FILE##*/}"
        CLIP_ID="${CLIP_ID%.*}"
        # Передаем ID картинки во вторую фазу скрипта
        "$0" "DECODE_IMG_ID:$CLIP_ID"
    else
        # Передаем обычную строку текста во вторую фазу скрипта
        xargs -r -I {} "$0" "{}" <<< "$CHOICE"
    fi

else
    # Обработка выбора (вторая фаза)
    if [[ "$@" == DECODE_IMG_ID:* ]]; then
        # Если это была картинка, вырезаем префикс ID, декодируем её и копируем
        CLIP_ID="${@#DECODE_IMG_ID:}"
        printf "%s" "$CLIP_ID" | cliphist decode | wl-copy
    else
        # Если это текст, обрабатываем стандартно
        echo "$@" | cliphist decode | wl-copy
    fi
fi

# 4. Всегда удаляем файл темы при выходе
rm "$WOFI_STYLE"
