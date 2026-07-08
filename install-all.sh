#!/bin/bash
# 🚀 СУПЕР-УСТАНОВЩИК DOTFILES
# Одна команда = всё готово от начала до конца
# Современный, универсальный, с обработкой ошибок и fallback
#
# Использование:
#   bash install-all.sh
#   bash install-all.sh --skip-packages  (только конфиги)
#   bash install-all.sh --only-packages  (только пакеты)

set -E

# ==================== КОНФИГУРАЦИЯ ====================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$HOME/.local/share/dotfiles-install-$(date +%s).log"
BAKUP_DIR="$HOME/.config/.dotfiles-backup-$(date +%s)"

# Создаём папку для логов
mkdir -p "$(dirname "$LOG_FILE")"

# ==================== ЦВЕТА И ЛОГИРОВАНИЕ ====================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

log_step() {
    echo -e "\n${CYAN}▶${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}✅${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}⚠️${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}❌${NC} $1" >&2 | tee -a "$LOG_FILE"
}

log_info() {
    echo -e "${MAGENTA}ℹ️${NC} $1" | tee -a "$LOG_FILE"
}

# ==================== ОБРАБОТКА ОШИБОК ====================
error_handler() {
    local line_no=$1
    log_error "Ошибка на строке $line_no"
    log_info "Логи сохранены в: $LOG_FILE"
    
    if ask_user "Хочешь открыть лог-файл?"; then
        ${EDITOR:-nano} "$LOG_FILE"
    fi
}

trap 'error_handler $LINENO' ERR

# ==================== УТИЛИТЫ ====================
command_exists() {
    command -v "$1" &> /dev/null
}

ask_user() {
    local prompt="$1"
    local response
    
    while true; do
        echo -ne "${BLUE}?${NC} $prompt (да/нет): "
        read -r response
        
        case "$response" in
            [дДyY][еEsS]|да|yes|y) return 0 ;;
            [нNnN][еEoO]|нет|no|n) return 1 ;;
            *) echo "Пожалуйста ответь 'да' или 'нет'" ;;
        esac
    done
}

select_option() {
    local prompt="$1"
    shift
    local options=("$@")
    local choice
    
    echo -e "\n${BLUE}?${NC} $prompt"
    for i in "${!options[@]}"; do
        echo "  $((i+1))) ${options[$i]}"
    done
    
    while true; do
        echo -ne "${BLUE}Выбор (1-${#options[@]}):${NC} "
        read -r choice
        
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#options[@]} ]; then
            echo "${options[$((choice-1))]}"
            return 0
        fi
    done
}

# ==================== ЗАГОЛОВОК ====================
show_header() {
    clear
    cat << "EOF"
╔════════════════════════════════════════════════════════════════════════════════╗
║                                                                                ║
║    🎨  DOTFILES: Полная установка для Niri + Pywal                            ║
║    🚀  Суперустановщик с обработкой ошибок и fallback                         ║
║                                                                                ║
╚════════════════════════════════════════════════════════════════════════════════╝
EOF
}

