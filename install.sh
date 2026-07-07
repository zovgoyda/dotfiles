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

# --- greetd + regreet: лёгкая замена SDDM ---
echo ""
echo "🖥 Настраиваю greetd + regreet..."
if ! command -v greetd &>/dev/null || ! command -v cage &>/dev/null || ! command -v regreet &>/dev/null || [ ! -f /etc/dinit.d/greetd ]; then
    echo "⚠️ Не найдены greetd/cage/regreet/greetd-dinit. Установи сначала:"
    echo " paru -S greetd greetd-dinit cage greetd-regreet-git"
else
    # Корректные пути для конфигов regreet
    REGREET_FILE="/etc/greetd/regreet.toml"
    GREETD_THEME_DIR="/etc/greetd/theme"
    
    # Пересоздаем директорию темы greetd с корректными системными правами
    if [ ! -d "$GREETD_THEME_DIR" ]; then
        sudo mkdir -p "$GREETD_THEME_DIR"
    fi
    # Даем права и root, и системному пользователю greeter
    sudo chown -R greeter:greeter "$GREETD_THEME_DIR"
    sudo chmod 755 "$GREETD_THEME_DIR"
    
    # Создаем и настраиваем права на конфигурационный файл regreet.toml
    if [ ! -f "$REGREET_FILE" ]; then
        sudo touch "$REGREET_FILE"
    fi
    # greeter должен владеть файлом, а твоя группа иметь право записи через waybar
    sudo chown greeter:$(id -g) "$REGREET_FILE"
    sudo chmod 664 "$REGREET_FILE"

    # Настраиваем доступную сессию для greetd
    sudo tee /etc/greetd/environments > /dev/null <<EOF
niri
EOF

    # Основной конфиг greetd (запуск cage без лишних переменных)
    sudo tee /etc/greetd/config.toml > /dev/null <<EOF
[terminal]
vt = 1

[default_session]
command = "cage -s -m last -- regreet"
user = "greeter"
EOF

    # Включаем службу через dinit
    sudo dinitctl enable greetd
    echo "✅ greetd + regreet настроены и включены!"
fi

echo ""
echo "✨ Установка завершена!"
echo ""
