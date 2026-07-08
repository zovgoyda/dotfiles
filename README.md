# 🎨 dotfiles

**Конфигурация для Niri WM с pywal темизацией и автоматической синхронизацией greetd/regreet**

## 📋 Что здесь

- **Niri** — wayland compositor
- **Waybar** — statusbar с интеграцией pywal
- **Wofi** — app launcher (быстро, красиво, с цветами)
- **Kitty** — терминал с поддержкой pywal
- **Regreet** — красивый экран входа для greetd
- **Pywal** — автоматическое создание цветовых схем из обоев
- **Cliphist** — история буфера обмена с превью картинок
- **Swaylock** — блокировка экрана

## 🚀 БЫСТРАЯ УСТАНОВКА 
```bash
curl -s https://raw.githubusercontent.com/zovgoyda/dotfiles/main/setup.sh | bash
```

**Или вручную:**

```bash
git clone https://github.com/zovgoyda/dotfiles ~/.config/dotfiles
cd ~/.config/dotfiles
bash setup.sh
```

**Всё!** Скрипт сам:
- ✅ Определит ОС и init system
- ✅ Установит все зависимости
- ✅ Создаст symlink'и конфигов
- ✅ Настроит greetd + regreet
- ✅ Даст права на скрипты

## 📦 Системные требования

### ОС
- **Arch Linux** (pacman)
- **Artix Linux** (pacman + dinit/runit/s6)
- **Debian/Ubuntu** (apt)
- **Fedora** (dnf)
- **Void Linux** (xbps)

### Init system
- **systemd** (или эмуляция в Artix)
- **dinit** (рекомендуется для Artix)
- **runit** (поддерживается)
- **s6** (поддерживается)

## 📖 Структура

```
.
├── setup.sh                         # 🚀 ГЛАВНЫЙ СКРИПТ (делает всё)
├── deps.sh                          # Отдельная установка зависимостей
├── install.sh                       # Отдельная установка конфигов
├── GREETD_SETUP.md                  # Дополнительная настройка greetd
├── README.md                        # Этот файл
│
├── niri/                            # Конфигурация Niri WM
├── waybar/                          # Конфиг + скрипты для statusbar
│   ├── config.json
│   ├── style.css
│   ├── theme.sh                     # Смена темы через pywal
│   ├── theme-toggle.sh              # Переключение dark/light
│   ├── cliphist.sh                  # История буфера обмена
│   ├── powermenu.sh                 # Меню выключения
│   ├── sync-greetd-theme.sh         # Синхронизация грита с pywal
│   └── sync-greetd-watcher.sh       # Мониторинг изменений в реальном времени
│
├── wofi/                            # Конфигурация app launcher
│   ├── config
│   └── style.css
│
├── kitty/                           # Конфигурация терминала
├── gtk-3.0/ & gtk-4.0/              # GTK темы
└── swaylock/                        # Конфигурация блокировки экрана
```

## 🎯 Основные возможности

### 🌈 Динамическая темизация

```bash
# Изменить обои и автоматически пересгенерировать тему
~/.config/waybar/theme.sh
```

Скрипт:
1. Открывает сетку обоев
2. Генерирует палитру через pywal
3. Обновляет waybar, wofi, niri, greetd/regreet цвета
4. Синхронизирует всё окружение

### 🔄 Синхронизация greetd/regreet

**Проблема**: При смене темы экран входа оставался светлым

**Решение**: Два скрипта работают в паре:

1. **sync-greetd-theme.sh** — основной скрипт синхронизации
   - Читает текущие цвета из pywal
   - Копирует обои на экран входа
   - Генерирует CSS с правильной цветопередачей
   - Обновляет конфиг regreet

2. **sync-greetd-watcher.sh** — фоновый мониторинг (опционально)
   - Следит за изменениями `~/.cache/wal/colors.sh`
   - Автоматически синхронизирует при смене темы
   - Требует `inotify-tools`

### 🖼 История буфера обмена

```bash
# Открыть историю с превью картинок
~/.config/waybar/cliphist.sh

# Очистить историю (right-click в waybar)
~/.config/waybar/cliphist.sh clear
```

### 💡 Переключение dark/light темы

```bash
# Переключить GTK тему (dark ↔ light)
~/.config/waybar/theme-toggle.sh

# Или явно
~/.config/waybar/theme-toggle.sh dark
~/.config/waybar/theme-toggle.sh light
```

## ⚙️ Настройка

### pywal

Если pywal установлен в нестандартном месте:

```bash
# Найди путь
which wal

# Обнови в скриптах
sed -i 's|WAL_BIN=.*|WAL_BIN="/путь/до/wal"|' ~/.config/waybar/theme.sh
```

### Обои

По умолчанию скрипт ищет обои в `~/wallpapers`. Если другой путь:

```bash
sed -i 's|WALLPAPER_DIR=.*|WALLPAPER_DIR="/твой/путь"|' ~/.config/waybar/theme.sh
```

### Шрифты

В конфигах используются:
- **JetBrains Mono** — основной моноширинный
- **Font Awesome** — иконки

Можешь заменить на свои в:
- `niri/config.kdl` — шрифт Niri
- `waybar/config.json` — шрифты Waybar
- `wofi/config` — шрифты Wofi
- `waybar/sync-greetd-theme.sh` (строка 70) — шрифт greetd

## 🔧 Трубблшутинг

### Тема не обновляется

```bash
# Проверь, что pywal установлен
which wal

# Проверь кэш цветов
cat ~/.cache/wal/colors.sh

# Запусти скрипт вручную для отладки
bash -x ~/.config/waybar/theme.sh
```

### Greetd не применяет цвета

```bash
# Проверь, что файлы созданы
ls -la /etc/greetd/theme/
cat /etc/greetd/regreet.toml

# Перезагрузи greetd
sudo systemctl restart greetd  # systemd
sudo dinitctl restart greetd   # dinit
```

### Cliphist не показывает превью

```bash
# ImageMagick должен быть установлен
which magick convert

# Проверь лог
journalctl -u wayland-session -f
```

## 📝 Дополнительно

- Смотри `GREETD_SETUP.md` для более глубокой настройки экрана входа
- Все скрипты используют переменные окружения и могут запускаться отдельно
- Конфигурации не требуют sudo (кроме greetd)

## 🎨 Пример темизации

```bash
# Изменить обои
~/.config/waybar/theme.sh  # откроется сетка обоев

# Система автоматически:
# 1. Генерирует цвета из выбранного изображения
# 2. Обновляет waybar, wofi, niri, kitty
# 3. Синхронизирует greetd/regreet (если настроен)
# 4. Отправляет уведомление
```

## 🙋 Вопросы?

Смотри
- `setup.sh` — главный скрипт установки
- `~/.config/waybar/theme.sh` — основной скрипт смены тем
- `~/.config/waybar/sync-greetd-watcher.sh` — автоматическая синхронизация
- `install.sh` — что устанавливается вручную
- `deps.sh` — какие пакеты нужны
