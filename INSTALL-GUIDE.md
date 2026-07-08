# 📖 Полное руководство по установке

## Содержание
- [Требования](#требования)
- [Быстрая установка](#быстрая-установка)
- [Пошаговая установка](#пошаговая-установка)
- [Устранение проблем](#устранение-проблем)
- [Полезные команды](#полезные-команды)

## Требования

### Минимальные
- Linux с wayland (нири работает только на wayland)
- sudo доступ (для установки системных пакетов)
- bash 4.0+
- Git (для клонирования репо)

### Поддерживаемые пакет-менеджеры
- `pacman` (Arch, Manjaro, Artix)
- `apt` (Ubuntu, Debian)
- `dnf` (Fedora, RHEL)
- `xbps` (Void Linux)

### Поддерживаемые init системы
- `systemd` (большинство дистрибьютивов)
- `dinit` (Artix)
- `runit` (Void, Artix)
- `s6` (Artix)

## Быстрая установка

### Вариант 1: Через git (рекомендуется)

```bash
# Клонируй репозиторий
git clone https://github.com/zovgoyda/dotfiles.git
cd dotfiles

# Запусти установщик
bash install-all.sh
```

### Вариант 2: Скачать ZIP

```bash
# Скачай и распакуй
wget https://github.com/zovgoyda/dotfiles/archive/main.zip
unzip main.zip
cd dotfiles-main

# Запусти установщик
bash install-all.sh
```

## Пошаговая установка

Если хочешь больше контроля, используй отдельные скрипты:

### Шаг 1: Только пакеты
```bash
bash deps.sh
```

### Шаг 2: Только конфиги
```bash
bash setup.sh
```

### Или всё одновременно
```bash
bash install-all.sh
```

## Что происходит внутри

### `install-all.sh` делает:

1. **Определение окружения**
   - Находит ОС и пакет-менеджер
   - Определяет init system
   - Спрашивает подтверждение

2. **Установка пакетов** (если не отключена)
   - Базовые пакеты: niri, waybar, wofi и т.д.
   - Greetd + зависимости
   - Опциональные пакеты (AUR)

3. **Установка конфигов**
   - Копирует ~/.config/niri
   - Копирует ~/.config/waybar
   - И другие конфиги (wofi, kitty, gtk и т.д.)
   - Создаёт бекапы старых конфигов

4. **Права и разрешения**
   - Выставляет права на исполнение
   - Настраивает greetd сервис

5. **Логирование**
   - Сохраняет всё в лог-файл
   - Показывает прогресс в реальном времени

## Устранение проблем

### Проблема: "Пакет-менеджер не найден"

**Причина:** ОС не поддерживается  
**Решение:**
1. Найди корректную команду установки для твоей ОС
2. Отредактируй скрипт или установи вручную

```bash
# Установка вручную для Arch
sudo pacman -Syu niri waybar wofi kitty --needed

# Для Ubuntu
sudo apt update && sudo apt install niri waybar wofi kitty
```

### Проблема: Недостаточно прав

**Причина:** Нужен sudo  
**Решение:**
```bash
# Убедись, что у тебя есть sudo доступ
sudo -l

# Если нет, добавь себя в sudoers (как root)
usermod -aG sudo username
```

### Проблема: cage-git не установился

**Причина:** Пакет из AUR, нужен paru  
**Решение:**
```bash
# Установи paru
sudo pacman -S paru

# Потом переустанови
bash install-all.sh --only-packages
```

### Проблема: greetd не стартует

**Причина:** Неверная конфигурация  
**Решение:**
```bash
# Проверь статус
sudo systemctl status greetd

# Посмотри ошибки
sudo journalctl -xe

# Переконфигурируй
sudo nano /etc/greetd/config.toml
```

### Проблема: Нири не запускается после установки

**Причина:** Отсутствуют зависимости  
**Решение:**
```bash
# Проверь логи
cat ~/.local/share/dotfiles-install-*.log

# Установи недостающие пакеты вручную
sudo pacman -S libxkbcommon libxkbcommon-x11

# Попробуй запустить нири
niri
```

## Полезны�� команды

### После установки

```bash
# Сменить обои и генерировать тему
~/.config/waybar/theme.sh

# Открыть меню выключения/перезагрузки
~/.config/waybar/powermenu.sh

# История буфера обмена
~/.config/waybar/cliphist.sh

# Переключить dark/light тему
~/.config/waybar/theme-toggle.sh

# Синхронизировать greetd с текущей темой
~/.config/waybar/sync-greetd-theme.sh
```

### Редактирование конфигов

```bash
# Niri конфиг
nano ~/.config/niri/config.kdl

# Waybar конфиг
nano ~/.config/waybar/config.jsonc

# Wofi конфиг
nano ~/.config/wofi/config

# Kitty конфиг
nano ~/.config/kitty/kitty.conf
```

### Проверка статуса

```bash
# Проверить установленные пакеты
pacman -Q | grep niri

# Проверить greetd
sudo systemctl status greetd

# Проверить логи установки
cat ~/.local/share/dotfiles-install-*.log

# Информация о системе
fastfetch
```

### Откат изменений

```bash
# Восстановить конфиги из бекапа
rm -rf ~/.config/niri ~/.config/waybar
cp -r ~/.config/.dotfiles-backup-*/niri ~/.config/
cp -r ~/.config/.dotfiles-backup-*/waybar ~/.config/

# Удалить установленные пакеты
sudo pacman -R niri waybar wofi  # для Arch

# Отключить greetd
sudo systemctl disable greetd
```

## Дополнительные ресурсы

- 📖 [Документация Niri](https://github.com/YaLTeR/niri)
- 📖 [Документация Waybar](https://github.com/Alexays/Waybar)
- 📖 [Документация Pywal](https://github.com/dylanaraps/pywal)
- 🐛 [Сообщить об ошибке](https://github.com/zovgoyda/dotfiles/issues)

## Контакты

Если что-то не работает:
1. Проверь [раздел проблем](https://github.com/zovgoyda/dotfiles/issues)
2. Посмотри логи: `cat ~/.local/share/dotfiles-install-*.log`
3. Создай новый issue с описанием и логами
