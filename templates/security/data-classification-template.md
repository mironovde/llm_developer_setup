# Data Classification — {{PROJECT_NAME}}

> Этот файл описывает **какие данные** проект обрабатывает, **уровень чувствительности**, и **требования к защите** per класс. Обновляется при добавлении новых типов данных.

## Классы

### 🟢 PUBLIC
Данные, которые открыты публично и нет риска при утечке.

| Примеры |
|---------|
| Product catalog (цены, описания, публичные images) |
| Public blog posts, docs |
| Marketing content |
| Open-source code |

**Защита**: стандартная; encryption at-rest опционально.

---

### 🟡 INTERNAL
Данные для внутренних процессов, не для публики, но не критичные если leaked.

| Примеры |
|---------|
| Agreggated analytics (без PII) |
| Internal tooling configs (без secrets) |
| Team wiki, internal docs |
| Business metrics (revenue агрегаты) |

**Защита**:
- Access restricted к авторизованным сотрудникам
- Encryption in transit (TLS)
- Encryption at-rest опционально
- Retention: 2 года default

---

### 🟠 CONFIDENTIAL
Чувствительные данные: PII, business-sensitive, operational secrets.

| Примеры |
|---------|
| User email, name, phone |
| User activity logs (с user_id) |
| Billing addresses |
| Internal financial data |
| API keys 3rd-party сервисов |
| Non-production secrets |

**Защита**:
- Encryption at-rest **ОБЯЗАТЕЛЬНО** (field-level или table-level)
- Encryption in transit (TLS ≥1.2)
- Access control: per-user authorization (IDOR prevention)
- Audit logging на read/write
- Retention: минимум необходимо для функции (GDPR data minimization)
- Right to deletion (GDPR Art. 17)
- Backup encryption
- Рассматривать pseudonymization (hash email в логах) где возможно

---

### 🔴 SECRET
Критичные данные, утечка = серьёзный ущерб (финансовый, правовой, репутационный).

| Примеры |
|---------|
| Passwords (hashed) |
| Session tokens, JWT secrets |
| Payment card data (PCI-DSS scope) |
| SSN, паспорт, водительские права |
| Медицинские данные (HIPAA scope) |
| Production database credentials |
| Private keys (signing, encryption) |
| OAuth client secrets |

**Защита** (всё CONFIDENTIAL plus):
- Field-level encryption **ОБЯЗАТЕЛЬНО** с rotation
- **Pan data (card numbers)**: PCI-DSS compliance — токенизация через Stripe/Adyen, НЕ хранить raw card numbers
- **Passwords**: только хэши (argon2id/bcrypt), НЕ encrypt/decrypt
- MFA обязательно для access
- Audit logging: все accesses (even read) с alert на unusual patterns
- Access через secret manager (Vault, AWS SM, Doppler), НЕ env vars напрямую
- Retention: строго по законам (GDPR: soon as not needed; HIPAA: 6 years; PCI: 12 months)
- Backup: encrypted с separate key
- Geo-restrictions (GDPR data residency)
- **НИКОГДА в логах** — даже masked частично

---

## Data Flow (обновляется при изменениях)

```
User → [Frontend (🟢 PUBLIC routing)] 
     → [Backend API (🟠 receives CONFIDENTIAL)]
     → [DB (🟠 stores CONFIDENTIAL, 🔴 stores SECRET encrypted)]
     → [3rd-party (e.g., Stripe: 🔴 PAN — только token)]
```

## Per-Field Classification

| Field | Class | Storage | Encryption | Retention |
|-------|-------|---------|-----------|-----------|
| `user.id` | PUBLIC | DB | — | forever |
| `user.email` | CONFIDENTIAL | DB | at-rest | until deletion request |
| `user.password_hash` | SECRET | DB | hashed, not encrypted | until deletion request |
| `user.phone` | CONFIDENTIAL | DB | at-rest field-level | until deletion request |
| `user.ssn` / `user.passport` | SECRET | DB | field-level + rotation | legal minimum |
| `payment.card_token` | CONFIDENTIAL | DB | at-rest | until deletion |
| `payment.card_pan` | SECRET | **НЕ ХРАНИМ** — через Stripe | — | — |
| `session.token` | SECRET | Redis (TTL) + httpOnly cookie | at-rest | session TTL |
| `audit_log.event` | CONFIDENTIAL | Log store | at-rest | 90 days |

## Compliance

Проект подпадает под:
- [ ] **GDPR** (EU users) — consent, export, deletion, 72h breach notification
- [ ] **CCPA** (California users) — disclosure, opt-out, deletion
- [ ] **PCI-DSS** (обработка card data) — tokenization обязательно
- [ ] **HIPAA** (медицинские данные US) — BAA с vendors, encryption, audit logs
- [ ] **SOC 2** (B2B customers) — evidence collection
- [ ] Другое: ____

## Incident Response для data breach

1. Contain (stop the leak)
2. Assess (what was exposed, how many users)
3. Notify:
   - **GDPR**: DPO и supervisory authority в 72h если PII leaked
   - **CCPA**: CA Attorney General if >500 CA residents
   - **HIPAA**: HHS и users в 60 days
   - **PCI**: card brand и acquirer в 72h
4. Document (timeline, affected records, remediation)
5. Post-mortem + user communication
