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
echo "✨ Установка завершена!"
echo ""
echo "Теперь все конфиги синхронизированы с репо."
echo "После git pull изменения будут видны сразу!"
