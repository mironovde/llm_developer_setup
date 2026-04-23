# Security Templates

Шаблоны для L2 (pre-commit) и L3 (CI/CD) enforcement layers. Копируй в каждый новый проект.

Reference: `~/.claude/CLAUDE.md` → SECURITY → ENFORCEMENT LAYERS.

## Что здесь

| Файл | Назначение | Куда копировать |
|------|-----------|-----------------|
| `.pre-commit-config.yaml` | gitleaks + bandit + detect-private-key + hadolint + checkov | Корень проекта |
| `.github/workflows/security.yml` | SAST (Semgrep, CodeQL) + dep audit + Trivy + SBOM | `.github/workflows/` |
| `CVE-RUNBOOK.md` | Процедура ответа на CVE в зависимостях | `docs/security/` |
| `data-classification-template.md` | Шаблон классификации данных проекта | `docs/data-classification.md` |

## Quick setup для нового проекта

```bash
# 1. Pre-commit
cp templates/security/.pre-commit-config.yaml ~/my-project/
cd ~/my-project
pip install pre-commit
pre-commit install
pre-commit run --all-files   # baseline scan

# 2. CI
mkdir -p ~/my-project/.github/workflows
cp templates/security/.github/workflows/security.yml ~/my-project/.github/workflows/

# 3. Docs
mkdir -p ~/my-project/docs/security
cp templates/security/CVE-RUNBOOK.md ~/my-project/docs/security/
cp templates/security/data-classification-template.md ~/my-project/docs/data-classification.md

# 4. Fill in data classification (requires project knowledge)
$EDITOR ~/my-project/docs/data-classification.md

# 5. Verify
git add .pre-commit-config.yaml .github/ docs/
git commit -m "chore: add security enforcement baseline"
```

## Adjust per project

### .pre-commit-config.yaml
- Включить ESLint блок если проект JS/TS
- Убрать Bandit если проект не Python
- Добавить проектно-специфичные linters

### .github/workflows/security.yml
- Выбрать корректные CodeQL languages для matrix
- Настроить Semgrep rulesets под stack
- Добавить FOSSA_API_KEY secret для license compliance (optional)

### CVE-RUNBOOK.md
- Добавить on-call ротацию и контакты
- Указать security channel name

### data-classification.md
- Заполнить Per-Field таблицу исходя из реальной БД
- Отметить compliance требования (GDPR/CCPA/PCI/HIPAA)

## Запуск threat-model для новой фичи

```
/threat-model Добавляю upload аватаров пользователей
```

Продуцирует `docs/threat-models/<feature>.md` с STRIDE анализом и mitigations.
