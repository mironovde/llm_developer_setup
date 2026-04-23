<!-- GSD:project-start source:PROJECT.md -->
## Project

**MFT Trading — Multi-Factor Trading System**

Робототорговая система для Tbank Invest API, позволяющая реализовать полный цикл алготрейдинга — от сбора данных и обучения моделей до бэктестинга, paper/live торговли и мониторинга. Система поддерживает множество торговых методов (статистический арбитраж, ML-модели, трендовые стратегии) с автоматическим подбором наилучшего подхода на каждый инструмент. Целевая аудитория — начинающий алготрейдер, которому нужна подробная справка по каждому методу и прозрачная экономика сделки.

**Core Value:** **Стабильное, математически обоснованное принятие торговых решений** — каждая стратегия должна иметь доверительные интервалы, корректно рассчитанную экономику (с учётом комиссий, плеча, проскальзывания) и защиту от переобучения. Без качественной математики = нет сделки.

### Constraints

- **Tech stack**: Python 3.12+ — единый язык для ML и backend
- **API**: Tbank Invest API v2 — единственный брокер
- **Latency**: минуты-часы горизонт, задержка не критична (но без лишних)
- **Security**: API токен только через env vars, никогда в коде
- **Data**: Tbank как основной источник, возможно дополнение MOEX данными
- **Reliability**: Graceful degradation при обрыве соединения
<!-- GSD:project-end -->

<!-- GSD:stack-start source:research/STACK.md -->
## Technology Stack

