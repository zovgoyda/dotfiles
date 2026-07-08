#!/bin/bash
# Автоматическая установка зависимостей
# Определяет дистрибьютив, пакет-менеджер и init system

set -e

echo "📦 Детектирую окружение..."
echo ""

# ========== ОПРЕДЕЛЯЕМ ОС ==========
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_ID="${ID}"
    OS_PRETTY="${PRETTY_NAME}"
else
    echo "❌ Не могу определить ОС (нет /etc/os-release)"
    exit 1
fi

echo "✅ ОС: $OS_PRETTY"

# ========== ОПРЕДЕЛЯЕМ PACKAGE MANAGER ==========
if command -v pacman &> /dev/null; then
    PKG_MANAGER="pacman"
    INSTALL_CMD="sudo pacman -Syu --noconfirm --needed"
    AUR_CMD="paru -Syu --noconfirm --needed"
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
    echo "❌ Не найден поддерживаемый пакет-менеджер"
    echo "   Поддерживаются: pacman, apt, dnf, xbps"
    exit 1
fi

echo "✅ Пакет-менеджер: $PKG_MANAGER"

# ========== ОПРЕДЕЛЯЕМ INIT SYSTEM ==========
echo ""
echo "🔍 Определяю init system..."

INIT_SYSTEM=""
if [ -d /run/systemd ]; then
    INIT_SYSTEM="systemd"
elif [ -f /etc/rc.conf ] || command -v runit-init &> /dev/null; then
    INIT_SYSTEM="runit"
elif [ -f /etc/dinit.d ] || command -v dinitctl &> /dev/null; then
    INIT_SYSTEM="dinit"
elif [ -f /etc/s6/rc.d ] || command -v s6-rc &> /dev/null; then
    INIT_SYSTEM="s6"
fi

if [ -z "$INIT_SYSTEM" ]; then
    echo "⚠️  Init system не определен автоматически"
    echo ""
    echo "Выбери init system:"
    echo "  1) systemd (рекомендуется)"
    echo "  2) dinit (для Artix)"
    echo "  3) runit (для Artix/Void)"
    echo "  4) s6 (для Artix)"
    read -p "Выбор (1-4): " init_choice
    
    case "$init_choice" in
        1) INIT_SYSTEM="systemd" ;;
        2) INIT_SYSTEM="dinit" ;;
        3) INIT_SYSTEM="runit" ;;
        4) INIT_SYSTEM="s6" ;;
        *) echo "❌ Неверный выбор"; exit 1 ;;
    esac
fi

echo "✅ Init system: $INIT_SYSTEM"
echo ""

# ========== ПАКЕТЫ = ОБЯЗАТЕЛЬНЫЕ ==========
echo "📋 Основные пакеты:"
BASE_PACKAGES=(
    niri
    waybar
    wofi
    kitty
    thunar
    firefox
    wl-clipboard
    swaybg
    libcanberra
    pavucontrol
    imagemagick
    gawk
    ttf-jetbrains-mono
    ttf-font-awesome
    polkit-gnome
    xarchiver
    inotify-tools
)

for pkg in "${BASE_PACKAGES[@]}"; do
    echo "  - $pkg"
done

echo ""
echo "📋 Пакеты для greetd:"
GREETD_PACKAGES=(
    greetd
)

case "$INIT_SYSTEM" in
    systemd)
        GREETD_PACKAGES+=("cage")
        echo "  - greetd (systemd)"
        ;;
    dinit)
        GREETD_PACKAGES+=("greetd-dinit")
        echo "  - greetd-dinit"
        ;;
    runit)
        GREETD_PACKAGES+=("greetd-runit")
        echo "  - greetd-runit
        ;;
    s6)
        GREETD_PACKAGES+=("greetd-s6")
        echo "  - greetd-s6"
        ;;
esac

echo ""
echo "📋 Опциональные пакеты (из AUR/extra):"
OPT_PACKAGES=(
    cliphist
    python-pywal
)

if [ "$USE_AUR" = true ]; then
    OPT_PACKAGES+=("swaylock-effects")
    OPT_PACKAGES+=("adw-gtk-theme")
    OPT_PACKAGES+=("greetd-regreet-git")
    OPT_PACKAGES+=("cage-git")
    echo "  - cliphist (история буфера обмена)"
    echo "  - swaylock-effects (красивая блокировка)"
    echo "  - python-pywal (генерация цветов из обоев)"
    echo "  - adw-gtk-theme (красивая GTK тема)"
    echo "  - greetd-regreet-git (красивый экран входа)"
    echo "  - cage-git (красивый compositor)"
else
    echo "  - cliphist (история буфера обмена)"
    echo "  - swaylock (стандартная блокировка)"
    echo "  - python-pywal (генерация цветов из обоев)"
    OPT_PACKAGES+=("swaylock")
fi

echo ""
echo "========================================"
echo "Начинаю установку..."
echo "========================================"
echo ""

# ========== УСТАНОВКА ОСНОВНЫХ ПА��ЕТОВ ==========
echo "🔧 Устанавливаю основные пакеты..."
$INSTALL_CMD ${BASE_PACKAGES[@]}
echo "✅ Основные пакеты установлены"
echo ""

# ========== УСТАНОВКА GREETD ==========
echo "🔧 Устанавливаю greetd..."
$INSTALL_CMD ${GREETD_PACKAGES[@]}
echo "✅ Greetd установлен"
echo ""

# ========== УСТАНОВКА ОПЦИОНАЛЬНЫХ (AUR) ==========
if [ "$USE_AUR" = true ]; then
    if command -v paru &> /dev/null; then
        echo "🔧 Устанавливаю пакеты из AUR..."
        $AUR_CMD ${OPT_PACKAGES[@]} || true
        echo "✅ AUR пакеты установлены (или уже есть)"
    else
        echo "⚠️  paru не найден (для AUR), пропускаю опциональные пакеты"
        echo "   Установи их вручную: paru -S ${OPT_PACKAGES[@]}"
    fi
else
    echo "🔧 Устанавливаю опциональные пакеты..."
    $INSTALL_CMD ${OPT_PACKAGES[@]} || true
    echo "✅ Опциональные пакеты установлены"
fi

echo ""
echo "========================================"
echo "✨ Все зависимости установлены!"
echo "========================================"
echo ""
echo "Дальше запусти: bash setup.sh"
echo ""
