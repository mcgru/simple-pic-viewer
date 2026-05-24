# История разработки Simple Pic Viewer

## 2026-05-23 — Версия через version.v + git tags

- Создан `version.v` с константой `app_version` (module main, коммитится в репозиторий)
- `main.v`: `--version` читает `${app_version}` из `version.v` вместо хардкода
- `bump-version.sh`: правит `version.v` вместо `main.v`, после обновления файлов делает
  `git commit -m "chore: bump version to X.Y.Z"` и `git tag -a "vX.Y.Z"`
- Docker-сборка использует закоммиченный `version.v` без изменений

## 2026-05-23 — Формат заголовка окна

- Формат заголовка: `   HOST: FOLDER -- NAME (i/N)` (с отступом 3 пробела)
- Откат: изображение снова по центру, без выравнивания влево

## 2026-05-23 — Makefile + calc-version.sh

- Создан `Makefile` с целями: build, docker, docker-static, bump, deb, commit
- По умолчанию (`make`) выводит список доступных целей
- `make bump` — автоматический расчёт версии через conventional commits
- `make bump X.Y.Z` — явное указание версии
- `calc-version.sh` — анализирует коммиты с последнего тэга (`feat:` → minor, `fix:`/прочее → patch)
- `make deb` — сборка .deb (предварительно собирает бинарник)
## 2026-05-23 — Заголовок окна: убран HOST, idx перенесён

- Формат: `   FOLDER (i/N) -- NAME` (без HOST, без иконки 📁)
- Индекс (i/N) теперь сразу после FOLDER, перед `--`
## 2026-05-23 — Клавиатурные шорткаты

- Копирование: C, С (кириллица), F5
- Перемещение: M, Ь (кириллица), F6
- Обновлён `--help`
## 2026-05-23 — .target.folders в директории с картинками

- `load_target_folders_at(dir)` — загрузка `.target.folders` из указанной директории
- main: при переданном CLI-аргументе сначала ищет `.target.folders` там, потом в CWD
## 2026-05-23 — Enter в диалоге копирования/перемещения

- `on_dialog_key`: добавлена обработка Enter — подтверждает выбор текущей строки
## 2026-05-23 — Относительные пути в .target.folders

- `load_target_folders_at`: относительные пути резолвятся относительно папки с .target.folders
- Фильтрация комментариев: `l.starts_with('#')` после `trim_space()` (эквивалент `^\s*#.*`)

## 2026-05-23 — Приоритетная цепочка .target.folders

- Низший приоритет: `~/.config/simple-pic-viewer/.target.folders`
- Выше: `.target.folders` в CWD
- Выше: `.target.folders` в промежуточных директориях на пути к start_dir
- Высший приоритет: `.target.folders` в start_dir
- Позлементное слияние: каждый следующий файл перезаписывает dir[0], dir[1] и т.д.

## 2026-05-23 — make install

- `make install`: копирует бинарник в `~/.local/bin` (или `/usr/local/bin` с sudo)
- Если `~/.local/bin` нет в PATH — подсказка с командой для `.bashrc`

## 2026-05-24 — Быстрые цифры 1-9 для копирования

- Цифры 1-9 в основном окне: копирование (хардлинк) в соответствующую папку без диалога
- Если цифра не назначена (больше чем папок) — открывается диалог выбора
- Обновлён `--help`
- `build.sh`: при ошибке сборки показывает `sudo apt install` строки из TLDR раздела howto.libs.md
- Создан `howto.libs.md` с описанием зависимостей для сборки и запуска

## 2026-05-24 — Версия в usage

- `--help` теперь первой строкой показывает версию приложения (как `--version`)

## 2026-05-24 — Префикс Version: в --help

- `--help` показывает `Version: simple-pic-viewer X.Y.Z` вместо `simple-pic-viewer X.Y.Z`

## 2026-05-24 — TGT_FLDR_N с правильным индексом

- `load_config()`: парсит число N из `TGT_FLDR_N` и ставит папку на позицию N-1 (а не в конец)
- Если N вне диапазона 1-9 — ошибка в терминал + GTK-диалог при запуске
- Добавлен глобал `config_errors []string` для сбора ошибок конфига

## 2026-05-24 — Shift+цифра: удаление файла из папки назначения

- `Shift+1..9` — удаление файла из соответствующей папки с проверкой по MD5
- `delete_from_folder()` в `fileops.v`: проверка существования, MD5, `os.rm()`
- Flash фона: зелёный (COPIED), красный (DELETED / ошибка) — 0.5 сек
- Заголовок окна: `COPIED filename` / `DELETED filename` на 2 сек
- `get_event_state()` — чтение модификаторов из GDK-события
- Обновлён `--help`

## 2026-05-24 — Пустые индексы + новый формат заголовка

- Если в `destination_dirs` пустая строка (пропущенный TGT_FLDR_N) — красная вспышка, `ERROR: no folder assigned to N`
- Заголовок при копировании: `COPIED to /path`
- Заголовок при удалении: `DELETED /abs/path/filename`
## 2026-05-24 — Delete dialog (D/В/F8) + починка Shift+digit

- Shift+digit не работал из-за смены keyval при зажатом Shift (3→# и т.д.)
- digit_idx(): маппинг shifted (US) и unshifted keyvals в 0-8
- D, В (кириллица), F8 — открывают диалог удаления с выбором папки
- show_delete_dialog(): аналог show_copy_dialog(), вызывает delete_from_folder()
- --help: добавлена строка D / В / F8