## Recommended Stack
### Core Technologies
| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Python | 3.12 | Runtime | Stable, all ML/trading libs support it. 3.13 has free-threading but ecosystem not ready. 3.12 is the sweet spot for production. |
| uv | 0.11.x | Package/project manager | 10-100x faster than pip. Replaces pip, pip-tools, virtualenv. Standard for new Python projects in 2026. Written in Rust by Astral. |
| FastAPI | 0.128.x | API server + WebSocket hub | Native async, WebSocket support, Pydantic validation, SSE for dashboards. Best Python ASGI framework for real-time trading backends. |
| uvicorn | 0.42.x | ASGI server | Production-grade ASGI server. Pair with FastAPI. Supports HTTP/1.1 and WebSockets natively. |
| Pydantic | 2.12.x | Data validation & settings | Type-safe configs, API schemas, settings management. FastAPI's native validation layer. Use pydantic-settings for env vars. |
| DuckDB | 1.5.x | Primary data store + analytics | OLAP-optimized, 8-50x faster than SQLite for analytical queries. Columnar storage reads only needed columns. Zero-config, embedded, perfect for local trading system. Direct Pandas/Polars integration. |
| Dash (Plotly) | 4.0.x | Web UI dashboard | Callback-based architecture avoids Streamlit's full-script reruns. Real-time updates without hacks. Plotly charts are interactive by default. Production-grade for trading dashboards. |
### Broker API
| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| tinkoff-investments | 0.2.0b118 | Tbank Invest API client | Official Python gRPC client. Sync + async. Streaming market data (candles, orderbook, trades). **CRITICAL: Package is quarantined on PyPI as of Dec 2025.** Install from GitHub: `pip install git+https://github.com/RussianInvestments/invest-python.git` |
| grpcio | latest | gRPC runtime | Dependency of tinkoff-investments. AsyncIO-native gRPC with streaming support. |
### Machine Learning
| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| XGBoost | 3.2.x | Gradient boosting (primary) | Best for structured/tabular financial data. Feature importance built-in. GPU support. Most popular in quant finance for alpha generation. |
| LightGBM | 4.6.x | Gradient boosting (secondary) | Faster training than XGBoost on large datasets. Histogram-based. Better for high-cardinality features. Use alongside XGBoost for ensemble. |
| scikit-learn | 1.8.x | ML pipeline, preprocessing | TimeSeriesSplit, Pipeline, StandardScaler, feature selection. Foundation for all ML workflows. Purged cross-validation via custom splitters. |
| Numba | 0.64.x | JIT compilation | Accelerates custom indicators and vectorized backtesting loops. 10-100x speedup over pure Python for numerical code. |
### Data Processing
| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| pandas | 2.2.x | Primary DataFrame library | Time-series native (DatetimeIndex, resample, rolling). Universal compatibility with all trading/ML libs. Still the standard for financial data manipulation. |
| NumPy | 2.x | Numerical computing | Foundation for everything. Vectorized operations, matrix algebra. Required by every ML/stats library. |
| Polars | 1.x | High-performance data processing | Use for ETL/feature engineering pipelines where Pandas is slow (3-13x faster). Lazy evaluation. DuckDB has native Polars integration. Use selectively, not as Pandas replacement. |
### Technical Analysis & Feature Engineering
| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| TA-Lib | 0.6.8 | Technical indicators (core) | C-based, fastest indicator library. 150+ indicators. Pre-built macOS wheels (ARM64 + x86). RSI, MACD, Bollinger, ATR, etc. |
| pandas-ta | 0.2.45b | Technical indicators (supplementary) | Pure Python, 150+ indicators. Easier API than TA-Lib. Use for indicators not in TA-Lib. **Warning: may be archived by July 2026.** |
### Statistical Analysis & Volatility
| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| statsmodels | 0.14.6 | Statistical models | ARIMA, cointegration tests (Engle-Granger, Johansen), ADF test, OLS regression. Essential for pairs trading and mean reversion. |
| arch | 8.0.x | GARCH volatility models | GARCH(1,1), GJR-GARCH, EGARCH. Volatility forecasting for risk management and position sizing. The only serious GARCH library in Python. |
| scipy | 1.x | Statistical functions | Distributions, hypothesis tests, optimization. KS-test, t-test for strategy validation. |
### Portfolio Analytics & Risk
| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| QuantStats | 0.0.77 | Performance reporting | Sharpe, Sortino, max drawdown, Calmar ratio. Auto-generated tearsheets (HTML). Monte Carlo simulations. All-in-one performance analytics. |
| PyPortfolioOpt | 1.5.6 | Portfolio optimization | Mean-variance, Black-Litterman, HRP, risk parity. Use for multi-strategy capital allocation. |
| empyrical | latest | Risk metrics (fast) | 50x faster than QuantStats for rolling calculations. Use internally for real-time risk monitoring. QuantStats for reports. |
### Visualization
| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Plotly | 6.x | Interactive charts | Candlestick charts, heatmaps, 3D surfaces. Native Dash integration. Zoom, hover, crosshair. Best for financial visualization. |
| mplfinance | latest | Matplotlib finance charts | Quick candlestick/OHLC charts for backtesting output. Use for static analysis plots, not dashboards. |
### Development Tools
| Tool | Version | Purpose | Notes |
|------|---------|---------|-------|
| Ruff | 0.15.x | Linter + formatter | Replaces Flake8+Black+isort. 10-100x faster. One tool for all code quality. By Astral (same as uv). |
| pytest | latest | Testing | Test strategies, indicators, risk calculations. Use pytest-asyncio for async gRPC tests. |
| mypy | latest | Type checking | Strict mode. Catch type errors in trading logic before runtime. |
| pre-commit | latest | Git hooks | Run Ruff + mypy on every commit. |
## Installation
# Initialize project with uv
# Set Python version
# Core framework
# Broker API (install from GitHub due to PyPI quarantine)
# Data storage & processing
# Machine Learning
# Technical Analysis
# Statistical Analysis
# Portfolio Analytics
# Visualization & Dashboard
# Async & Real-time
# Dev dependencies
## Alternatives Considered
| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| DuckDB | SQLite | If you need OLTP (many small writes) instead of analytics. SQLite is better for simple key-value storage. Use DuckDB for all analytical queries on candle/trade data. |
| DuckDB | TimescaleDB/InfluxDB | If you need distributed time-series across multiple nodes. Overkill for single-node local system. Adds ops complexity (separate DB server). |
| Dash | Streamlit | If you want fastest possible prototype (hours, not days). Streamlit is simpler but reruns entire script on interaction -- bad for trading dashboards with live data. |
| Dash | Panel (HoloViz) | If you need deep Bokeh integration or already use HoloViz ecosystem. Panel is flexible but less popular, smaller community. |
| Dash | FastAPI + React/Vue SPA | If you need custom pixel-perfect UI. Much more development effort, but maximum flexibility. Consider for v2 if Dash becomes limiting. |
| pandas | Polars (full replacement) | Don't fully replace Pandas. Most financial libs (TA-Lib, QuantStats, XGBoost) expect Pandas input. Use Polars for ETL pipelines where perf matters, convert to Pandas at ML boundaries. |
| XGBoost | CatBoost | If dealing with many categorical features (instrument types, sectors). CatBoost handles categoricals natively without encoding. Consider for cross-instrument learning phase. |
| vectorbt (open-source) | Custom backtester | Build custom because: (1) vectorbt OSS hasn't been updated since 0.28.4, (2) VBT PRO is paid, (3) custom gives full control over commission model, slippage, MOEX-specific rules. Use vectorized NumPy/Numba patterns inspired by vectorbt's architecture. |
| Custom backtester | Backtrader | Only if you want event-driven backtesting and don't mind a library last actively developed in 2018. API is well-documented but codebase is stale. |
| uv | pip + venv | Never. uv is strictly better in 2026. Faster, handles lockfiles, replaces multiple tools. |
## What NOT to Use
| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Zipline / Zipline-reloaded | Designed for Python 3.5-3.6, Quantopian-era. Installation nightmares on modern Python. Unmaintained architecture. | Custom vectorized backtester |
| Backtrader (as primary engine) | Last major development ~2018. Event-driven architecture is slow for parameter optimization (thousands of runs). Undocumented internals. | Custom backtester with Numba acceleration |
| vectorbt open-source (0.28.4) | Abandoned in favor of paid VBT PRO. No updates since 2023. Will rot on Python 3.12+. | Custom vectorized backtester using same NumPy/Numba patterns |
| InfluxDB / TimescaleDB | Requires running separate database server. Massive overkill for single-user local system. DuckDB handles time-series analytics perfectly. | DuckDB (embedded, zero-config) |
| Streamlit (for production dashboard) | Full script rerun on every interaction. RAM grows linearly per connection. Poor for live-updating trading data. | Dash with Plotly |
| Flask / Django | Synchronous by default. No native WebSocket. FastAPI is strictly better for async trading backends. | FastAPI |
| pip + virtualenv | Slow dependency resolution. No lockfile. uv does everything better in 2026. | uv |
| Jupyter-only workflow | Fine for exploration, terrible for production trading system. Code must be in modules. | Use Jupyter for research notebooks only, not for production code |
| pandas-ta as sole indicator lib | May be archived by July 2026 (maintainer warning). Slower than TA-Lib. | TA-Lib as primary, pandas-ta as supplement |
## Stack Patterns by Variant
- Skip FastAPI/Dash, use Jupyter + Plotly for analysis
- DuckDB for data storage, custom vectorized backtester
- Focus: feature engineering pipeline + walk-forward validation
- FastAPI + WebSocket for order management
- Dash dashboard for monitoring
- Redis (optional) for pub/sub between strategy engine and execution engine
- Focus: graceful degradation, connection recovery, position tracking
- Add MLflow for experiment tracking
- Consider Optuna for hyperparameter optimization
- Polars for heavy feature engineering pipelines
- Focus: walk-forward validation, purged cross-validation
## Version Compatibility
| Package A | Compatible With | Notes |
|-----------|-----------------|-------|
| tinkoff-investments 0.2.0b118 | Python 3.9-3.12 | Does NOT support Python 3.13 yet. Pin to 3.12. |
| DuckDB 1.5.x | Python 3.10+ | Dropped Python 3.9. Min is 3.10. |
| scikit-learn 1.8.x | Python 3.11-3.14 | Dropped Python 3.10. Could conflict with tinkoff SDK on 3.10. |
| Numba 0.64.x | Python 3.10-3.14 | Dropped Python 3.9. |
| XGBoost 3.2.x | Python 3.10+ | Works with Python 3.12 perfectly. |
| **Consensus: Python 3.12** | All listed packages | 3.12 is the only version supported by ALL packages including tinkoff-investments. |
## Critical Warning: Tbank SDK Installation
## Sources
- [tinkoff-investments PyPI](https://pypi.org/project/tinkoff-investments/) -- version 0.2.0b118, quarantine status verified (HIGH confidence)
- [RussianInvestments/invest-python GitHub](https://github.com/RussianInvestments/invest-python) -- features, installation verified (HIGH confidence)
- [Tinkoff Invest Python SDK Docs](https://russianinvestments.github.io/invest-python/) -- official documentation (HIGH confidence)
- [DuckDB 1.5.0 PyPI](https://pypi.org/project/duckdb/) -- version verified (HIGH confidence)
- [DuckDB vs SQLite Comparison](https://www.analyticsvidhya.com/blog/2026/01/duckdb-vs-sqlite/) -- 8-50x OLAP performance advantage (MEDIUM confidence)
- [FastAPI 0.128.0 PyPI](https://pypi.org/project/fastapi/) -- version verified (HIGH confidence)
- [Dash 4.0.0 PyPI](https://pypi.org/project/dash/) -- version verified (HIGH confidence)
- [XGBoost 3.2.0 PyPI](https://pypi.org/project/xgboost/) -- version verified (HIGH confidence)
- [LightGBM 4.6.0 PyPI](https://pypi.org/project/lightgbm/) -- version verified (HIGH confidence)
- [scikit-learn 1.8.0 PyPI](https://pypi.org/project/scikit-learn/) -- version verified (HIGH confidence)
- [arch 8.0.0 PyPI](https://pypi.org/project/arch/) -- GARCH models, version verified (HIGH confidence)
- [statsmodels 0.14.6 PyPI](https://pypi.org/project/statsmodels/) -- version verified (HIGH confidence)
- [QuantStats 0.0.77 PyPI](https://pypi.org/project/quantstats/) -- version verified (HIGH confidence)
- [PyPortfolioOpt 1.5.6 PyPI](https://pypi.org/project/pyportfolioopt/) -- version verified (HIGH confidence)
- [TA-Lib 0.6.8 PyPI](https://pypi.org/project/TA-Lib/) -- version verified, macOS ARM64 wheels (HIGH confidence)
- [uv 0.11.x PyPI](https://pypi.org/project/uv/) -- version verified (HIGH confidence)
- [Ruff 0.15.x PyPI](https://pypi.org/project/ruff/) -- version verified (HIGH confidence)
- [Pydantic 2.12.5 PyPI](https://pypi.org/project/pydantic/) -- version verified (HIGH confidence)
- [Numba 0.64.0 PyPI](https://pypi.org/project/numba/) -- version verified (HIGH confidence)
- [Python Quant Trading Ecosystem Guide 2025](https://medium.com/@mahmoud.abdou2002/the-ultimate-python-quantitative-trading-ecosystem-2025-guide-074c480bce2e) -- ecosystem overview (MEDIUM confidence)
- [Backtesting Framework Comparison](https://autotradelab.com/blog/backtrader-vs-nautilusttrader-vs-vectorbt-vs-zipline-reloaded) -- framework comparison (MEDIUM confidence)
- [Streamlit vs Dash Comparison](https://www.squadbase.dev/en/blog/streamlit-vs-dash-in-2025-comparing-data-app-frameworks) -- dashboard framework comparison (MEDIUM confidence)
- [FastAPI WebSocket Patterns](https://medium.com/@connect.hashblock/10-fastapi-websocket-patterns-for-live-dashboards-3e36f3080510) -- real-time architecture patterns (MEDIUM confidence)
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

Conventions not yet established. Will populate as patterns emerge during development.
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

Architecture not yet mapped. Follow existing patterns found in the codebase.
<!-- GSD:architecture-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd:quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd:debug` for investigation and bug fixing
- `/gsd:execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->



<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run `/gsd:profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
