# DECISIONS — ADR-журнал сборки Team OS v2

> Формат: контекст → варианты → выбор → причина → статус. Вето пользователя применимо задним числом к любому ADR.

## ADR-001: Рабочий репозиторий
- date: 2026-07-31 · status: accepted
- context: ТЗ указывает `~/Projects/llm_developer_setup`, фактически репозиторий настроек живёт в `~/development/llm_developer_setup`.
- choice: работать в фактическом репо; ветка `team-os` от `main`; всё в `team-os/`.
- consequences: пути в доках — от фактического корня.

## ADR-002: Хребет оркестрации — lead-сессия + субагенты; Teams только для T3
- context: варианты: (A) lead+субагенты, (B) Agent Teams всегда, (C) внешний оркестратор.
- choice: A как базовый режим; Teams — опциональный режим T3-спринтов (флаг уже включён у пользователя).
- причина: Teams ≈ ×7 токенов (подтверждено costs.md), in-process тиммейты не переживают `/resume`; субагенты дёшевы, фоновые по умолчанию, вложенность до 3.
- consequences: командные роли = `.claude/agents/*.md`; Teams-протокол описан в t3-скилле с актуальной механикой (implicit team, спавн `Agent{name}`, без TeamCreate/TeamDelete).

## ADR-003: Герметичность Gym — project-уровневая установка конфига
- context: Gym должен тестировать конфиг Team OS, не таща 45k-токенный конфиг пользователя. `CLAUDE_CONFIG_DIR` отвергнут экспериментом: свежий конфиг-дир теряет OAuth (кейчейн привязан к конфиг-диру).
- choice: прогоны `claude -p --setting-sources project --strict-mcp-config`; Team OS-конфиг копируется в фикстуру как project-конфиг (CLAUDE.md + `.claude/{agents,skills,hooks,rules,settings.json}`).
- причина: измерено: 45 409 → 7 468 свежих ток. на старт; auth и вложенный запуск работают.
- consequences: Gym тестирует те же файлы, что ставит install.sh (та же выкладка, другой уровень); в docs честно указано отличие «global vs project» уровня.

## ADR-004: Определение токен-бюджета
- context: базовая загрузка сессии ~20–30k input; «T0 ≤ 20k суммарно» невозможно, если считать кэш-читки.
- choice: `budget_used = input_tokens + cache_creation + output_tokens` (cache_read бесплатен). Стартовые ориентиры ТЗ сохраняем, калибрует Gym.
- consequences: скрипты и check.sh считают бюджет по этой формуле из stream-json result.

## ADR-005: Ярусы моделей
- choice: lead-сессия — `opus` (или `opusplan`); architect/code-reviewer/security — `opus`; PM/UX/visual/implementer/QA/devops/researcher — `sonnet`; судья Gym и рутина — `haiku`; `fable` — вне ярусов (opt-in, жрёт usage credits).
- причина: §6.4 ТЗ + скан моделей (Sonnet 5 — дефолт и очень силён; Opus 5 low/medium effort сильны — субагентам снижаем effort вместо смены модели).
- consequences: `model:` алиасами во frontmatter; никаких пиновых ID.

## ADR-006: Автопилот — внешний wrapper, не Stop-hook-цикл
- context: варианты: (A) официальный ralph-loop плагин (Stop-hook), (B) свой Stop-hook, (C) внешний bash-цикл `claude -p` на итерацию.
- choice: C, с паттернами из A (fail-open state, promise-sentinel, max-iterations) и frankbria (4-слойный детект лимита, circuit breaker).
- причина: Stop-hook-цикл умирает вместе с сессией при крэше/лимите; внешний цикл переживает оба, даёт свежий контекст на итерацию (§5.4 ТЗ) и пишет телеметрию из stream-json.
- consequences: `scripts/autopilot`; ralph-loop не устанавливается (дубль мандата).