# ==================== ОПРЕДЕЛЕНИЕ ОКРУЖЕНИЯ ====================
detect_environment() {
    log_step "Определяю окружение..."
    
    # ОС
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_ID="${ID}"
        OS_PRETTY="${PRETTY_NAME}"
    else
        log_error "Не могу определить ОС"
        return 1
    fi
    log_success "ОС: $OS_PRETTY"
    
    # Пакет-менеджер
    if command_exists pacman; then
        PKG_MANAGER="pacman"
        INSTALL_CMD="sudo pacman -Syu --needed --noconfirm"
        REMOVE_CMD="sudo pacman -R --noconfirm"
        AUR_CMD="paru -Syu --needed --noconfirm"
        USE_AUR=true
    elif command_exists apt; then
        PKG_MANAGER="apt"
        INSTALL_CMD="sudo apt update && sudo apt install -y"
        REMOVE_CMD="sudo apt remove -y"
        USE_AUR=false
    elif command_exists dnf; then
        PKG_MANAGER="dnf"
        INSTALL_CMD="sudo dnf install -y"
        REMOVE_CMD="sudo dnf remove -y"
        USE_AUR=false
    elif command_exists xbps-install; then
        PKG_MANAGER="xbps"
        INSTALL_CMD="sudo xbps-install -Sy"
        REMOVE_CMD="sudo xbps-remove -R"
        USE_AUR=false
    else
        log_error "Пакет-менеджер не найден (pacman, apt, dnf, xbps)"
        return 1
    fi
    log_success "Пакет-менеджер: $PKG_MANAGER"
    
    # Init system
    INIT_SYSTEM=""
    if [ -d /run/systemd/system ]; then
        INIT_SYSTEM="systemd"
    elif command_exists dinitctl; then
        INIT_SYSTEM="dinit"
    elif command_exists sv; then
        INIT_SYSTEM="runit"
    elif command_exists s6-rc; then
        INIT_SYSTEM="s6"
    fi
    
    if [ -z "$INIT_SYSTEM" ]; then
        INIT_SYSTEM=$(select_option "Выб��ри init system" "systemd" "dinit" "runit" "s6")
    fi
    log_success "Init system: $INIT_SYSTEM"
}

# ==================== УСТАНОВКА ПАКЕТОВ ====================
install_packages() {
    log_step "Установка пакетов для $PKG_MANAGER..."
    
    # Базовые пакеты
    BASE_PACKAGES=(
        niri waybar wofi kitty thunar firefox wl-clipboard swaybg
        libcanberra pavucontrol imagemagick gawk ttf-jetbrains-mono
        ttf-font-awesome polkit-gnome xarchiver inotify-tools fastfetch
        noto-fonts-cjk
    )
    
    # Greetd пакеты
    GREETD_PACKAGES=(greetd)
    case "$INIT_SYSTEM" in
        systemd)
            GREETD_PACKAGES+=(greetd)
            ;;
        dinit)
            GREETD_PACKAGES+=(greetd-dinit)
            ;;
        runit)
            GREETD_PACKAGES+=(greetd-runit)
            ;;
        s6)
            GREETD_PACKAGES+=(greetd-s6)
            ;;
    esac
    
    # Опциональные пакеты
    OPT_PACKAGES=(cliphist python-pywal)
    if [ "$USE_AUR" = true ]; then
        OPT_PACKAGES+=(swaylock-effects adw-gtk-theme greetd-regreet-git cage-git wlroots0.20)
    else
        OPT_PACKAGES+=(swaylock)
    fi
    
    # Вывод списка
    log_info "Будут установлены пакеты:"
    log_info "  Базовые: ${#BASE_PACKAGES[@]} пакетов"
    log_info "  Greetd: ${#GREETD_PACKAGES[@]} пакетов"
    log_info "  Опциональные: ${#OPT_PACKAGES[@]} пакетов"
    
    if ! ask_user "Продолжить установку?"; then
        log_warning "Установка пакетов отменена пользователем"
        return 1
    fi
    
    # Установка базовых
    log_step "Устанавливаю базовые пакеты..."
    if $INSTALL_CMD ${BASE_PACKAGES[@]}; then
        log_success "Базовые пакеты установлены"
    else
        log_error "Ошибка при установке базовых пакетов"
        if ask_user "Продолжить несмотря на ошибку?"; then
            log_warning "Продолжаю..."
        else
            return 1
        fi
    fi
    
    # Установка greetd
    log_step "Устанавливаю greetd..."
    if [ "$USE_AUR" = true ]; then
        $AUR_CMD ${GREETD_PACKAGES[@]} 2>&1 | tee -a "$LOG_FILE" || true
    else
        $INSTALL_CMD ${GREETD_PACKAGES[@]} 2>&1 | tee -a "$LOG_FILE" || true
    fi
    log_success "Greetd установлен"
    
    # Установка опциональных
    log_step "Устанавливаю опциональные пакеты..."
    if [ "$USE_AUR" = true ]; then
        if command_exists paru; then
            $AUR_CMD ${OPT_PACKAGES[@]} 2>&1 | tee -a "$LOG_FILE" || log_warning "Некоторые AUR пакеты не установились"
        else
            log_warning "paru не найден, пропускаю AUR пакеты"
        fi
    else
        $INSTALL_CMD ${OPT_PACKAGES[@]} 2>&1 | tee -a "$LOG_FILE" || log_warning "Некоторые пакеты не установились"
    fi
    log_success "Опциональные пакеты установлены"
}

