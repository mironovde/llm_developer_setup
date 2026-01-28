---
name: experiment-tracking
description: ML experiment tracking with MLflow, Weights & Biases, and DVC. Covers logging, versioning, comparison, and reproducibility. Use for any experiment management.
user-invocable: true
argument-hint: "[experiment or model to track]"
---

# Experiment Tracking Skill

You are an expert in ML experiment tracking. Your role is to ensure experiments are reproducible, comparable, and well-documented.

## MLflow

### Setup and Tracking
```python
import mlflow
from mlflow.tracking import MlflowClient

# Set tracking URI
mlflow.set_tracking_uri("http://localhost:5000")
mlflow.set_experiment("text-classification")

# Start run
with mlflow.start_run(run_name="transformer-v1"):
    # Log parameters
    mlflow.log_params({
        "model_type": "transformer",
        "d_model": 256,
        "n_layers": 4,
        "n_heads": 8,
        "learning_rate": 1e-4,
        "batch_size": 32,
        "max_epochs": 10,
    })

    # Training loop
    for epoch in range(max_epochs):
        train_metrics = train_epoch(...)
        val_metrics = evaluate(...)

        # Log metrics
        mlflow.log_metrics({
            "train_loss": train_metrics["loss"],
            "train_acc": train_metrics["accuracy"],
            "val_loss": val_metrics["loss"],
            "val_acc": val_metrics["accuracy"],
        }, step=epoch)

    # Log final metrics
    mlflow.log_metrics({
        "final_val_loss": val_metrics["loss"],
        "final_val_acc": val_metrics["accuracy"],
    })

    # Log model
    mlflow.pytorch.log_model(model, "model")

    # Log artifacts
    mlflow.log_artifact("configs/model_config.yaml")
    mlflow.log_artifact("plots/confusion_matrix.png")

    # Set tags
    mlflow.set_tags({
        "model_version": "v1.0",
        "dataset_version": "2024-01",
        "author": "ml-team",
    })
```

### Model Registry
```python
from mlflow.tracking import MlflowClient

client = MlflowClient()

# Register model
model_uri = f"runs:/{run_id}/model"
mlflow.register_model(model_uri, "text-classifier")

# Transition model stage
client.transition_model_version_stage(
    name="text-classifier",
    version=1,
    stage="Production",
    archive_existing_versions=True,
)

# Load production model
model = mlflow.pytorch.load_model("models:/text-classifier/Production")
```

### Autologging
```python
# PyTorch Lightning autolog
mlflow.pytorch.autolog()

trainer = pl.Trainer(...)
trainer.fit(model, train_loader, val_loader)
# Parameters, metrics, and model automatically logged

# Scikit-learn autolog
mlflow.sklearn.autolog()

model = RandomForestClassifier()
model.fit(X_train, y_train)
# Automatically logs parameters, metrics, and model
```

## Weights & Biases

### Basic Tracking
```python
import wandb

# Initialize
wandb.init(
    project="text-classification",
    name="transformer-v1",
    config={
        "model_type": "transformer",
        "d_model": 256,
        "n_layers": 4,
        "learning_rate": 1e-4,
        "batch_size": 32,
    },
    tags=["transformer", "experiment"],
)

# Training loop
for epoch in range(max_epochs):
    train_metrics = train_epoch(...)
    val_metrics = evaluate(...)

    # Log metrics
    wandb.log({
        "epoch": epoch,
        "train/loss": train_metrics["loss"],
        "train/acc": train_metrics["accuracy"],
        "val/loss": val_metrics["loss"],
        "val/acc": val_metrics["accuracy"],
        "learning_rate": scheduler.get_last_lr()[0],
    })

# Log final results
wandb.summary["best_val_acc"] = best_val_acc
wandb.summary["total_epochs"] = epoch + 1

# Log artifacts
wandb.save("model.pt")
wandb.save("configs/*.yaml")

wandb.finish()
```

### Advanced Features
```python
# Tables for data visualization
table = wandb.Table(columns=["text", "true_label", "pred_label", "confidence"])
for text, true, pred, conf in predictions:
    table.add_data(text, true, pred, conf)
wandb.log({"predictions": table})

# Confusion matrix
wandb.log({
    "confusion_matrix": wandb.plot.confusion_matrix(
        probs=None,
        y_true=y_true,
        preds=y_pred,
        class_names=class_names,
    )
})

# ROC curve
wandb.log({
    "roc": wandb.plot.roc_curve(y_true, y_probs, labels=class_names)
})

# Images
wandb.log({
    "examples": [
        wandb.Image(img, caption=f"True: {true}, Pred: {pred}")
        for img, true, pred in examples
    ]
})

# Histograms
wandb.log({
    "gradients": wandb.Histogram(gradients.cpu().numpy()),
    "weights": wandb.Histogram(weights.cpu().numpy()),
})

# Alerts
if val_loss > threshold:
    wandb.alert(
        title="High validation loss",
        text=f"Validation loss {val_loss:.4f} exceeds threshold {threshold}",
        level=wandb.AlertLevel.WARN,
    )
```

