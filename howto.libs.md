# Зависимости для сборки и запуска Simple Pic Viewer

## TLDR

#### Установка Vlang
```
git clone --depth 1 https://github.com/vlang/v /opt/v
cd /opt/v && make
ln -s /opt/v/v /usr/local/bin/v
```

#### Установка библиотек для build
```
sudo apt install  build-essential pkg-config git libgtk-3-dev  fakeroot dpkg-dev
```

#### Установка библиотек для runtime
```
sudo apt install  libgtk-3-0 libgdk-pixbuf-2.0-0   gdk-pixbuf-tiff
```

## 1. Сборка из исходников (build-time)

### Язык V

Компилятор V не входит в стандартные репозитории Debian/Ubuntu. Устанавливается из исходников:

```bash
git clone --depth 1 https://github.com/vlang/v /opt/v
cd /opt/v && make
ln -s /opt/v/v /usr/local/bin/v
```

### Системные пакеты

Сердцевина — `libgtk-3-dev`. Он тянет все необходимые зависимости транзитивно:

```bash
sudo apt install build-essential pkg-config git libgtk-3-dev
```

| Пакет | Зачем |
|---|---|
| `build-essential` | gcc, make (V компилирует C код через gcc) |
| `pkg-config` | `pkg-config --cflags --libs gtk+-3.0` для флагов линковки |
| `git` | клонировать V compiler, для `make bump` |
| `libgtk-3-dev` | GTK3 заголовки и .so symlinks |

`libgtk-3-dev` тянет за собой (автоматически):
- `libglib2.0-dev` — GObject, GMainLoop, GString
- `libgdk-pixbuf-2.0-dev` — загрузка PNG/JPEG/TIFF
- `libpango1.0-dev` — рендеринг текста
- `libcairo2-dev` — 2D графика
- `libatk1.0-dev` — accessibility toolkit
- `libgdk-pixbuf-xlib-2.0-dev` — X11 интероп для gdk-pixbuf

Также понадобятся для `make deb`:
- `fakeroot` — `fakeroot dpkg-deb --build`
- `dpkg-dev` — содержит `dpkg-deb`

### Итого: команда для установки всего для сборки

```bash
sudo apt install build-essential pkg-config git libgtk-3-dev fakeroot dpkg-dev
```

Плюс ручная установка V compiler (однократно).

## 2. Запуск (runtime)

### Минимальные runtime-зависимости

Динамически слинкованный бинарник линкуется к `.so` библиотекам. Нужны именно runtime-пакеты (без `-dev`):

| Пакет | Зачем |
|---|---|
| `libgtk-3-0` (>= 3.24) | GTK3 core — окна, виджеты, событийный цикл |
| `libgdk-pixbuf-2.0-0` (>= 2.42) | загрузка изображений через pixbuf loaders |
| `gdk-pixbuf-tiff` (опционально) | если нужна поддержка TIFF через gdk-pixbuf loader |

`libgtk-3-0` тянет транзитивно:
- `libglib2.0-0` — GObject, event loop
- `libpango-1.0-0` — отрисовка текста
- `libcairo2` — 2D рендеринг
- `libatk1.0-0` — доступность
- `libgdk-pixbuf-2.0-0` — уже явно указано
- `libx11-6`, `libxdamage1`, `libxcomposite1`, `libxrandr2` — X11/XWayland

### Проверка после сборки

```bash
ldd simple-pic-viewer
# покажет все .so на которые линкуется бинарник
# типичный вывод (сокращённо):
#   linux-vdso.so.1
#   libgtk-3.so.0
#   libgdk-3.so.0
#   libgdk_pixbuf-2.0.so.0
#   libpango-1.0.so.0
#   libcairo.so.2
#   libglib-2.0.so.0
#   libgobject-2.0.so.0
#   libX11.so.6
#   ...
```

### Итого: что ставить на целевой машине для запуска

```bash
sudo apt install libgtk-3-0 libgdk-pixbuf-2.0-0
```

Для TIFF:
```bash
sudo apt install gdk-pixbuf-tiff
```
