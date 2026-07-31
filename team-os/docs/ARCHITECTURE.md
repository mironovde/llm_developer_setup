# ARCHITECTURE — устройство Team OS v2

> Проверено против Claude Code v2.1.207 и официальных доков на 31.07.2026. Все ключевые решения — в [DECISIONS.md](DECISIONS.md), первоисточники — в [RESEARCH.md](RESEARCH.md).

## 1. Слои системы

```
~/.claude/                        ← ставится install.sh из team-os/home/
  CLAUDE.md                       ← лид-оркестратор: тир-роутер, контракты, законы (~110 строк)
  settings.json                   ← права (allow/ask/deny), хуки, statusline
  statusline.sh                   ← модель·effort·ctx%·$·ветка (+ кэш для метрик сессии)
  agents/  (10 ролей)             ← pm, ux, visual, architect, implementer, qa, reviewer, security, devops, researcher
  skills/  (12)                   ← t1/t2/t3, verify, browser-loop, retro, decide + ручные /tier /autonomy /standup /gym /research-refresh
  hooks/   (5 × teamos-*)         ← фильтр шумных выводов, страж браузерного цикла, ворота автопилота, метрики сессий, helper цикла
  teamos/bin/                     ← autopilot, standup, efficiency-report, doctor, teamos-lib.sh
<проект>/
  CLAUDE.md, .claude/rules/*      ← стек-специфика (path-scoped: webapp/python/ios)
  .mcp.json (+ mcp-snippets/)     ← пиненые MCP по нуждам проекта
  team/                           ← ВСЁ состояние команды (см. §4)
```

## 2. Маршрутизатор сложности (горячий путь)

Таблица тиров живёт в глобальном CLAUDE.md (лид триажит мгновенно, сам). Детали процессов — в скиллах `t1/t2/t3` с progressive disclosure: описание ~30 токенов, тело грузится только при вызове. T0 не грузит ничего.

- Сомнение → нижний тир; эскалация дёшева (одна строка в JOURNAL + перепланирование).
- Бюджеты: T0 ≤ 20k, T1 ≤ 150k (формула ADR-004: `input + cache_creation + output`, кэш-читки бесплатны); T2/T3 — в SPRINT.md. Превышение → стоп + `[budget-alert]`.
- `/tier` — обязывающий оверрайд (пол, не потолок: эскалация вверх разрешена).

## 3. Роли и модели

| Ярус | Кто | Модель |
|---|---|---|
| Оркестрация/критика | лид (сессия), architect, code-reviewer, security-auditor | `opus` |
| Исполнение | pm, ux-designer, visual-designer, implementer, qa, devops, researcher | `sonnet` |
| Рутина | судья Gym, статусные мелочи | `haiku` |

`fable` — только по явной просьбе (ест usage credits). Ролям с критикой запрещена запись (`disallowedTools: Edit, Write`) — недоверие по построению. Контракт двусторонний: бриф `goal/paths/done-criterion/budget/do-NOT` → отчёт ≤15 строк `status/changed/proofs/risks/next`. Тяжёлое — в `team/artifacts/`, в контекст — путь + ≤3 строки.

## 4. Состояние на диске (§4 = «команда живёт вне чата»)

`team/`: PRODUCT (продуктовая правда) · CONSTITUTION (yaml-блок: autonomy, бюджеты + прайм-правила) · BACKLOG (стратегический слой, score=(V×R)/E) · SPRINT (итерация: задачи, статусы, **proof-колонка**) · DECISIONS (ADR, вето задним числом) · JOURNAL (append-only однострочные события) · metrics.jsonl · specs/ · solutions/ (уроки compound-шага) · artifacts/.

Точка возобновления любой сессии: SPRINT.md + хвост JOURNAL. Оперативные микро-задачи — в native Tasks (переживают resume); третьего трекера нет (ADR-013).

## 5. Верификация — «недоверие по построению»

1. Скилл `verify`: Iron Law (адаптация obra/superpowers) — заявление без свежего прогона в этом же ходу запрещено; таблица «заявление → единственно допустимое доказательство».
2. QA/review/security — всегда свежий контекст; самоотчёт исполнителя доказательством не является.
3. Браузерный цикл (боль №2): скилл `browser-loop` + маркер `team/artifacts/.browser-loop.json` + **Stop-hook `teamos-loop-guard.sh`** — завершить ход с открытым циклом нельзя (exit 2), пока не записаны 4 доказательства: build-маркер свежей сборки, полный проход теста, чистая консоль/сеть, скриншот. Fail-open: битый/застарелый маркер и 5 блокировок подряд снимают блок (урок ralph-loop — никогда не запирать сессию навечно).
4. `/code-review`, `/verify` платформа больше НЕ автозапускает (v2.1.215) — тир-плейбуки зовут их явно.

## 6. Токен-экономика (механизмы §6 ТЗ)

