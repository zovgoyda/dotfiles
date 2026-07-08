# 🚀 Супер-установщик Dotfiles

## Быстрый старт (одна команда)

```bash
bash install-all.sh
```

Скрипт автоматически:
- ✅ Определит вашу ОС и пакет-менеджер
- ✅ Выберет правильный init system
- ✅ Установит все необходимые пакеты
- ✅ Скопирует конфигурации
- ✅ Настроит greetd + regreet
- ✅ Выставит права на скрипты
- ✅ Создаст бекапы старых конфигов

## Опции

```bash
bash install-all.sh --skip-packages   # Только конфиги, без пакетов
bash install-all.sh --only-packages   # Только пакеты, без конфигов
bash install-all.sh -h                # Справка
```

## Что происходит?

### 1️⃣ Определение окружения
- Определяет ОС (Arch, Ubuntu, Fedora, Void и др.)
- Находит пакет-менеджер (pacman, apt, dnf, xbps)
- Определяет init system (systemd, dinit, runit, s6)

### 2️⃣ Установка пакетов
Скрипт просит подтверждение перед установкой и показывает список пакетов.

**Базовые пакеты:**
- niri, waybar, wofi, kitty, thunar, firefox
- wl-clipboard, swaybg, libcanberra, pavucontrol
- imagemagick, gawk, ttf-jetbrains-mono, ttf-font-awesome
- polkit-gnome, xarchiver, inotify-tools, fastfetch

**Для greetd:**
- cage-git, wlroots0.20 (для systemd)
- greetd-dinit/runit/s6 (для других init систем)

**Опциональные (AUR/extra):**
- swaylock-effects, adw-gtk-theme
- greetd-regreet-git, cliphist, python-pywal

### 3️⃣ Установка конфигов
- Копирует конфигурации в ~/.config
- Создаёт бекапы старых конфигов
- Использует симлинки для удобства

### 4️⃣ Настройка greetd
- Автоматически настраивает экран входа
- Выбирает правильный compositor (cage-git или cage)
- Включает сервис в зависимости от init system
- Имеет fallback если cage не установлен

## Обработка ошибок

Скрипт имеет встроенную обработку ошибок:

- ❌ Если пакет не установился? → Спросит, продолжать ли
- ❌ Если cage-git не найден? → Используется обычный cage
- ❌ Если что-то сломалось? → Вся информация в логе

## Логи

Все логи сохраняются в:
```
~/.local/share/dotfiles-install-TIMESTAMP.log
```

При ошибке скрипт предложит открыть лог-файл в редакторе.

## Старые скрипты

Оставлены для совместимости:
- `deps.sh` — установка только зависимостей
- `setup.sh` — только установка конфигов
- `install.sh` — старый установщик
- `welcome.sh` — интерактивная настройка

## После установки

### 1. Сменить обои и генерировать тему
```bash
~/.config/waybar/theme.sh
```

### 2. Перезагрузить нири
```bash
Mod+Shift+R
```

### 3. (Опционально) Синхронизация greetd
```bash
bash ~/.config/waybar/sync-greetd-watcher.sh &
```

### 4. Отредактировать конфиги
```bash
nano ~/.config/niri/config.kdl
nano ~/.config/waybar/config.jsonc
```

## Что если что-то не работает?

1. **Посмотри логи:**
   ```bash
   cat ~/.local/share/dotfiles-install-*.log
   ```

2. **Проверь установленные пакеты:**
   ```bash
   pacman -Q | grep niri  # для Arch
   apt list --installed | grep niri  # для Ubuntu
   ```

3. **Восстанови бекап конфигов:**
   ```bash
   rm -rf ~/.config/niri
   cp -r ~/.config/.dotfiles-backup-*/niri ~/.config/
   ```

## Возможные проблемы

### cage/cage-git не найдены
**Решение:** Установи вручную:
```bash
paru -S cage-git wlroots0.20  # для Arch
```

### greetd не стартует
**Решение:** Проверь конфиг:
```bash
sudo systemctl status greetd
sudo journalctl -xe
```

### Симлинки не работают
**Решение:** Удали старые конфиги и переустанови:
```bash
rm -rf ~/.config/niri ~/.config/waybar
bash install-all.sh --skip-packages
```

## Поддерживаемые системы

✅ **Arch Linux** (и производные)
✅ **Ubuntu/Debian**
✅ **Fedora/RHEL**
✅ **Void Linux**
✅ **Artix Linux** (все init системы)

## Вклад

Если нашёл ошибку или хочешь добавить поддержку для другой ОС:
1. Проверь логи: `~/.local/share/dotfiles-install-*.log`
2. Создай issue или PR
