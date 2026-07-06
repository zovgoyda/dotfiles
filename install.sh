#!/bin/bash
# Быстрая установка всех конфигов через symlink
# После переустановки ОС просто запусти: bash install.sh

CONFIG_DIR="$HOME/.config"
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Массив папок которые нужно симлинковать
CONFIGS=(
    "waybar"
    "wofi"
    "gtk-3.0"
    "gtk-4.0"
    "kitty"
    "niri"
)

echo "🔗 Устанавливаю symlink'и для конфигов..."
echo ""

# Создаём директорию если её нет
mkdir -p "$CONFIG_DIR"

for config in "${CONFIGS[@]}"; do
    src="$DOTFILES_DIR/$config"
    dst="$CONFIG_DIR/$config"
    
    if [ -d "$src" ]; then
        # Если есть оригинальный конфиг - бекапим
        if [ -e "$dst" ] && [ ! -L "$dst" ]; then
            backup_name="$dst.backup.$(date +%s)"
            mv "$dst" "$backup_name"
            echo "💾 Бекап сохранён: $backup_name"
        fi
        
        # Если это был symlink на старую папку - удаляем
        if [ -L "$dst" ]; then
            rm "$dst"
        fi
        
        # Создаём symlink
        ln -s "$src" "$dst"
        echo "✅ $config → symlink создан"
    else
        echo "⚠️  $config не найдена в репо"
    fi
done

echo ""
echo "🔧 Выставляю права на исполнение для .sh скриптов..."
find "$DOTFILES_DIR" -type f -name "*.sh" -exec chmod +x {} \;
echo "✅ Права выставлены"

# --- SDDM: тема логина, синхронизирующаяся с обоями/pywal ---
echo ""
echo "🖥  Настраиваю тему SDDM..."

if ! pacman -Qi where-is-my-sddm-theme-git &>/dev/null && [ ! -d "/usr/share/sddm/themes/where_is_my_sddm_theme" ]; then
    echo "⚠️  Тема not found. Установи сначала: yay -S where-is-my-sddm-theme-git"
else
    SDDM_THEMES_DIR="/usr/local/share/sddm-themes"
    SDDM_THEME_DIR="$SDDM_THEMES_DIR/where_is_my_sddm_theme"

    # Директория для тем в пользовательском владении — чтобы дальше
    # писать в неё (менять фон/цвета) можно было БЕЗ sudo
    if [ ! -d "$SDDM_THEMES_DIR" ] || [ ! -w "$SDDM_THEMES_DIR" ]; then
        sudo mkdir -p "$SDDM_THEMES_DIR"
        sudo chown "$(id -u):$(id -g)" "$SDDM_THEMES_DIR"
    fi

    # Копируем свежую тему из системного каталога (только если ещё не скопирована)
    if [ ! -d "$SDDM_THEME_DIR" ] && [ -d "/usr/share/sddm/themes/where_is_my_sddm_theme" ]; then
        cp -r "/usr/share/sddm/themes/where_is_my_sddm_theme" "$SDDM_THEME_DIR"
        echo "✅ Тема скопирована в $SDDM_THEME_DIR"
    fi

    # Настраиваем SDDM использовать нашу директорию и эту тему (нужен sudo один раз)
    sudo mkdir -p /etc/sddm.conf.d
    sudo tee /etc/sddm.conf.d/theme.conf > /dev/null <<EOF
[Theme]
Current=where_is_my_sddm_theme
ThemeDir=$SDDM_THEMES_DIR
EOF
    echo "✅ /etc/sddm.conf.d/theme.conf настроен"
    echo "   Дальнейшая синхронизация фона/цветов идёт без sudo через"
    echo "   waybar/sync-sddm-theme.sh (уже подключено в theme.sh)"
fi

echo ""
echo "✨ Установка завершена!"
echo ""
echo "Теперь все конфиги синхронизированы с репо."
echo "После git pull изменения будут видны сразу!"
