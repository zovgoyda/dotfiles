#!/bin/bash
# 🚀 ПОЛНАЯ АВТОМАТИЧЕСКАЯ УСТАНОВКА DOTFILES
# Одна команда = всё готово
# 
# Использование:
#   bash setup.sh

set -e

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║     🎨 Dotfiles: Полная установка для Niri + Pywal          ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# ==================== ЦВЕТА ====================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ==================== ФУНКЦИИ ====================
log_step() {
    echo -e "${BLUE}▶${NC} $1"
}

log_success() {
    echo -e "${GREEN}✅${NC} $1"
}

log_error() {
    echo -e "${RED}❌${NC} $1" >&2
}

log_warning() {
    echo -e "${YELLOW}⚠️${NC} $1"
}

# ==================== ОПРЕДЕЛЯЕМ ОС ====================
log_step "Определяю окружение..."

if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_ID="${ID}"
    OS_PRETTY="${PRETTY_NAME}"
else
    log_error "Не могу определить ОС"
    exit 1
fi

log_success "ОС: $OS_PRETTY"

# ==================== ОПРЕДЕЛЯЕМ PACKAGE MANAGER ====================
if command -v pacman &> /dev/null; then
    PKG_MANAGER="pacman"
    INSTALL_CMD="sudo pacman -Syu --needed"
    AUR_CMD="paru -Syu --needed"
    USE_AUR=true
elif command -v apt &> /dev/null; then
    PKG_MANAGER="apt"
    INSTALL_CMD="sudo apt update && sudo apt install -y"
    USE_AUR=false
elif command -v dnf &> /dev/null; then
    PKG_MANAGER="dnf"
    INSTALL_CMD="sudo dnf install -y"
    USE_AUR=false
elif command -v xbps-install &> /dev/null; then
    PKG_MANAGER="xbps"
    INSTALL_CMD="sudo xbps-install -Sy"
    USE_AUR=false
else
    log_error "Пакет-менеджер не найден"
    exit 1
fi

log_success "Пакет-менеджер: $PKG_MANAGER"

# ==================== ОПРЕДЕЛЯЕМ INIT SYSTEM ====================
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
    INIT_SYSTEM="systemd"
fi

log_success "Init system: $INIT_SYSTEM"
echo ""

# ==================== СБОР ПАКЕТОВ ====================
log_step "Собираю список пакетов..."

BASE_PACKAGES=(
    niri waybar wofi kitty thunar firefox wl-clipboard swaybg
    libcanberra pavucontrol imagemagick gawk ttf-jetbrains-mono
    ttf-font-awesome polkit-gnome xarchiver inotify-tools fastfetch
    noto-fonts-cjk
)

GREETD_PACKAGES=(greetd)
case "$INIT_SYSTEM" in
    systemd) GREETD_PACKAGES+=(greetd) ;;
    dinit) GREETD_PACKAGES+=(greetd-dinit) ;;
    runit) GREETD_PACKAGES+=(greetd-runit) ;;
    s6) GREETD_PACKAGES+=(greetd-s6) ;;
esac

OPT_PACKAGES=(cliphist python-pywal)
if [ "$USE_AUR" = true ]; then
    OPT_PACKAGES+=(swaylock-effects adw-gtk-theme greetd-regreet-git cage-git wlroots0.20)
else
    OPT_PACKAGES+=(swaylock)
fi

log_success "Собрано $(( ${#BASE_PACKAGES[@]} + ${#GREETD_PACKAGES[@]} + ${#OPT_PACKAGES[@]} )) пакетов"
echo ""

# ==================== УСТАНОВКА ПАКЕТОВ ====================
log_step "Устанавливаю основные пакеты..."
$INSTALL_CMD ${BASE_PACKAGES[@]}
log_success "Основные пакеты установлены"

log_step "Устанавливаю greetd..."
$INSTALL_CMD ${GREETD_PACKAGES[@]}
log_success "Greetd установлен"

if [ "$USE_AUR" = true ] && command -v paru &> /dev/null; then
    log_step "Устанавливаю AUR пакеты..."
    $AUR_CMD ${OPT_PACKAGES[@]} || true
    log_success "AUR пакеты установлены"
else
    log_step "Устанавливаю опциональные пакеты..."
    $INSTALL_CMD ${OPT_PACKAGES[@]} || true
    log_success "Опциональные пакеты установлены"
fi

echo ""

