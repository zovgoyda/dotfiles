# Синхронизация greetd/regreet с pywal темой

## Описание

Этот набор скриптов обеспечивает автоматическую синхронизацию экрана входа (greetd + regreet) с текущей pywal палитрой и обоями.

### Что синхронизируется:
- ✅ Обои экрана входа
- ✅ Цвета (из pywal палитры)
- ✅ Темная тема GTK

## Установка

### 1. Убедись, что установлены зависимости:

```bash
sudo pacman -S inotify-tools  # Arch Linux
# или
sudo apt install inotify-tools  # Debian/Ubuntu
```

### 2. Дай права на исполнение скриптам:

```bash
chmod +x ~/.config/waybar/sync-greetd-theme.sh
chmod +x ~/.config/waybar/sync-greetd-watcher.sh
```

### 3. Создай необходимые директории и файлы:

```bash
sudo mkdir -p /etc/greetd/theme
sudo touch /etc/greetd/regreet.toml
sudo chown -R greeter:greeter /etc/greetd/theme
sudo chmod 755 /etc/greetd/theme
```

### 4. Запусти синхронизацию вручную (опционально):

```bash
bash ~/.config/waybar/sync-greetd-theme.sh
```

## Использование

### Вариант 1: Запуск в фоне (рекомендуется)

Добавь в свой `~/.config/hyprland/hyprland.conf` или другой конфиг WM:

```bash
exec-once = ~/.config/waybar/sync-greetd-watcher.sh &
```

Это запустит watcher, который будет следить за изменениями pywal палитры и обоев в реальном времени.

### Вариант 2: Ручной запуск при смене темы

Скрипт уже вызывается из `waybar/theme.sh`, так что синхронизация происходит автоматически при смене темы через waybar.

## Как это работает

1. **sync-greetd-theme.sh** — основной скрипт, который:
   - Читает палитру из `~/.cache/wal/colors.sh`
   - Копирует текущие обои в `/etc/greetd/theme/wall.png`
   - Генерирует CSS с правильными цветами
   - Обновляет конфиг regreet с темной темой

2. **sync-greetd-watcher.sh** — следит за файлами (`colors.sh` и `current_wallpaper`) и автоматически запускает синхронизацию при изменении

## Трубблшутинг

### CSS не применяется

Убедись, что:
- `/etc/greetd/theme/regreet.css` существует и имеет правильные права
- `gtk_theme_name = "Adwaita-dark"` в `/etc/greetd/regreet.toml`
- ReGreet перезагружен (`sudo systemctl restart greetd`)

### Цвета не синхронизируются

```bash
# Проверь, что pywal палитра генерируется:
ls -la ~/.cache/wal/colors.sh

# Запусти скрипт вручную с выводом ошибок:
bash ~/.config/waybar/sync-greetd-theme.sh
```

### Watcher не запускается

Проверь, что `inotify-tools` установлен:

```bash
which inotifywait
```
