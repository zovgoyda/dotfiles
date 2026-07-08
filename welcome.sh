#!/bin/bash
# 🎨 ПРИВЕТСТВЕННЫЙ СКРИПТ DOTFILES
# Интерактивная настройка после установки
# Выбор папки с обоями, генерация темы, настройка путей

set -e

# ==================== ЦВЕТА ====================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ==================== ФУНКЦИИ ====================
print_header() {
    echo ""
    echo -e "${CYAN}╔$(printf '=%.0s' {1..60})╗${NC}"
    echo -e "${CYAN}║${NC}  $1"
    echo -e "${CYAN}╚$(printf '=%.0s' {1..60})╝${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✅${NC} $1"
}

print_error() {
    echo -e "${RED}❌${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠️${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ️${NC} $1"
}

read_choice() {
    local prompt="$1"
    local response
    read -p "$(echo -e ${BLUE})▶${NC} $prompt: " response
    echo "$response"
}

# ==================== ФУНКЦИЯ: НАСТРОЙКА МОНИТОРОВ ====================
setup_monitors() {
    echo ""
    print_header "🖥️  Настройка мониторов"
    
    CONFIG_DIR="$HOME/.config"
    NIRI_OUTPUTS="$CONFIG_DIR/niri/add/outputs.kdl"
    
    if ! command -v wlr-randr &> /dev/null; then
        print_warning "wlr-randr не установлен, используем встроенные функции"
        return
    fi
    
    echo -e "${BLUE}Обнаруженные мониторы:${NC}"
    echo ""
    
    # Получаем список мониторов
    wlr-randr --help &>/dev/null || {
        print_info "Пропускаем автоопределение мониторов"
        return
    }
    
    # Показываем текущую конфигурацию
    if [ -f "$NIRI_OUTPUTS" ]; then
        echo -e "${CYAN}Текущая конфигурация outputs.kdl:${NC}"
        cat "$NIRI_OUTPUTS"
        echo ""
    fi
    
    monitor_choice=$(read_choice "Ты хочешь отредактировать конфиг мониторов? (да/нет)")
    
    if [ "$monitor_choice" = "да" ] || [ "$monitor_choice" = "yes" ] || [ "$monitor_choice" = "y" ]; then
        if command -v nano &> /dev/null; then
            nano "$NIRI_OUTPUTS"
            print_success "Конфиг мониторов обновлен"
        else
            print_warning "nano не установлен, отредактируй вручную: $NIRI_OUTPUTS"
        fi
    fi
    
    # Обновляем координаты в window-rules для адаптивности
    update_floating_positions
}

# ==================== ФУНКЦИЯ: АДАПТИВНАЯ ПОЗИЦИЯ ОКОН ====================
update_floating_positions() {
    echo ""
    print_info "Адаптирую координаты окон к твоему разрешению..."
    
    CONFIG_DIR="$HOME/.config"
    NIRI_WINDOWRULES="$CONFIG_DIR/niri/add/windowrules.kdl"
    
    if [ ! -f "$NIRI_WINDOWRULES" ]; then
        return
    fi
    
    # Получаем разрешение экрана
    if command -v wlr-randr &> /dev/null 2>/dev/null; then
        # Пытаемся получить ширину из wlr-randr
        SCREEN_WIDTH=$(wlr-randr 2>/dev/null | grep -oP '\d+x\d+' | head -1 | cut -d'x' -f1 || echo "3440")
    else
        SCREEN_WIDTH=3440  # Значение по умолчанию
    fi
    
    # Если разрешение отличается от стандартного (3440), масштабируем
    if [ "$SCREEN_WIDTH" != "3440" ]; then
        SCALE=$(echo "scale=3; $SCREEN_WIDTH / 3440" | bc 2>/dev/null || echo "1")
        
        print_info "Ширина экрана: ${SCREEN_WIDTH}px (масштаб: ${SCALE})"
        
        # Масштабируем позиции павконтрола (было x=2550)
        NEW_X=$(echo "$SCALE * 2550" | bc | cut -d'.' -f1)
        
        # Создаём временный файл с обновленными координатами
        sed -i "s/x=2550/x=$NEW_X/g" "$NIRI_WINDOWRULES"
        
        print_success "Позиции окон адаптирова��ы (x=$NEW_X)"
    fi
}

