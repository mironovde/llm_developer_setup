# Gym — тестовый контур Team OS

Система не считается настроенной, пока не прошла эти задачи; конфиг не меняется, пока изменение не прошло их же (против baseline, по pass-rate И токенам).

## Запуск

```bash
bash gym/run.sh smoke            # 001+003, быстрая проверка механики
bash gym/run.sh all              # все задачи (это реальные headless-прогоны — часы и токены!)
bash gym/run.sh 005 006          # выборочно
bash gym/run.sh all --baseline   # зафиксировать базлайн
bash gym/run.sh 003 --runs 3     # pass^k: все прогоны должны быть зелёными
```

Результаты: `results/<run-id>/summary.json` + по задаче `transcript.jsonl`, `check.log`, `grading.json`.

## Механика

- **Герметичность** (ADR-003): фикстура + конфиг Team OS на project-уровне; `--setting-sources project --settings gym-settings.json --strict-mcp-config`. Конфиг пользователя не грузится, auth сохраняется.
- **Два слоя оценки**: `check.sh` — детерминированные ворота (тесты, артефакты, дисциплина тира, бюджет); судья `haiku` + `--json-schema` — по `expectations.md`, каждое ожидание с цитатой-доказательством.
- **Бюджеты** (ADR-004/015): `input + cache_creation + output`; gym-бюджеты включают холодный конфиг-лоад (~28.5k) и потому выше интерактивных ориентиров.
- **Capability-скипы** (ADR-012): `requires` в meta.json (node/python3/chrome/xcodebuild — функциональные проверки); отсутствие на машине = SKIPPED, не провал.

## Задачи

| ID | Что проверяет |
|---|---|
| 001-t0-typo | T0: один проход, без команды/церемоний, бюджет |
| 002-t0-doc-fix | T0: docs-only фикс |
| 003-t1-js-bugfix | T1: repro→fix, тесты не тронуты, независимая верификация |
| 004-t1-py-bugfix | то же на Python/unittest |
| 005-trap-t0 | ловушка: выглядит T0, скрытая связность → эскалация с [escalate] в JOURNAL |
| 006-t2-feature-web | T2 веб: полный браузерный цикл с build-маркером, скриншотом, чистой консолью |
| 007-t2-refactor | T2: рефакторинг с сохранением API + ADR |
| 008-long-cycle | выживание длинного цикла: 8 последовательных шагов без бросания |
| 009-t1-security | auth-код: не копировать небезопасную «конвенцию», CSPRNG + хэш |
| 010-ios-sim | SwiftPM багфикс (skip без Xcode) |

## Как добавить задачу из реального провала

Ретро пишет кандидатов в `team/solutions/gym-candidates.md`. Оформи по образцу 001/003: `meta.json`, `prompt.md`, `fixture/` (в ПРЕД-фиксном состоянии), `check.sh` (см. правила о `set -e` в шапке 001), `expectations.md`. Проверь check.sh в обе стороны (на решённой копии PASS, на нерешённой FAIL) — и только потом в набор.
