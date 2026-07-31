# Team OS v2 — быстрый старт

Автономная «продуктовая команда» на Claude Code для соло-разработчика: маршрутизатор сложности, ролевые субагенты, жёсткая верификация, токен-экономика, телеметрия и собственный тестовый контур (Gym).

## Установка (одна команда)

```bash
bash team-os/install.sh
```

- Покажет план: что добавится, что заменится. Всё заменяемое уходит в таймстемп-бэкап `~/.claude/teamos-backups/<ts>/` — **ничего не теряется**.
- `--dry-run` — только план, без записи. `--yes` — без вопроса.
- Установка идемпотентна: повторный запуск ничего не ломает.

**Откат одной строкой** (путь печатается при установке):

```bash
cp -R ~/.claude/teamos-backups/<ts>/. ~/.claude/
```

После установки: перезапустить сессии Claude Code (или `/reload-skills`). Проверить здоровье:

```bash
bash team-os/scripts/doctor
```

## Новый проект

```bash
cp -R team-os/project-template/. ~/projects/my-app/
cd ~/projects/my-app && git init
claude
```

Первая сессия сама выполнит Init protocol из CLAUDE.md шаблона: определит стек, заполнит команды, обновит `team/PRODUCT.md`.

## Ежедневная работа

Просто ставь задачи в чат. Лид сам объявит тир (`[T0]…[T3]`) и соразмерный процесс.

| Команда | Что делает |
|---|---|
| `/standup` | Статус спринта — детерминированный скрипт, почти 0 токенов |
| `/tier T2 <задача>` | Принудительный тир |
| `/autonomy L0..L3` | Уровень вовлечения: пара → консультации → ворота (дефолт) → автопилот |
| `/decide <тема>` | Зафиксировать ADR; вето: «veto ADR-N» — команда перепланируется |
| `/gym smoke\|all` | Прогнать golden-задачи (реальные headless-прогоны!) |
| `/research-refresh` | Скан экосистемы (ежемесячно) |

## Ночной автопилот

```bash
cd ~/projects/my-app
caffeinate -i ~/.claude/teamos/bin/autopilot . --max-iterations 15
```

Свежий контекст на итерацию, состояние на диске, переживает 5-часовые окна Max (парсит «resets 3:45pm» и ждёт), стоп-файлы: `team/HALT` (блокер) и `team/.autopilot/done` (всё сделано). Необратимые действия (деплой, merge, force-push) в автопилоте железно запрещены хуком.

## Отчёты (без LLM, бесплатно)

```bash
~/.claude/teamos/bin/standup ~/projects/my-app
~/.claude/teamos/bin/efficiency-report ~/projects/my-app --days 7
```

## Дальше

- Устройство и ограничения: [ARCHITECTURE.md](ARCHITECTURE.md)
- Пошаговые сценарии: [PLAYBOOK.md](PLAYBOOK.md)
- Вердикты ресёрча: [RESEARCH.md](RESEARCH.md) · Журнал решений: [DECISIONS.md](DECISIONS.md)
