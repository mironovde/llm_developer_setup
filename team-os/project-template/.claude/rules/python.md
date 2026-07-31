---
paths: ["**/*.py"]
---

# Python rules

- Type hints on all public functions and methods.
- Tests with pytest; deterministic, no sleeps or real network in CI.
- Prefer `uv` (or venv) for environments and installs.
- `ruff` for lint and format — fix warnings, do not suppress them.
- No bare `except:` — catch specific exceptions, re-raise or log with context.
- SQL only via parameterized queries / ORM. Never f-string interpolation.
- Pydantic models or dataclasses as DTOs at system boundaries (API, DB, queues).