# ==================== НАЧАЛО ====================
clear
echo ""
echo -e "${MAGENTA}╔$(printf '=%.0s' {1..58})╗${NC}"
echo -e "${MAGENTA}║${NC}  🎨 Добро пожаловать в Dotfiles!${NC}"
echo -e "${MAGENTA}║${NC}${NC}  Давай настроим всё для тебя  🚀"
echo -e "${MAGENTA}╚$(printf '=%.0s' {1..58})╝${NC}"
echo ""

CONFIG_DIR="$HOME/.config"
DOTFILES_DIR="$CONFIG_DIR/dotfiles"
WAYBAR_SCRIPT="$CONFIG_DIR/waybar/theme.sh"

# ==================== 1. ВЫБОР ПАПКИ С ОБОЯМИ ====================
print_header "1️⃣  Выбор папки с обоями"

echo -e "${BLUE}Где находятся твои обои?${NC}"
echo ""
echo "Варианты:"
echo "  1) ~/wallpapers (по умолчанию)"
echo "  2) ~/Pictures/wallpapers"
echo "  3) ~/Downloads/wallpapers"
echo "  4) Другая папка (указать вручную)"
echo ""

wallpaper_choice=$(read_choice "Выбор (1-4)")

case "$wallpaper_choice" in
    1)
        WALLPAPER_DIR="$HOME/wallpapers"
        ;;
    2)
        WALLPAPER_DIR="$HOME/Pictures/wallpapers"
        ;;
    3)
        WALLPAPER_DIR="$HOME/Downloads/wallpapers"
        ;;
    4)
        WALLPAPER_DIR=$(read_choice "Полный путь к папке с обоями")
        ;;
    *)
        WALLPAPER_DIR="$HOME/wallpapers"
        print_warning "Неверный выбор, используем ~/wallpapers"
        ;;
esac

# Создаём папку если её нет
if [ ! -d "$WALLPAPER_DIR" ]; then
    mkdir -p "$WALLPAPER_DIR"
    print_info "Создал папку: $WALLPAPER_DIR"
fi

# Обновляем путь в theme.sh
if [ -f "$WAYBAR_SCRIPT" ]; then
    sed -i "s|WALLPAPER_DIR=.*|WALLPAPER_DIR=\"$WALLPAPER_DIR\"|" "$WAYBAR_SCRIPT"
    print_success "Обновлен путь в theme.sh: $WALLPAPER_DIR"
else
    print_warning "theme.sh не найден"
fi

echo ""

# ==================== 2. НАСТРОЙКА МОНИТОРОВ ====================
setup_monitors

# ==================== 3. ПРОВЕРКА ЗАВИСИМОСТЕЙ ====================
print_header "2️⃣  Проверка зависимостей"

echo -e "${BLUE}Проверяю необходимые программы...${NC}"
echo ""

DEPS_OK=true

# Проверяем pywal
if command -v wal &> /dev/null; then
    WAL_PATH=$(which wal)
    print_success "pywal найден: $WAL_PATH"
else
    print_warning "pywal не установлен (нужен для генерации тем)"
    DEPS_OK=false
fi

# Проверяем fastfetch
if command -v fastfetch &> /dev/null; then
    print_success "fastfetch установлен ✓"
else
    print_warning "fastfetch не установлен"
fi

# Проверяем inotify-tools
if command -v inotifywait &> /dev/null; then
    print_success "inotify-tools установлен ✓"
else
    print_warning "inotify-tools не установлен (нужен для автосинхронизации greetd)"
fi

echo ""

if [ "$DEPS_OK" = false ]; then
    print_warning "Некоторые зависимости отсутствуют. Продолжаем установку..."
fi

echo ""

# ==================== 4. ГЕНЕРАЦИЯ НАЧАЛЬНОЙ ТЕМЫ ====================
print_header "3️⃣  Генерация начальной темы"