# ==================== УСТАНОВКА КОНФИГОВ ====================
install_configs() {
    log_step "Установка конфигураций..."
    
    CONFIG_DIR="$HOME/.config"
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$BAKUP_DIR"
    
    CONFIGS=(waybar wofi gtk-3.0 gtk-4.0 kitty niri swaylock fastfetch)
    
    for config in "${CONFIGS[@]}"; do
        src="$SCRIPT_DIR/$config"
        dst="$CONFIG_DIR/$config"
        
        if [ ! -d "$src" ]; then
            log_warning "Конфиг не найден: $config"
            continue
        fi
        
        # Бекап существующего конфига
        if [ -e "$dst" ] && [ ! -L "$dst" ]; then
            log_info "Бекапирую существующий конфиг: $config"
            mv "$dst" "$BAKUP_DIR/$config"
        fi
        
        # Удаляем старый симлинк
        if [ -L "$dst" ]; then
            rm "$dst"
        fi
        
        # Создаём новый симлинк
        ln -s "$src" "$dst"
        log_success "$config → ~/.config/$config"
    done
    
    log_info "Бекапы сохранены в: $BAKUP_DIR"
}

# ==================== ПРАВА НА СКРИПТЫ ====================
fix_script_permissions() {
    log_step "Выставляю права на исполнение скриптам..."
    find "$SCRIPT_DIR" -type f -name "*.sh" -exec chmod +x {} \;
    log_success "Права установлены"
}

# ==================== НАСТРОЙКА GREETD ====================
setup_greetd() {
    log_step "Настраиваю greetd + regreet..."
    
    if ! command_exists greetd; then
        log_warning "greetd не установлен, пропускаю"
        return 0
    fi
    
    # Создаём директорию
    sudo mkdir -p /etc/greetd/theme
    sudo chown -R greeter:greeter /etc/greetd/theme
    sudo chmod 755 /etc/greetd/theme
    
    # Конфиг greetd
    local cage_cmd="cage-git"
    if ! command_exists cage-git; then
        if command_exists cage; then
            cage_cmd="cage"
            log_warning "cage-git не найден, используем обычный cage"
        else
            log_error "cage/cage-git не найдены!"
            if ask_user "Использовать fallback конфиг без cage?"; then
                cage_cmd=""
            else
                return 1
            fi
        fi
    fi
    
    local cmd_line=""
    if [ -n "$cage_cmd" ]; then
        cmd_line="command = \"$cage_cmd -s -m last -- regreet\""
    else
        cmd_line="command = \"regreet\""
        log_warning "greetd будет запускать regreet напрямую (может быть нестабильно)"
    fi
    
    sudo tee /etc/greetd/config.toml > /dev/null <<EOF
[terminal]
vt = 1

[default_session]
$cmd_line
user = "greeter"
EOF
    
    # Конфиг окружений
    sudo tee /etc/greetd/environments > /dev/null <<'EOF'
niri
EOF
    
    # Конфиг regreet
    if [ ! -f /etc/greetd/regreet.toml ]; then
        sudo touch /etc/greetd/regreet.toml
    fi
    sudo chown greeter:$(id -g greeter 2>/dev/null || echo greeter) /etc/greetd/regreet.toml 2>/dev/null || \
    sudo chown greeter:greeter /etc/greetd/regreet.toml
    sudo chmod 664 /etc/greetd/regreet.toml
    
    # Включаем сервис
    case "$INIT_SYSTEM" in
        systemd)
            sudo systemctl enable greetd 2>&1 | tee -a "$LOG_FILE"
            log_success "greetd включен для systemd"
            ;;
        dinit)
            sudo dinitctl enable greetd 2>&1 | tee -a "$LOG_FILE" || log_warning "dinit enable failed"
            log_success "greetd настроен для dinit"
            ;;
        runit)
            if [ -f /etc/runit/sv/greetd/run ]; then
                sudo ln -sf /etc/runit/sv/greetd /etc/runit/runsvdir/default/ 2>&1 | tee -a "$LOG_FILE"
                log_success "greetd настроен для runit"
            else
                log_warning "runit greetd сервис не найден"
            fi
            ;;
        s6)
            log_info "Для s6: используй s6-rc-update вручную"
            ;;
    esac
}

