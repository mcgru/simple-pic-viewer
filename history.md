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
