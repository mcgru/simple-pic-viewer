# Simple Pic Viewer — установка и сборка

## Runtime dependencies (на системе пользователя)

Для запуска готового бинарника нужны GTK3 и его зависимости:

```bash
# Ubuntu / Debian
sudo apt install libgtk-3-0 libgdk-pixbuf-2.0-0

# Fedora
sudo dnf install gtk3 gdk-pixbuf2

# Arch
sudo pacman install gtk3 gdk-pixbuf2

# Alpine (если запуск вне контейнера)
sudo apk add gtk+3.0 gdk-pixbuf
```

Пакет `libgtk-3-0` сам тянет все необходимые зависимости (cairo, pango, glib, X11 и т.д.).

## Development dependencies (для сборки)

```bash
# Ubuntu / Debian
sudo apt install build-essential git libgtk-3-dev

# Fedora
sudo dnf install gcc git pkgconfig gtk3-devel

# Arch
sudo pacman install base-devel git gtk3
```

Также нужно установить **V compiler** — либо из исходников:

```bash
git clone --depth 1 https://github.com/vlang/v /opt/v
cd /opt/v && make
sudo ln -s /opt/v/v /usr/local/bin/v
```

либо готовый бинарник с [GitHub releases](https://github.com/vlang/v/releases).

## Сборка вручную

```bash
# динамическая
v -enable-globals \
  -cflags "$(pkg-config --cflags gtk+-3.0)" \
  -ldflags "$(pkg-config --libs gtk+-3.0)" \
  -o simple-pic-viewer .

# статическая (см. Dockerfile.ubuntu.static — требует сборки GTK из исходников)
```

## Docker-сборка (рекомендуемый способ)

```bash
# динамический бинарник на Ubuntu 24.04
docker build --network host -f Dockerfile.ubuntu -t simple-pic-viewer-builder .
docker run --rm --network host -v $(pwd):/app simple-pic-viewer-builder

# Alpine-образ (запуск в контейнере)
docker build --network host -f Dockerfile.static -t simple-pic-viewer .
docker run --rm --network host -e DISPLAY=$DISPLAY \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v $(pwd):/pics simple-pic-viewer /simple-pic-viewer /pics/tests/pics
```

## Сборка .deb пакета

```bash
./makedeb.sh
```