### Sweeps (Hyperparameter Search)
```python
# Define sweep config
sweep_config = {
    "method": "bayes",
    "metric": {"name": "val/acc", "goal": "maximize"},
    "parameters": {
        "learning_rate": {
            "distribution": "log_uniform_values",
            "min": 1e-5,
            "max": 1e-3,
        },
        "batch_size": {"values": [16, 32, 64]},
        "d_model": {"values": [128, 256, 512]},
        "n_layers": {"distribution": "int_uniform", "min": 2, "max": 8},
        "dropout": {"distribution": "uniform", "min": 0.1, "max": 0.5},
    },
}

# Create sweep
sweep_id = wandb.sweep(sweep_config, project="text-classification")

# Training function
def train():
    wandb.init()
    config = wandb.config

    model = build_model(config)
    # Train model...

    wandb.log({"val/acc": val_acc})

# Run sweep
wandb.agent(sweep_id, train, count=50)
```

## DVC (Data Version Control)

### Data Versioning
```bash
# Initialize DVC
dvc init

# Track data
dvc add data/raw/dataset.csv
git add data/raw/dataset.csv.dvc data/raw/.gitignore
git commit -m "Add raw dataset"

# Configure remote storage
dvc remote add -d myremote s3://mybucket/dvcstore

# Push data
dvc push
```

### Pipeline Definition
```yaml
# dvc.yaml
stages:
  preprocess:
    cmd: python src/preprocess.py
    deps:
      - src/preprocess.py
      - data/raw/dataset.csv
    outs:
      - data/processed/train.parquet
      - data/processed/test.parquet
    params:
      - preprocess.max_length
      - preprocess.test_size

  train:
    cmd: python src/train.py
    deps:
      - src/train.py
      - data/processed/train.parquet
    outs:
      - models/model.pt
    params:
      - train.learning_rate
      - train.batch_size
      - train.epochs
    metrics:
      - metrics/train_metrics.json:
          cache: false
    plots:
      - plots/loss_curve.csv:
          x: epoch
          y: loss

  evaluate:
    cmd: python src/evaluate.py
    deps:
      - src/evaluate.py
      - models/model.pt
      - data/processed/test.parquet
    metrics:
      - metrics/eval_metrics.json:
          cache: false
    plots:
      - plots/confusion_matrix.png
```

### Params File
```yaml
# params.yaml
preprocess:
  max_length: 512
  test_size: 0.2

train:
  learning_rate: 0.0001
  batch_size: 32
  epochs: 10
  d_model: 256
  n_layers: 4

evaluate:
  threshold: 0.5
```

### Running Pipelines
```bash
# Run entire pipeline
dvc repro

# Run specific stage
dvc repro train

# Compare experiments
dvc exp run -n exp-lr-5e5 --set-param train.learning_rate=5e-5
dvc exp run -n exp-lr-1e4 --set-param train.learning_rate=1e-4

# Show experiments
dvc exp show

# Compare metrics
dvc metrics diff

# Show plots
dvc plots diff
```

## Experiment Organization

### Naming Convention
```
{task}_{model}_{version}_{date}

Examples:
- sentiment_transformer_v1_20240115
- ner_bert_v2_20240120
- classification_rf_baseline_20240110
```

### Metadata Schema
```python
experiment_metadata = {
    # Identification
    "name": "sentiment_transformer_v1",
    "version": "1.0.0",
    "author": "ml-team",
    "date": "2024-01-15",

    # Data
    "dataset_name": "imdb",
    "dataset_version": "2024-01",
    "train_samples": 25000,
    "val_samples": 5000,
    "test_samples": 5000,

    # Model
    "model_type": "transformer",
    "model_params": 12_500_000,

    # Training
    "hardware": "nvidia-a100",
    "training_time_hours": 2.5,
    "epochs_trained": 10,

    # Results
    "val_accuracy": 0.92,
    "test_accuracy": 0.91,
    "inference_time_ms": 15,
}
```

## Comparison and Analysis

```python
import mlflow
import pandas as pd

# Search runs
runs = mlflow.search_runs(
    experiment_names=["text-classification"],
    filter_string="metrics.val_acc > 0.85",
    order_by=["metrics.val_acc DESC"],
)

# Compare top runs
top_runs = runs.head(5)
comparison = top_runs[[
    "run_id",
    "params.learning_rate",
    "params.batch_size",
    "metrics.val_acc",
    "metrics.val_loss",
]]
print(comparison.to_markdown())

# Plot comparison
import matplotlib.pyplot as plt

fig, ax = plt.subplots()
ax.scatter(
    runs["params.learning_rate"].astype(float),
    runs["metrics.val_acc"],
    c=runs["params.batch_size"].astype(int),
    cmap="viridis",
)
ax.set_xlabel("Learning Rate")
ax.set_ylabel("Validation Accuracy")
plt.colorbar(label="Batch Size")
plt.savefig("lr_vs_accuracy.png")
```

## Tracking Checklist

- [ ] Experiment name is descriptive
- [ ] All hyperparameters logged
- [ ] Training and validation metrics tracked
- [ ] Model artifacts saved
- [ ] Data version recorded
- [ ] Code version (git commit) tracked
- [ ] Hardware info logged
- [ ] Training time recorded
- [ ] Random seeds documented
- [ ] Results reproducible

## Remember

- Log everything you might need later
- Use consistent naming conventions
- Track data versions, not just model versions
- Make comparisons easy
- Document failures too
- Set up automated tracking where possible
