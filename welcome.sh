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

# ==================== НАЧАЛО ====================
clear
echo ""
echo -e "${MAGENTA}╔$(printf '=%.0s' {1..58})╗${NC}"
echo -e "${MAGENTA}║${NC}  🎨 Добро пожаловать в Dotfiles!${NC}"
echo -e "${MAGENTA}║${NC}${NC}  Давай наст��оим всё для тебя  🚀"
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

# ==================== 2. ПРОВЕРКА ЗАВИСИМОСТЕЙ ====================
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

# ==================== 3. ГЕНЕРАЦИЯ НАЧАЛЬНОЙ ТЕМЫ ====================
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

# ==================== 4. ОПЦИОНАЛЬНЫЕ СЕРВИСЫ ====================
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

# ==================== 5. ИНФОРМАЦИЯ О СИСТЕМЕ ====================
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
echo ""

echo -e "${MAGENTA}🚀 Начинай с этого:${NC}"
echo "  ~/.config/waybar/theme.sh"
echo ""

echo -e "${GREEN}✨ Спасибо за использование Dotfiles! ✨${NC}"
echo ""
