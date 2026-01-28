# LLM Developer Setup - ML Engineer Specialization

## Specialization: Machine Learning Engineering (PyTorch, TensorFlow, MLOps)

This configuration is optimized for ML engineering including model development, data pipelines, experiment tracking, and production deployment.

## Critical Workflow: Always Start Here

**MANDATORY FIRST STEP**: Before ANY task execution, you MUST:
1. Read this file completely
2. Invoke `/skill-router` to determine relevant skills and MCPs
3. Decompose the task using `/task-decomposition`
4. Only then proceed with implementation

## Core Principles

### Context Efficiency
- Load only relevant skills for current task
- Unload context that's no longer needed
- Use skill router to optimize context usage
- Keep working memory focused on active task

### Git Discipline
- Create feature branches for any non-trivial work
- Make atomic, well-documented commits
- Update PROJECT_STATUS.md after each milestone
- Merge to main only after testing and review

### Quality Standards
- Every model must be validated
- Experiments must be reproducible
- Data quality must be monitored
- Product usability is paramount (ML products)

## Available Skills

### Core Skills (All Specializations)
| Skill | Command | Purpose |
|-------|---------|---------|
| Skill Router | `/skill-router` | **MANDATORY** - Determines which skills to load |
| Task Decomposition | `/task-decomposition` | Breaks tasks into atomic subtasks |
| Product Manager | `/pm-challenge` | Challenges product decisions |
| Financial Analyst | `/financial-review` | Reviews financial aspects |
| Git Workflow | `/git-workflow` | Manages git operations |
| Testing Challenger | `/test-challenge` | Tests and challenges results |
| Context Manager | `/context-manage` | Optimizes context usage |
| Progress Tracker | `/progress-update` | Updates project status |

### ML-Specific Skills
| Skill | Command | Purpose |
|-------|---------|---------|
| ML Modeling | `/ml-modeling` | Model architecture and training |
| Data Engineering | `/data-engineering` | Data pipelines and processing |
| ML Deployment | `/ml-deployment` | Model serving and inference |
| Experiment Tracking | `/experiment-tracking` | MLflow, W&B, experiment management |
| ML Testing | `/ml-testing` | Model validation and testing |

## Technology Stack

### Deep Learning
- **Frameworks**: PyTorch, TensorFlow, JAX
- **Libraries**: Hugging Face, timm, torchvision
- **Training**: PyTorch Lightning, Keras

### Data
- **Processing**: Pandas, Polars, DuckDB
- **Visualization**: Matplotlib, Seaborn, Plotly
- **Feature Engineering**: scikit-learn, Feature-engine

### MLOps
- **Experiment Tracking**: MLflow, Weights & Biases, Neptune
- **Model Registry**: MLflow, DVC
- **Serving**: TorchServe, TensorFlow Serving, Triton
- **Orchestration**: Airflow, Prefect, Dagster

### Infrastructure
- **Compute**: AWS SageMaker, GCP Vertex AI, Azure ML
- **GPUs**: CUDA, cuDNN, NVIDIA Triton
- **Containers**: Docker, NVIDIA Container Toolkit

## Workflow Pattern

```
User Request
    │
    ▼
┌─────────────────┐
│  /skill-router  │ ◄── MANDATORY: Route to ML skills
└────────┬────────┘
         │
         ▼
┌─────────────────────┐
│ /task-decomposition │ ◄── Break into atomic subtasks
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│  /data-engineering  │ ◄── Data pipeline and quality
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│   /ml-modeling      │ ◄── Model architecture and training
└────────┬────────────┘
         │
         ▼
┌─────────────────────────┐
│   /experiment-tracking  │ ◄── Log experiments
└────────┬────────────────┘
         │
         ▼
┌─────────────────────┐
│   /ml-testing       │ ◄── Validate model
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│   /ml-deployment    │ ◄── Deploy to production
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│   /pm-challenge     │ ◄── Product review
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│   /progress-update  │ ◄── Update status & commit
└─────────────────────┘
```

## ML Code Standards

### Reproducibility
- Set random seeds
- Version datasets
- Log all hyperparameters
- Use config files

### Code Quality
- Type hints for all functions
- Docstrings with examples
- Modular architecture
- Configuration management

### Experiment Management
- Meaningful experiment names
- Clear metrics logging
- Artifact versioning
- Comparison baselines

## Project Structure

```
ml_project/
├── configs/
│   ├── model/
│   ├── training/
│   └── data/
├── data/
│   ├── raw/
│   ├── processed/
│   └── features/
├── notebooks/
│   ├── exploration/
│   └── experiments/
├── src/
│   ├── data/
│   │   ├── dataset.py
│   │   └── transforms.py
│   ├── models/
│   │   ├── architecture.py
│   │   └── layers.py
│   ├── training/
│   │   ├── trainer.py
│   │   └── callbacks.py
│   ├── evaluation/
│   │   └── metrics.py
│   └── inference/
│       └── predictor.py
├── tests/
├── scripts/
│   ├── train.py
│   ├── evaluate.py
│   └── serve.py
├── Dockerfile
├── requirements.txt
└── pyproject.toml
```

## ML Development Principles

### Data Quality
- Validate data distributions
- Handle missing values
- Check for data leakage
- Monitor data drift

### Model Development
- Start simple, add complexity
- Use proper train/val/test splits
- Cross-validation for small data
- Regularization and early stopping

### Evaluation
- Multiple metrics
- Confidence intervals
- Fairness assessment
- Business metrics alignment

## MCP Configuration for ML

Recommended MCPs for ML development:
- `github` - Repository management
- `filesystem` - Data and model files
- `jupyter` - Notebook management (if available)

## Branching Strategy

```
main
  │
  ├── experiment/model-v1
  ├── experiment/feature-engineering
  ├── feature/data-pipeline
  ├── feature/model-serving
  └── release/model-v1.0
```

## Remember

1. **Never skip the skill router** - it's the gateway to efficient context
2. **Decompose before implementing** - atomic tasks succeed
3. **Reproducibility is essential** - log everything
4. **Data quality first** - garbage in, garbage out
5. **Challenge results** - better products through critique
6. **Monitor in production** - models degrade over time
