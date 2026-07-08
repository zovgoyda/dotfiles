# Синхронизация greetd/regreet с pywal темой

## Описание

Этот набор скриптов обеспечивает автоматическую синхронизацию экрана входа (greetd + regreet) с текущей pywal палитрой и обоями.

### Что синхронизируется:
- ✅ Обои экрана входа
- ✅ Цвета (из pywal палитры)
- ✅ Темная тема GTK

## Быстрый старт

### 1. Убедись, что установлены зависимости

```bash
bash deps.sh
```

### 2. Установи конфигурации

```bash
bash install.sh
```

### 3. Синхронизация работает через `theme.sh`

При каждой смене тем через `~/.config/waybar/theme.sh` greetd/regreet автоматически обновляется.

### 4. (Опционально) Включи мониторинг в реальном времени

```bash
# Запусти watcher в фоне
bash ~/.config/waybar/sync-greetd-watcher.sh &

# Или добавь в свой конфиг WM (например niri):
# exec-once = ["~/.config/waybar/sync-greetd-watcher.sh"]
```

## Как это работает

### sync-greetd-theme.sh

Основной скрипт, который:
1. Читает текущие цвета из `~/.cache/wal/colors.sh`
2. Копирует обои в `/etc/greetd/theme/wall.png`
3. Генерирует CSS с правильной цветопередачей
4. Обновляет конфиг regreet

**Вызывается автоматически из:**
- `~/.config/waybar/theme.sh` при смене темы

### sync-greetd-watcher.sh

Фоновый скрипт для мониторинга в реальном времени:
1. Следит за `~/.cache/wal/colors.sh`
2. Следит за `~/.cache/current_wallpaper`
3. Автоматически запускает синхронизацию при изменении

**Требует:** `inotify-tools`

## Интеграция с различными init systems

### systemd

```bash
# Статус
sudo systemctl status greetd

# Перезагрузка
sudo systemctl restart greetd

# Логи
journalctl -u greetd -f
```

### dinit (рекомендуется для Artix)

```bash
# Статус
sudo dinitctl status greetd

# Перезагрузка
sudo dinitctl restart greetd

# Логи
sudo tail -f /var/log/dinit/greetd.log
```

### runit

```bash
# Статус
sudo sv status greetd

# Перезагрузка
sudo sv restart greetd

# Логи
sudo tail -f /var/log/runit/greetd/current
```

## Трубблшутинг

### Цвета не применяются

```bash
# 1. Проверь, что pywal создал палитру
cat ~/.cache/wal/colors.sh

# 2. Запусти синхронизацию вручную
bash ~/.config/waybar/sync-greetd-theme.sh

# 3. Проверь сгенерированный CSS
cat /etc/greetd/theme/regreet.css

# 4. Перезагрузи greetd
sudo systemctl restart greetd  # systemd
sudo dinitctl restart greetd   # dinit
```

### CSS синтаксис ошибок

```bash
# Проверь правильность RGB конвертации
# В файле должны быть цифры, а не переменные
grep rgba /etc/greetd/theme/regreet.css

# Пример правильного вывода:
# background-color: rgba(11, 14, 25, 0.85) !important;
```

### Watcher не запускается

```bash
# Проверь inotify-tools
which inotifywait

# Запусти с отладкой
bash -x ~/.config/waybar/sync-greetd-watcher.sh
```

## Дополнительная настройка

### Изменить шрифт в greetd

```bash
# Отредактируй sync-greetd-theme.sh
sed -i 's/JetBrains Mono 12/Твой Шрифт 14/g' ~/.config/waybar/sync-greetd-theme.sh
```

### Изменить прозрачность фона

```bash
# В sync-greetd-theme.sh найди строку:
# background-color: rgba($BG_RGB, 0.85)
# Измени 0.85 на значение от 0 (прозрачный) до 1 (непрозрачный)
```

### Использовать светлую тему

```bash
# В sync-greetd-theme.sh измени:
gtk_theme_name = "Adwaita-dark"
# На:
gtk_theme_name = "Adwaita"
```

## Файлы конфигурации

- `/etc/greetd/config.toml` — основной конфиг greetd
- `/etc/greetd/regreet.toml` — конфиг regreet (генерируется скриптом)
- `/etc/greetd/theme/regreet.css` — CSS для оформления (генерируется скриптом)
- `/etc/greetd/theme/wall.png` — обои (генерируется скриптом)

## Безопасность

Правам на файлы:
- `regreet.toml` → `greeter:$(id -g)` с правами `664`
- `/etc/greetd/theme` → `greeter:greeter` с правами `755`
- Это позволяет скриптам в твоей сессии обновлять файлы

## Вопросы?

Смотри комментарии в скриптах:
- `~/.config/waybar/sync-greetd-theme.sh`
- `~/.config/waybar/sync-greetd-watcher.sh`
