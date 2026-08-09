---
name: threat-model
description: Use when designing new feature touching auth, payments, data access, file uploads, or external integrations. Produces STRIDE-based threat analysis with concrete mitigations. Invoke explicitly via `/threat-model <feature description>` or auto-invoke when user asks to design/build something security-sensitive.
---

# Threat Modeling Skill

Systematic STRIDE-based threat analysis для новой feature или архитектурного изменения. Цель — найти уязвимости до того как они попадут в код.

## When to invoke

- Новая фича с PII / payments / auth / authz
- Новый external integration (webhook, 3rd-party API)
- File upload / download функционал
- Admin interface или privileged operations
- LLM agent с tool use
- Encryption / key management

## Process (6 шагов)

### 1. Describe the feature
Напиши кратко:
- **Что** делает фича (2-3 предложения)
- **Actors**: кто её использует (анонимный user, authenticated user, admin, system, внешний сервис)
- **Data**: какие данные входят и выходят (класс: PUBLIC/INTERNAL/CONFIDENTIAL/SECRET — см. data-classification.md)
- **Trust boundaries**: где проходят границы доверия

### 2. Build Data Flow Diagram

Нарисуй (ASCII/mermaid) data flow:
```
[Actor] --(data: class)--> [Process] --(stored)--> [Data Store]
                                |
                                +---(external call)---> [External Service]
```

Отметь trust boundaries штрихованной линией.

### 3. Apply STRIDE per component

Для каждого элемента (process, data store, data flow, external entity) рассмотри:

| Категория | Вопрос | Пример уязвимости |
|-----------|--------|-------------------|
| **S**poofing | Может ли атакующий притвориться другим actor'ом? | Stolen session token, forged JWT, CSRF |
| **T**ampering | Может ли атакующий изменить данные in transit/at-rest? | MITM, DB injection, unsigned payloads |
| **R**epudiation | Может ли actor отрицать что сделал действие? | Нет audit log, мутабельные логи |
| **I**nformation disclosure | Утечка чувствительной инфы? | Verbose errors, logs с PII, timing attack |
| **D**enial of service | Можно ли вывести из строя? | Unbounded loop, amplification, exhaustion |
| **E**levation of privilege | Может ли user получить роль выше своей? | Mass assignment, IDOR, auth bypass |

### 4. Score threats (DREAD simplified)

Для каждой найденной угрозы:

| Параметр | Score 1-3 |
|----------|-----------|
| **Damage** | 1=low, 2=moderate, 3=critical (data loss, compliance violation, full compromise) |
| **Reproducibility** | 1=hard, 2=sometimes, 3=trivial (любой user может) |
| **Exploitability** | 1=needs skill, 2=medium, 3=script kiddie |
| **Affected users** | 1=few, 2=many, 3=all |
| **Discoverability** | 1=unknown, 2=discoverable, 3=public info |

Total score 5-15. Action по severity:
- **12-15**: CRITICAL — обязательно mitigate до ship
- **8-11**: HIGH — mitigate до ship
- **5-7**: MEDIUM — mitigate если low cost, иначе accept + document

### 5. Define mitigations

Для каждой угрозы CRITICAL/HIGH:
- **Control**: что конкретно защищает (library, pattern, config)
- **Where**: в каком слое (L1 prompt / L2 precommit / L3 CI / L4 runtime / L5 monitor)
- **Owner**: кто реализует
- **Test**: как верифицировать что mitigation работает

### 6. Document

Создай `docs/threat-models/<feature-name>.md`:

```markdown
# Threat Model: <Feature Name>

**Date**: 2026-MM-DD
**Reviewed by**: <author>

## Feature description
<2-3 предложения>

## Data Flow

<ASCII/mermaid diagram>

## Threats identified

### T1: <title>
- **Category**: Spoofing
- **Description**: <как атакуется>
- **DREAD**: D3+R2+E2+A3+D2 = 12 (CRITICAL)
- **Mitigation**: <конкретные меры>
- **Layers**: L1 prompt (REFUSE в CLAUDE.md), L3 CI (semgrep rule)
- **Test**: tests/security/t1-spoofing.test.ts
- **Status**: MITIGATED / ACCEPTED / IN-PROGRESS

### T2: ...

## Residual risk
<что осталось не mitigated и почему (cost/benefit rationale)>

## Sign-off
- [ ] Security review passed
- [ ] Mitigations implemented
- [ ] Tests passing
```

## Example output template

```
## Threats for "User avatar upload"

### T1: Upload of malicious file (XSS via SVG)
- Category: Information disclosure + Elevation (via stored XSS)
- DREAD: D3+R3+E3+A3+D3 = 15 (CRITICAL)
- Mitigation:
  - Whitelist MIME types (image/jpeg, image/png, image/webp — NOT image/svg+xml)
  - Re-verify MIME server-side using magic bytes (not just Content-Type header)
  - Randomize filename, store outside web root
  - Serve through /api/avatar/{id} with Content-Type from DB (not user-controlled)
  - CSP: `img-src 'self'`
- Layers: L2 (schema check), L3 (semgrep pattern), L4 (nginx MIME enforcement)
- Test: tests/security/avatar-svg-xss.test.ts

### T2: Path traversal in filename
- Category: Tampering
- DREAD: D2+R2+E2+A2+D1 = 9 (HIGH)
- Mitigation: randomize filename server-side, never use user-provided name for disk path
- Layers: L1 prompt
- Test: tests/security/avatar-path-traversal.test.ts

### T3: Storage exhaustion (uploaded 10GB files)
- Category: DoS
- DREAD: D2+R3+E3+A3+D3 = 14 (CRITICAL)
- Mitigation:
  - Size limit (1MB server-side + client-side hint)
  - Rate limit (1 upload / 10s per user)
  - Storage quota per user
- Layers: L3 (nginx client_max_body_size), L4 (app-level validation)
- Test: tests/security/avatar-size-limit.test.ts
```

## Integration with project

После threat model:
1. Сохрани файл в `docs/threat-models/`
2. Добавь упомянутые tests в suite
3. Обнови REFUSE в CLAUDE.md если найден новый общий pattern
4. Если есть CONFIDENTIAL/SECRET данные — обнови `docs/data-classification.md`
5. Для CRITICAL threats — добавь в runtime monitoring / alerting

## References

- `~/.claude/CLAUDE.md` → SECURITY section
- `~/.claude/SECURITY.md` → extended reference
- `llm_developer_setup/templates/security/data-classification-template.md`
- [OWASP Threat Modeling](https://owasp.org/www-community/Threat_Modeling)
- [Microsoft STRIDE](https://learn.microsoft.com/en-us/azure/security/develop/threat-modeling-tool-threats)
