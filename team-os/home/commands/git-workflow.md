# Git Workflow — Управление git операциями

TASK: Выполнить git-операцию [$ARGUMENTS] чтобы зафиксировать/доставить изменения безопасно.

## Доступные операции

### `branch [name]` — Создать feature-ветку
```bash
git fetch origin
git checkout -b feature/[name] origin/main
git push -u origin feature/[name]
```
Типы веток: `feature/`, `fix/`, `refactor/`, `chore/`, `release/`, `experiment/`

### `commit` — Зафиксировать и запушить
1. `git status` — показать изменения
2. `git diff --staged` и `git diff` — что изменилось
3. Conventional Commit: `type(scope): описание`
4. `git add [конкретные файлы]`
5. `git commit`
6. `git push` — ОБЯЗАТЕЛЬНО!

### `merge [source] [target]` — Слить ветку
1. Тесты проходят
2. `git checkout [target]` && `git pull origin [target]`
3. `git merge --no-ff [source]`
4. Разрешить конфликты
5. `git push origin [target]`

### `status` — Текущее состояние
### `sync` — Синхронизация с main

## Правила
1. Никогда не работай в main
2. Conventional commits
3. Атомарные коммиты
4. Push после каждого коммита
5. Не коммить секреты
6. Конкретные файлы, НЕ `git add .`

Определи операцию и выполни.