# ==================== УСТАНОВКА КОНФИГОВ ====================
log_step "Устанавливаю конфигурации..."

CONFIG_DIR="$HOME/.config"
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$CONFIG_DIR"

CONFIGS=(waybar wofi gtk-3.0 gtk-4.0 kitty niri swaylock fastfetch)

for config in "${CONFIGS[@]}"; do
    src="$DOTFILES_DIR/$config"
    dst="$CONFIG_DIR/$config"
    
    if [ -d "$src" ]; then
        if [ -e "$dst" ] && [ ! -L "$dst" ]; then
            backup_name="$dst.backup.$(date +%s)"
            mv "$dst" "$backup_name"
        fi
        
        if [ -L "$dst" ]; then
            rm "$dst"
        fi
        
        ln -s "$src" "$dst"
        log_success "$config → ~/.config/$config"
    fi
done

echo ""

# ==================== ПРАВА НА СКРИПТЫ ====================
log_step "Даю права на исполнение скриптам..."
find "$DOTFILES_DIR" -type f -name "*.sh" -exec chmod +x {} \;
log_success "Права установлены"

echo ""

# ==================== НАСТРОЙКА GREETD ====================
log_step "Настраиваю greetd + regreet..."

if command -v greetd &> /dev/null; then
    sudo mkdir -p /etc/greetd/theme
    sudo chown -R greeter:greeter /etc/greetd/theme
    sudo chmod 755 /etc/greetd/theme
    
    sudo tee /etc/greetd/config.toml > /dev/null <<'EOF'
[terminal]
vt = 1

[default_session]
command = "cage-git -s -m last -- regreet"
user = "greeter"
EOF
    
    sudo tee /etc/greetd/environments > /dev/null <<'EOF'
niri
EOF
    
    if [ ! -f /etc/greetd/regreet.toml ]; then
        sudo touch /etc/greetd/regreet.toml
    fi
    sudo chown greeter:$(id -g) /etc/greetd/regreet.toml 2>/dev/null || sudo chown greeter:greeter /etc/greetd/regreet.toml
    sudo chmod 664 /etc/greetd/regreet.toml
    
    case "$INIT_SYSTEM" in
        systemd) sudo systemctl enable greetd &> /dev/null ;;
        dinit) sudo dinitctl enable greetd &> /dev/null ;;
        runit) [ -f /etc/runit/sv/greetd/run ] && sudo ln -sf /etc/runit/sv/greetd /etc/runit/runsvdir/default/ ;;
        s6) log_warning "s6: используй s6-rc-update" ;;
    esac
    
    log_success "greetd настроен для $INIT_SYSTEM"
else
    log_warning "greetd не установлен"
fi

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                  ✨ УСТАНОВКА ЗАВЕРШЕНА! ✨                 ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# ==================== ЗАПУСК WELCOME.SH ====================
log_step "Запускаю приветственный скрипт..."
echo ""

WELCOME_SCRIPT="$DOTFILES_DIR/welcome.sh"
if [ -f "$WELCOME_SCRIPT" ]; then
    bash "$WELCOME_SCRIPT"
else
    echo -e "${YELLOW}⚠️${NC} welcome.sh не найден"
    echo ""
    echo -e "${GREEN}📝 СЛЕДУЮЩИЕ ШАГИ:${NC}"
    echo ""
    echo "1️⃣  (Опционально) Отредактируй конфиги:"
    echo "    nano ~/.config/niri/config.kdl"
    echo "    nano ~/.config/waybar/config.jsonc"
    echo ""
    echo "2️⃣  Перезагрузи сессию (Mod+Shift+R в niri) или перезагрузись"
    echo ""
    echo "3️⃣  Для смены обоев и генерации темы:"
    echo "    ~/.config/waybar/theme.sh"
    echo ""
    echo "4️⃣  (Опционально) Для синхронизации greetd в реальном времени:"
    echo "    bash ~/.config/waybar/sync-greetd-watcher.sh &"
    echo "    # Или добавь в niri конфиг: exec-once = [\"~/.config/waybar/sync-greetd-watcher.sh\"]"
    echo ""
    echo "5️⃣  Fastfetch установлен - показать информацию о системе:"
    echo "    fastfetch"
    echo ""
    echo -e "${BLUE}📖 Документация:${NC}"
    echo "    - README.md — полная документация"
    echo "    - GREETD_SETUP.md — настройка экрана входа"
    echo ""
fi
