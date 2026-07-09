#!/bin/bash
# Полная переустановка и настройка dotfiles

set -e

echo ""
echo "╔════════════════════════════════════════════════╗"
echo "║  🎨 Dotfiles Setup для Niri + Wayland          ║"
echo "╚════════════════════════════════════════════════╝"
echo ""

# Цвета
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_step() { echo -e "${BLUE}▶${NC} $1"; }
log_ok() { echo -e "${GREEN}✓${NC} $1"; }

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"

log_step "Установка конфигов в $CONFIG_DIR..."
mkdir -p "$CONFIG_DIR"

for dir in waybar wofi gtk-3.0 gtk-4.0 kitty niri swaylock; do
    src="$DOTFILES_DIR/$dir"
    dst="$CONFIG_DIR/$dir"
    
    if [ -d "$src" ]; then
        # Бекап старого
        if [ -e "$dst" ] && [ ! -L "$dst" ]; then
            mv "$dst" "$dst.backup"
        fi
        
        # Удаляем symlink если был
        [ -L "$dst" ] && rm "$dst"
        
        # Создаём новый
        ln -s "$src" "$dst"
        log_ok "$dir → ~/.config/$dir"
    fi
done

log_step "Выставляю права на скрипты..."
find "$DOTFILES_DIR" -name "*.sh" -exec chmod +x {} \;
log_ok "Права установлены"

echo ""
log_step "Настраиваю greetd..."

if command -v greetd &>/dev/null; then
    sudo mkdir -p /etc/greetd/theme
    sudo chmod 755 /etc/greetd/theme
    
    # Определяем каким cage пользоваться
    if command -v cage-git &>/dev/null; then
        cage_cmd="cage-git -s -m last -- regreet"
    elif command -v cage &>/dev/null; then
        cage_cmd="cage -s -m last -- regreet"
    else
        cage_cmd="regreet"
    fi
    
    sudo tee /etc/greetd/config.toml >/dev/null <<EOF
[terminal]
vt = 1

[default_session]
command = "$cage_cmd"
user = "greeter"
EOF
    
    sudo tee /etc/greetd/environments >/dev/null <<EOF
niri
EOF
    
    # regreet конфиг
    if [ ! -f /etc/greetd/regreet.toml ]; then
        sudo touch /etc/greetd/regreet.toml
    fi
    sudo chmod 664 /etc/greetd/regreet.toml
    
    # Включаем сервис
    if [ -d /run/systemd/system ]; then
        sudo systemctl enable greetd 2>/dev/null
    fi
    
    log_ok "greetd настроен"
else
    echo "⚠️  greetd не установлен"
fi

echo ""
echo "✨ Готово!"
echo ""
echo "📝 Следующие шаги:"
echo "   1. Создай папку обоев: mkdir -p ~/wallpapers"
echo "   2. Положи туда обои (jpg/png/webp)"
echo "   3. Генерируй тему: ~/.config/waybar/theme.sh"
echo "   4. Перезагрузи niri: Mod+Shift+R"
echo ""