## ADR-007: Единая схема телеметрии
- choice: `team/metrics.jsonl`, поля: `ts, kind, task, tier, mode(autopilot|interactive|gym), model, turns, in_tok, out_tok, cache_read, cache_create, cost_usd, dur_s, outcome(ok|fail|halt|limit), session_id, note`.
- писатели: autopilot и gym — парс stream-json result; интерактив — SessionEnd-hook (best-effort). Читатели: `standup`, `efficiency-report`, ретро.
- consequences: скрипты уже написаны и оттестированы против этой схемы.

## ADR-008: Фильтрация шумных выводов — PostToolUse `updatedToolOutput`
- choice: один PostToolUse(Bash)-hook: для известных шумных раннеров (npm test/jest/vitest/pytest/xcodebuild/next build…) подменяет вывод выжимкой (хвост + FAIL/ERROR-строки + exit-статус); остальное не трогает.
- причина: официальный паттерн из costs.md; 80–99% экономии на болтливых раннерах.
- consequences: `home/hooks/test-output-filter.sh`; настоящий полный лог пишется в `team/artifacts/` самим протоколом верификации.

## ADR-009: Ручные команды — `disable-model-invocation: true`
- context: скан скиллов: с этим флагом описание вообще не грузится в контекст.
- choice: `/tier, /autonomy, /standup, /gym, /research-refresh` — manual-only (нулевой стартовый налог); авто-инвокабельными остаются только тир-плейбуки, verify, browser-loop, retro, decide.
- consequences: стартовый налог скиллов Team OS — только 5–6 коротких описаний.

## ADR-010: Набор MCP
- choice: user-scope: context7 (remote HTTP). Project-шаблон: chrome-devtools-mcp@1.6.0 (web); XcodeBuildMCP@2.7.0 (iOS, opt-in с фильтром workflow); playwright-mcp — только для кросс-браузерного E2E (закомментирован). GitHub MCP — SKIP (`gh` CLI).
- причина: вердикты RESEARCH §4; незаполненный `${VAR}` НЕ отключает сервер → у context7 ключ через `${CONTEXT7_API_KEY:-}` (аноним-режим без ключа), тяжёлые серверы — закомментированы, а не «пустые».

## ADR-011: Enforcement браузерного цикла — маркер + Stop-hook
- context: боль №2: агент бросает цикл правка→тест или тестирует несвежую сборку.
- choice: скилл `browser-loop` открывает маркер `team/artifacts/.browser-loop.json` (список обязательных доказательств: build-маркер, тест, консоль, скриншот); Stop-hook блокирует завершение хода (exit 2 + причина), пока маркер не закрыт скриптом, который проверяет наличие доказательств.
- причина: «нарушение цикла — блокер, не варнинг» (ТЗ §5.2); Stop-hook — единственный механизм жёсткой блокировки.
- consequences: fail-open при кривом маркере (урок ralph-loop): битый state удаляется, сессия не запирается навечно.

## ADR-012: Универсальность по машинам — capability-детект в рантайме
- context: конфиг используется на нескольких машинах; на машине сборки нет Xcode, на других — может быть (указание пользователя 31.07.2026: iOS-логику не вырезать, инструкции универсальные).
- choice: вся iOS-логика (роль-инструкции, rules, XcodeBuildMCP-шаблон, iOS golden-задача) — первоклассная часть конфига везде. Машино-зависимые вещи детектятся в рантайме: Gym-задачи объявляют `requires:` (xcodebuild, chrome, node…), runner помечает недоступное как SKIPPED (не FAIL и не удаление); `doctor` показывает, какие capability на этой машине отсутствуют и как доставить.
- consequences: один и тот же `team-os/` ставится на любую машину без правок; baseline Gym хранит список скипов конкретной машины.

## ADR-013: Двухслойный бэклог
- choice: оперативный слой — native Tasks (переживают resume, зависимости); стратегический — `team/BACKLOG.md`/`SPRINT.md`. Третьего трекера нет (§11 ТЗ).
- consequences: лид синхронизирует слои на границах фаз; `standup` читает файлы (Tasks недоступны скриптам — не документированы на диске).

## ADR-014: Языковая политика
- choice: промпты/конфиги/код — EN; `team-os/docs/` и общение — RU (§10 ТЗ). Состояние `team/` — EN (это конфиг для агентов), кроме свободного текста решений/журнала — как удобно пользователю.
