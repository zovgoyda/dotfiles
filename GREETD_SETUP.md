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

### 4. В��лючи systemd сервис (опционально, для автозапуска):

```bash
mkdir -p ~/.config/systemd/user
cp .config/systemd/user/greetd-theme-sync.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now greetd-theme-sync.service

# Проверить статус:
systemctl --user status greetd-theme-sync.service
```

### 5. Запустить синхронизацию вручную:

```bash
bash ~/.config/waybar/sync-greetd-theme.sh
```

## Как это работает

1. **sync-greetd-theme.sh** — основной скрипт, который:
   - Читает палитру из `~/.cache/wal/colors.sh`
   - Копирует текущие обои в `/etc/greetd/theme/wall.png`
   - Генерирует CSS с правильными цветами
   - Обновляет конфиг regreet с темной темой

2. **sync-greetd-watcher.sh** — следит за файлами (`colors.sh` и `current_wallpaper`) и автоматически запускает синхронизацию при изменении

3. **greetd-theme-sync.service** — systemd сервис для автозапуска watcher при загрузке системы

## Троблшутинг

### Systemd сервис не запускается

```bash
# Проверить логи:
journalctl --user -u greetd-theme-sync.service -f
```

### CSS не применяется

Убедись, что:
- `/etc/greetd/theme/regreet.css` существует и имеет правильные права
- `gtk_theme_name = "Adwaita-dark"` в `/etc/greetd/regreet.toml`
- ReGreet перезагружен (перезагрузись или запусти `sudo systemctl restart greetd`)

### Цвета не синхронизируются

```bash
# Проверить, что pywal палитра генерируется:
ls -la ~/.cache/wal/colors.sh

# Запустить скрипт вручную с выводом ошибок:
bash ~/.config/waybar/sync-greetd-theme.sh
```

## Использование

Скрипты уже вызываются из `waybar/theme.sh`, так что синхронизация происходит при смене темы через waybar.

Кроме того, если включен systemd сервис, синхронизация происходит в реальном времени при изменении pywal палитры.
