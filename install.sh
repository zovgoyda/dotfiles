#!/bin/bash
# Универсальная установка конфигураций
# Поддерживает различные init systems (systemd, dinit, runit, s6)

set -e

echo "🔗 Установка конфигураций dotfiles"
echo ""

CONFIG_DIR="$HOME/.config"
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "📍 Paths:"
echo "   Config dir: $CONFIG_DIR"
echo "   Dotfiles:   $DOTFILES_DIR"
echo ""

# ========== ОПРЕДЕЛЯЕМ INIT SYSTEM ==========
echo "🔍 Определяю init system..."

INIT_SYSTEM=""
if [ -d /run/systemd/system ]; then
    INIT_SYSTEM="systemd"
elif command -v dinitctl &> /dev/null; then
    INIT_SYSTEM="dinit"
elif command -v sv &> /dev/null; then
    INIT_SYSTEM="runit"
elif command -v s6-rc &> /dev/null; then
    INIT_SYSTEM="s6"
fi

if [ -z "$INIT_SYSTEM" ]; then
    echo "⚠️  Init system не определен. Используй systemd (по умолчанию)"
    INIT_SYSTEM="systemd"
fi

echo "✅ Init system: $INIT_SYSTEM"
echo ""

# ========== SYMLINK'И КОНФИГОВ ==========
echo "🔗 Создаю symlink'и для конфигов..."
echo ""

CONFIGS=(
    "waybar"
    "wofi"
    "gtk-3.0"
    "gtk-4.0"
    "kitty"
    "niri"
    "swaylock"
)

mkdir -p "$CONFIG_DIR"

for config in "${CONFIGS[@]}"; do
    src="$DOTFILES_DIR/$config"
    dst="$CONFIG_DIR/$config"
    
    if [ -d "$src" ]; then
        # Бекап оригинального конфига
        if [ -e "$dst" ] && [ ! -L "$dst" ]; then
            backup_name="$dst.backup.$(date +%s)"
            mv "$dst" "$backup_name"
            echo "💾 Бекап: $backup_name"
        fi
        
        # Удаляем старый symlink
        if [ -L "$dst" ]; then
            rm "$dst"
        fi
        
        # Создаём новый symlink
        ln -s "$src" "$dst"
        echo "✅ $config → ~/.config/$config"
    else
        echo "⚠️  $config не найдена"
    fi
done

echo ""
echo "🔧 Выставляю права на исполнение для скриптов..."
find "$DOTFILES_DIR" -type f -name "*.sh" -exec chmod +x {} \;
echo "✅ Права установлены"
echo ""

# ========== GREETD SETUP ==========
echo "🖥️  Настраиваю greetd + regreet..."
echo ""

if ! command -v greetd &>/dev/null; then
    echo "⚠️  greetd не установлен. Запусти deps.sh"
else
    # Создаём директории
    echo "  • Создаю /etc/greetd/theme..."
    sudo mkdir -p /etc/greetd/theme
    sudo chown -R greeter:greeter /etc/greetd/theme
    sudo chmod 755 /etc/greetd/theme
    
    # Обновляем конфиг greetd
    echo "  • Обновляю /etc/greetd/config.toml..."
    sudo tee /etc/greetd/config.toml > /dev/null <<'EOF'
[terminal]
vt = 1

[default_session]
command = "cage -s -m last -- regreet"
user = "greeter"
EOF
    
    # Создаём файл окружений
    echo "  • Обновляю /etc/greetd/environments..."
    sudo tee /etc/greetd/environments > /dev/null <<'EOF'
niri
EOF
    
    # Создаём/обновляем файл regreet.toml с правильными правами
    if [ ! -f /etc/greetd/regreet.toml ]; then
        sudo touch /etc/greetd/regreet.toml
    fi
    sudo chown greeter:$(id -g) /etc/greetd/regreet.toml 2>/dev/null || sudo chown greeter:greeter /etc/greetd/regreet.toml
    sudo chmod 664 /etc/greetd/regreet.toml
    
    # Включаем greetd в зависимости от init system
    echo "  • Включаю greetd для $INIT_SYSTEM..."
    case "$INIT_SYSTEM" in
        systemd)
            sudo systemctl enable greetd
            echo "    ✅ sudo systemctl enable greetd"
            ;;
        dinit)
            sudo dinitctl enable greetd
            echo "    ✅ sudo dinitctl enable greetd"
            ;;
        runit)
            if [ -f /etc/runit/sv/greetd/run ]; then
                sudo ln -sf /etc/runit/sv/greetd /etc/runit/runsvdir/default/
                echo "    ✅ runit service enabled"
            else
                echo "    ⚠️  runit service не найден"
            fi
            ;;
        s6)
            echo "    ℹ️  s6: используй s6-rc-update"
            ;;
    esac
    
    echo "✅ greetd настроен"
fi

echo ""
echo "========================================"
echo "✨ Установка завершена!"
echo "========================================"
echo ""
echo "📝 Следующие шаги:"
echo ""
echo "1️⃣  Отредактируй конфиги (если нужно):"
echo "    nano ~/.config/niri/config.kdl"
echo "    nano ~/.config/waybar/config.json"
echo ""
echo "2️⃣  Перезагрузи сессию или перезагрузись"
echo ""
echo "3️⃣  Для смены обоев и темы:"
echo "    ~/.config/waybar/theme.sh"
echo ""
echo "4️⃣  Для синхронизации greetd в реальном времени (опционально):"
echo "    bash ~/.config/waybar/sync-greetd-watcher.sh &"
echo ""
echo "ℹ️  Смотри README.md для полной документации"
echo ""