| Механизм | Реализация | Эффект |
|---|---|---|
| Контракты | брифы/отчёты фиксированного формата в CLAUDE.md + каждом агенте | лид не читает сырые диффы |
| Artifact-over-context | правило №9 CONSTITUTION + инструкции ролей | тяжёлое на диске |
| Hook-фильтр | `teamos-test-output-filter.sh` (PostToolUse, `updatedToolOutput`) — известные шумные раннеры → выжимка (signal-строки+хвост) | 80–99 % на болтливых выводах |
| Тощий старт | CLAUDE.md ~110 строк; 5 ручных скиллов с `disable-model-invocation` (описание вообще не грузится); rules path-scoped | замерено: старый конфиг 45.4k ток./старт, Team OS-профиль в Gym ≈ 26.6k полного инпута (7.5k свежих) |
| Телеметрия | `metrics.jsonl` (схема ADR-007): gym/autopilot пишут из stream-json result; интерактив — SessionEnd-hook через кэш statusline | сырьё для ретро и калибровки |
| Кэш-дисциплина | правило в CLAUDE.md: без пауз в итерации, батчить изменения конфига | меньше cache_create |
| Бюджет-алерт | правило роутера + Gym-гейт бюджета | нет молчаливого дожига |

## 7. Автопилот (ночной режим)

Внешний wrapper `scripts/autopilot` (ADR-006), не Stop-hook-цикл: переживает крэши и лимиты.

- Итерация = свежий `claude -p` (stream-json) с фиксированным промптом «одна единица работы из состояния на диске»; `TEAMOS_AUTOPILOT=1` активирует PreToolUse-ворота (deny деплоя/merge/force-push с формулировкой «поставь в очередь на пользовательские ворота»).
- Детект лимита — 4 слоя (паттерн frankbria): структурный `rate_limit_event status:rejected` → текстовые с фильтрацией эха tool_result → парсинг «resets 3:45pm» (python, +2 мин запас; фолбэк 60 мин; потолок 6 ч) → sleep → продолжение. Лимит не тратит счётчик итераций.
- Стопы: `team/HALT` (агент упёрся в user-only решение) · `team/.autopilot/done` (бэклог закрыт) · лимит итераций · circuit breaker (3 итерации без изменений git-состояния) · 2 итерации подряд с permission denials.
- Без `bypassPermissions` (§8 ТЗ): только allowlists + acceptEdits. Встроенные ретраи транзиентов (`CLAUDE_CODE_RETRY_WATCHDOG`) не дублируются.

## 8. Gym (самокалибровка)

- Задачи `gym/tasks/NNN-name/`: `meta.json` (tier, budget, timeout, `requires` — capability-детект в рантайме, ADR-012), `prompt.md`, `fixture/`, `check.sh` (детерминированный гейт: exit-code), `expectations.md` (судья).
- Герметичность (ADR-003): прогон в свежем워크спейсе с Team OS-конфигом на **project-уровне** + `--setting-sources project --settings gym-settings.json --strict-mcp-config`. Конфиг пользователя не грузится; auth сохраняется. `CLAUDE_CONFIG_DIR` отвергнут экспериментом (теряет OAuth).
- Два слоя оценки: `check.sh` — ворота; судья (`haiku` + `--json-schema`, схема skill-creator) — объяснение с обязательными цитатами-доказательствами. «Агент сказал, что прошло» — не доказательство.
- Железное правило: любое изменение конфига принимается только при непроигрыше против `results/baseline.json` по pass-rate И токенам. `pass_k` — для критичных задач (все прогоны зелёные).
- Набор растёт из реальных провалов (ретро → `gym-candidates.md` → новая задача).

## 9. Безопасность автономии (§8 ТЗ)

- Летальная трифекта: у агента максимум 2 из {приватные данные, недоверенный контент, канал наружу}; researcher не видит секретов, deny `WebSearch/WebFetch` в Gym-профиле.
- Секреты: deny-правила на `.env`, `*.pem`, `*.key`, `~/.ssh`, `~/.aws`; исключение — `.env.test` (штатные тест-креды нашего же продукта, боль №3).
- Необратимое: ask-правила (интерактив) + hook-deny (автопилот). MCP: официальные издатели, версии запинены, снипеты вместо «пустых ${VAR}» (незаполненная переменная сервер НЕ отключает — проверено).
- Вывод MCP/веба — недоверенный ввод; правило в CLAUDE.md и роли researcher.

## 10. Честные ограничения платформы

1. **Метрики интерактивных сессий — best-effort**: SessionEnd-hook берёт usage из кэша statusline (statusline может не успеть обновиться в самом конце). Точные цифры — только у headless-прогонов (gym/autopilot). `/usage` скриптам недоступен.
2. **Teams не переживают /resume** и стоят ≈×7 — потому opt-in только для T3 (ADR-002); TeamCreate/TeamDelete больше не существуют — вся старая документация про них устарела.
3. **`.mcp.json` на новой машине требует ручного одобрения** (trust) — первый запуск проекта спросит.
4. **Поле `rate_limits` в statusline** — структура зависит от версии CLI; statusline пробует несколько имён и молча пропускает при отсутствии.
5. **`--max-turns` в CLI v2.1.207 отсутствует** — лимиты итераций только wrapper'ом; per-агент `maxTurns` во frontmatter работает.
6. **Gym тестирует конфиг на project-уровне**, а install ставит его на user-уровень: содержимое то же, но user-уровневые нюансы (например, precedence с настройками проекта) Gym не покрывает.
7. **Хуки It's bash**: на экзотических локалях/окружениях возможны сюрпризы; все хуки fail-open и «тихие» (ошибка хука не валит работу).
8. Автопилот не отвечает на permission-prompt'ы (headless): недостающее право = запись в HALT после 2 итераций, а не зависание.