# ==================== ЗАВЕРШЕНИЕ ====================
show_summary() {
    cat << "EOF"

╔════════════════════════════════════════════════════════════════════════════════╗
║                                                                                ║
║                   ✨ УСТАНОВКА ЗАВЕРШЕНА! ✨                                   ║
║                                                                                ║
║  Доступные команды:                                                           ║
║  • ~/.config/waybar/theme.sh       — сменить обои и генерировать тему        ║
║  • ~/.config/waybar/powermenu.sh   — меню выключения/перезагрузки            ║
║  • ~/.config/waybar/cliphist.sh    — история буфера обмена                   ║
║                                                                                ║
║  Следующие шаги:                                                              ║
║  1. (Опционально) Отредактируй конфиги:                                       ║
║     nano ~/.config/niri/config.kdl                                             ║
║     nano ~/.config/waybar/config.jsonc                                         ║
║                                                                                ║
║  2. Перезагрузи сессию (Mod+Shift+R в niri) или перезагрузись                ║
║                                                                                ║
║  3. Запусти theme.sh для генерации темы:                                       ║
║     ~/.config/waybar/theme.sh                                                  ║
║                                                                                ║
║  Логи сохранены в: $LOG_FILE                                                  ║
║                                                                                ║
╚════════════════════════════════════════════════════════════════════════════════╝
EOF
}

# ==================== ОСНОВНОЙ ФЛОУ ====================
main() {
    show_header
    
    local skip_packages=false
    local only_packages=false
    
    # Парсим аргументы
    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-packages)
                skip_packages=true
                shift
                ;;
            --only-packages)
                only_packages=true
                shift
                ;;
            -h|--help)
                cat << 'EOF'
Использование: bash install-all.sh [ОПЦИИ]

Опции:
  --skip-packages    Пропустить установку пакетов, только конфиги
  --only-packages    Установить только пакеты, без конфигов
  -h, --help         Показать эту справку
EOF
                exit 0
                ;;
            *)
                log_error "Неизвестная опция: $1"
                exit 1
                ;;
        esac
    done
    
    log_info "Логи пишутся в: $LOG_FILE"
    echo ""
    
    # Определяем окружение
    if ! detect_environment; then
        log_error "Не удалось определить окружение"
        exit 1
    fi
    
    echo ""
    
    # Устанавливаем пакеты
    if [ "$only_packages" = false ]; then
        if [ "$skip_packages" = false ]; then
            if ! install_packages; then
                log_error "Установка пакетов не завершена"
                if ! ask_user "Продолжить без пакетов?"; then
                    exit 1
                fi
            fi
            echo ""
        fi
        
        # Устанавливаем конфиги
        install_configs
        echo ""
        
        # Выставляем права
        fix_script_permissions
        echo ""
        
        # Настраиваем greetd
        setup_greetd
        echo ""
    else
        install_packages
    fi
    
    # Итоговое резюме
    if [ "$only_packages" = false ]; then
        show_summary
    fi
}

main "$@"
