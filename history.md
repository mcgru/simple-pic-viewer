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