echo -e "${BLUE}Хочешь сгенерировать тему прямо сейчас?${NC}"
echo ""
echo "Если скажешь 'да', я:"
echo "  • Откажу список обоев из $WALLPAPER_DIR"
echo "  • Ты выберешь обои"
echo "  • Я сгенерирую тему и обновлю все компоненты"
echo ""

theme_choice=$(read_choice "Генерировать тему сейчас? (да/нет)")

if [ "$theme_choice" = "да" ] || [ "$theme_choice" = "yes" ] || [ "$theme_choice" = "y" ]; then
    if [ -f "$WAYBAR_SCRIPT" ] && command -v wal &> /dev/null; then
        echo ""
        print_info "Запускаю theme.sh..."
        echo ""
        bash "$WAYBAR_SCRIPT"
        print_success "Тема сгенерирована!"
    else
        print_error "Не могу запустить theme.sh (pywal или theme.sh не найдены)"
    fi
else
    print_info "OK, можешь запустить theme.sh позже:"
    echo "    ~/.config/waybar/theme.sh"
fi

echo ""

# ==================== 5. ОПЦИОНАЛЬНЫЕ СЕРВИСЫ ====================
print_header "4️⃣  Опциональные сервисы в фоне"

echo -e "${BLUE}Запустить дополнительные сервисы?${NC}"
echo ""
echo "Доступные опции:"
echo "  • sync-greetd-watcher.sh (автосинхронизация экрана входа при смене темы)"
echo ""

watcher_choice=$(read_choice "Запустить watcher? (да/нет)")

if [ "$watcher_choice" = "да" ] || [ "$watcher_choice" = "yes" ] || [ "$watcher_choice" = "y" ]; then
    WATCHER_SCRIPT="$CONFIG_DIR/waybar/sync-greetd-watcher.sh"
    if [ -f "$WATCHER_SCRIPT" ] && command -v inotifywait &> /dev/null; then
        bash "$WATCHER_SCRIPT" &
        WATCHER_PID=$!
        print_success "Watcher запущен (PID: $WATCHER_PID)"
        print_info "Чтобы остановить: kill $WATCHER_PID"
    else
        print_warning "Watcher недоступен (inotify-tools не установлен или скрипт не найден)"
    fi
else
    print_info "Можешь запустить watcher позже:"
    echo "    bash ~/.config/waybar/sync-greetd-watcher.sh &"
fi

echo ""

# ==================== 6. ИНФОРМАЦИЯ О СИСТЕМЕ ====================
print_header "5️⃣  Информация о системе"

echo -e "${BLUE}Твоя система:${NC}"
echo ""
if command -v fastfetch &> /dev/null; then
    fastfetch
else
    neofetch 2>/dev/null || echo "Установи fastfetch или neofetch для красивого вывода информации"
fi

echo ""

# ==================== ИТОГИ ====================
print_header "🎉 Всё готово!"

echo -e "${GREEN}Твоя установка готова к использованию!${NC}"
echo ""
echo -e "${CYAN}📁 Папка с обоями:${NC}      $WALLPAPER_DIR"
echo -e "${CYAN}⚙️  Конфиги:${NC}            ~/.config/"
echo -e "${CYAN}🎨 Смена обоев:${NC}         ~/.config/waybar/theme.sh"
echo -e "${CYAN}🔄 Синхронизация:${NC}       ~/.config/waybar/sync-greetd-watcher.sh"
echo ""

echo -e "${YELLOW}💡 Советы:${NC}"
echo "  1. Положи обои в: $WALLPAPER_DIR"
echo "  2. Запусти theme.sh для смены обоев и генерации темы"
echo "  3. Посмотри README.md для полной документации"
echo "  4. Если мониторы выглядят странно, отредактируй:"
echo "     ~/.config/niri/add/outputs.kdl"
echo ""

echo -e "${MAGENTA}🚀 Начинай с этого:${NC}"
echo "  ~/.config/waybar/theme.sh"
echo ""

echo -e "${GREEN}✨ Спасибо за использование Dotfiles! ✨${NC}"
echo ""
