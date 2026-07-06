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

# --- greetd + gtkgreet: лёгкая замена SDDM ---
echo ""
echo "🖥  Настраиваю greetd + gtkgreet..."

if ! command -v greetd &>/dev/null || ! command -v cage &>/dev/null || [ ! -x /usr/bin/gtkgreet ] || [ ! -f /etc/dinit.d/greetd ]; then
    echo "⚠️  Не найдены greetd/cage/gtkgreet/greetd-dinit. Установи сначала:"
    echo "    yay -S greetd greetd-dinit cage greetd-gtkgreet-git"
else
    # Отключаем SDDM, если он ещё стоит и активен
    if [ -f /etc/dinit.d/boot.d/sddm ] || [ -L /etc/dinit.d/boot.d/sddm ]; then
        sudo dinitctl disable sddm
        sudo dinitctl stop sddm
        echo "✅ SDDM отключён"
    fi

    # Директория с темой greeter'а — во владении пользователя,
    # чтобы sync-greetd-theme.sh мог обновлять обои/цвета БЕЗ sudo
    GREETD_THEME_DIR="/etc/greetd/theme"
    if [ ! -d "$GREETD_THEME_DIR" ] || [ ! -w "$GREETD_THEME_DIR" ]; then
        sudo mkdir -p "$GREETD_THEME_DIR"
        sudo chown "$(id -u):$(id -g)" "$GREETD_THEME_DIR"
    fi

    # Список сессий, которые может запустить gtkgreet
    sudo tee /etc/greetd/environments > /dev/null <<EOF
niri
EOF

    # Основной конфиг greetd (нужен sudo один раз)
    sudo tee /etc/greetd/config.toml > /dev/null <<EOF
[terminal]
vt = 1

[default_session]
command = "env GTK_THEME=adw-gtk3-dark cage -s -- gtkgreet -s /etc/greetd/theme/style.css"
user = "greeter"

EOF

    sudo dinitctl enable greetd

    echo "✅ greetd настроен и включён (vt1, sessions: niri)"
fi

echo ""
echo "✨ Установка завершена!"
echo ""
