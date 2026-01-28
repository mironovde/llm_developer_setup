---
name: ml-modeling
description: Machine learning model development including architecture design, training, hyperparameter tuning, and optimization. Covers PyTorch, TensorFlow, and scikit-learn patterns.
user-invocable: true
argument-hint: "[model type or task]"
---

# ML Modeling Skill

You are an expert ML engineer. Your role is to design, train, and optimize machine learning models following best practices for reproducibility and performance.

## Model Development Principles

### Start Simple
- Begin with baseline models
- Add complexity incrementally
- Measure improvements rigorously
- Don't over-engineer early

### Reproducibility
- Set all random seeds
- Version code and data
- Log hyperparameters
- Document experiments

## PyTorch Patterns

### Model Architecture
```python
import torch
import torch.nn as nn
from typing import Optional

class TransformerBlock(nn.Module):
    def __init__(
        self,
        d_model: int,
        n_heads: int,
        d_ff: int,
        dropout: float = 0.1,
    ):
        super().__init__()
        self.attention = nn.MultiheadAttention(d_model, n_heads, dropout=dropout)
        self.norm1 = nn.LayerNorm(d_model)
        self.norm2 = nn.LayerNorm(d_model)
        self.ffn = nn.Sequential(
            nn.Linear(d_model, d_ff),
            nn.GELU(),
            nn.Dropout(dropout),
            nn.Linear(d_ff, d_model),
            nn.Dropout(dropout),
        )

    def forward(
        self,
        x: torch.Tensor,
        mask: Optional[torch.Tensor] = None,
    ) -> torch.Tensor:
        # Pre-norm architecture
        attn_out, _ = self.attention(
            self.norm1(x), self.norm1(x), self.norm1(x),
            attn_mask=mask
        )
        x = x + attn_out
        x = x + self.ffn(self.norm2(x))
        return x


class TextClassifier(nn.Module):
    def __init__(
        self,
        vocab_size: int,
        d_model: int = 256,
        n_heads: int = 8,
        n_layers: int = 4,
        n_classes: int = 2,
        max_seq_len: int = 512,
        dropout: float = 0.1,
    ):
        super().__init__()
        self.embedding = nn.Embedding(vocab_size, d_model)
        self.pos_encoding = nn.Parameter(torch.randn(1, max_seq_len, d_model) * 0.02)
        self.layers = nn.ModuleList([
            TransformerBlock(d_model, n_heads, d_model * 4, dropout)
            for _ in range(n_layers)
        ])
        self.classifier = nn.Linear(d_model, n_classes)
        self.dropout = nn.Dropout(dropout)

    def forward(self, x: torch.Tensor, mask: Optional[torch.Tensor] = None) -> torch.Tensor:
        seq_len = x.size(1)
        x = self.embedding(x) + self.pos_encoding[:, :seq_len, :]
        x = self.dropout(x)

        for layer in self.layers:
            x = layer(x, mask)

        # Global average pooling
        x = x.mean(dim=1)
        return self.classifier(x)
```

### Training Loop
```python
import torch
from torch.utils.data import DataLoader
from tqdm import tqdm
from typing import Dict, Any

def train_epoch(
    model: nn.Module,
    dataloader: DataLoader,
    optimizer: torch.optim.Optimizer,
    criterion: nn.Module,
    device: torch.device,
    scheduler: Optional[Any] = None,
) -> Dict[str, float]:
    model.train()
    total_loss = 0.0
    correct = 0
    total = 0

    for batch in tqdm(dataloader, desc="Training"):
        inputs = batch["input_ids"].to(device)
        labels = batch["labels"].to(device)

        optimizer.zero_grad()
        outputs = model(inputs)
        loss = criterion(outputs, labels)

        loss.backward()
        torch.nn.utils.clip_grad_norm_(model.parameters(), max_norm=1.0)
        optimizer.step()

        if scheduler is not None:
            scheduler.step()

        total_loss += loss.item()
        _, predicted = outputs.max(1)
        total += labels.size(0)
        correct += predicted.eq(labels).sum().item()

    return {
        "loss": total_loss / len(dataloader),
        "accuracy": correct / total,
    }


@torch.no_grad()
def evaluate(
    model: nn.Module,
    dataloader: DataLoader,
    criterion: nn.Module,
    device: torch.device,
) -> Dict[str, float]:
    model.eval()
    total_loss = 0.0
    correct = 0
    total = 0

    for batch in tqdm(dataloader, desc="Evaluating"):
        inputs = batch["input_ids"].to(device)
        labels = batch["labels"].to(device)

        outputs = model(inputs)
        loss = criterion(outputs, labels)

        total_loss += loss.item()
        _, predicted = outputs.max(1)
        total += labels.size(0)
        correct += predicted.eq(labels).sum().item()

    return {
        "loss": total_loss / len(dataloader),
        "accuracy": correct / total,
    }
```

### Configuration Management
```python
from dataclasses import dataclass, field
from typing import List, Optional

@dataclass
class ModelConfig:
    vocab_size: int = 30000
    d_model: int = 256
    n_heads: int = 8
    n_layers: int = 4
    n_classes: int = 2
    max_seq_len: int = 512
    dropout: float = 0.1

@dataclass
class TrainingConfig:
    batch_size: int = 32
    learning_rate: float = 1e-4
    weight_decay: float = 0.01
    warmup_steps: int = 1000
    max_epochs: int = 10
    early_stopping_patience: int = 3
    gradient_clip_norm: float = 1.0

@dataclass
class ExperimentConfig:
    model: ModelConfig = field(default_factory=ModelConfig)
    training: TrainingConfig = field(default_factory=TrainingConfig)
    seed: int = 42
    experiment_name: str = "default"

# Usage
config = ExperimentConfig(
    model=ModelConfig(d_model=512, n_layers=6),
    training=TrainingConfig(learning_rate=5e-5),
)
```

## PyTorch Lightning

```python
import pytorch_lightning as pl
from pytorch_lightning.callbacks import ModelCheckpoint, EarlyStopping

class LitClassifier(pl.LightningModule):
    def __init__(self, config: ExperimentConfig):
        super().__init__()
        self.save_hyperparameters()
        self.config = config
        self.model = TextClassifier(**asdict(config.model))
        self.criterion = nn.CrossEntropyLoss()

    def forward(self, x):
        return self.model(x)

    def training_step(self, batch, batch_idx):
        outputs = self(batch["input_ids"])
        loss = self.criterion(outputs, batch["labels"])
        acc = (outputs.argmax(dim=1) == batch["labels"]).float().mean()

        self.log("train/loss", loss, prog_bar=True)
        self.log("train/acc", acc, prog_bar=True)
        return loss

    def validation_step(self, batch, batch_idx):
        outputs = self(batch["input_ids"])
        loss = self.criterion(outputs, batch["labels"])
        acc = (outputs.argmax(dim=1) == batch["labels"]).float().mean()

        self.log("val/loss", loss, prog_bar=True)
        self.log("val/acc", acc, prog_bar=True)

    def configure_optimizers(self):
        optimizer = torch.optim.AdamW(
            self.parameters(),
            lr=self.config.training.learning_rate,
            weight_decay=self.config.training.weight_decay,
        )
        scheduler = torch.optim.lr_scheduler.CosineAnnealingLR(
            optimizer,
            T_max=self.trainer.estimated_stepping_batches,
        )
        return {
            "optimizer": optimizer,
            "lr_scheduler": {"scheduler": scheduler, "interval": "step"},
        }


# Training
trainer = pl.Trainer(
    max_epochs=config.training.max_epochs,
    accelerator="auto",
    devices="auto",
    callbacks=[
        ModelCheckpoint(monitor="val/loss", mode="min", save_top_k=3),
        EarlyStopping(monitor="val/loss", patience=3, mode="min"),
    ],
    precision="16-mixed",
)

model = LitClassifier(config)
trainer.fit(model, train_dataloader, val_dataloader)
```

## Scikit-learn Patterns

```python
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import cross_val_score, GridSearchCV
from sklearn.ensemble import RandomForestClassifier, GradientBoostingClassifier
from sklearn.metrics import classification_report, confusion_matrix

# Pipeline
pipeline = Pipeline([
    ("scaler", StandardScaler()),
    ("classifier", RandomForestClassifier(random_state=42)),
])

# Cross-validation
scores = cross_val_score(pipeline, X_train, y_train, cv=5, scoring="accuracy")
print(f"CV Accuracy: {scores.mean():.4f} (+/- {scores.std() * 2:.4f})")

# Hyperparameter tuning
param_grid = {
    "classifier__n_estimators": [100, 200, 300],
    "classifier__max_depth": [10, 20, None],
    "classifier__min_samples_split": [2, 5, 10],
}

grid_search = GridSearchCV(
    pipeline,
    param_grid,
    cv=5,
    scoring="accuracy",
    n_jobs=-1,
    verbose=1,
)
grid_search.fit(X_train, y_train)

print(f"Best params: {grid_search.best_params_}")
print(f"Best score: {grid_search.best_score_:.4f}")

# Evaluation
y_pred = grid_search.predict(X_test)
print(classification_report(y_test, y_pred))
print(confusion_matrix(y_test, y_pred))
```

## Hyperparameter Optimization

### Optuna
```python
import optuna
from optuna.integration import PyTorchLightningPruningCallback

def objective(trial: optuna.Trial) -> float:
    # Suggest hyperparameters
    config = ExperimentConfig(
        model=ModelConfig(
            d_model=trial.suggest_categorical("d_model", [128, 256, 512]),
            n_layers=trial.suggest_int("n_layers", 2, 8),
            n_heads=trial.suggest_categorical("n_heads", [4, 8, 16]),
            dropout=trial.suggest_float("dropout", 0.1, 0.5),
        ),
        training=TrainingConfig(
            learning_rate=trial.suggest_float("lr", 1e-5, 1e-3, log=True),
            batch_size=trial.suggest_categorical("batch_size", [16, 32, 64]),
        ),
    )

    model = LitClassifier(config)
    trainer = pl.Trainer(
        max_epochs=10,
        callbacks=[
            PyTorchLightningPruningCallback(trial, monitor="val/loss"),
        ],
        enable_progress_bar=False,
    )

    trainer.fit(model, train_dataloader, val_dataloader)
    return trainer.callback_metrics["val/loss"].item()


# Run optimization
study = optuna.create_study(
    direction="minimize",
    pruner=optuna.pruners.MedianPruner(),
)
study.optimize(objective, n_trials=100, timeout=3600)

print(f"Best trial: {study.best_trial.params}")
```

## Model Optimization

### Quantization
```python
import torch.quantization

# Dynamic quantization
quantized_model = torch.quantization.quantize_dynamic(
    model,
    {nn.Linear},
    dtype=torch.qint8,
)

# Static quantization
model.qconfig = torch.quantization.get_default_qconfig("fbgemm")
model_prepared = torch.quantization.prepare(model)
# Run calibration data through model
model_quantized = torch.quantization.convert(model_prepared)
```

### ONNX Export
```python
import torch.onnx

dummy_input = torch.randint(0, 1000, (1, 512))

torch.onnx.export(
    model,
    dummy_input,
    "model.onnx",
    export_params=True,
    opset_version=14,
    input_names=["input_ids"],
    output_names=["logits"],
    dynamic_axes={
        "input_ids": {0: "batch_size", 1: "sequence_length"},
        "logits": {0: "batch_size"},
    },
)
```

## Model Checklist

- [ ] Set random seeds for reproducibility
- [ ] Validate data shapes and types
- [ ] Proper train/val/test splits
- [ ] Gradient clipping enabled
- [ ] Learning rate scheduling
- [ ] Early stopping configured
- [ ] Checkpointing best models
- [ ] Metrics logged properly
- [ ] Memory usage monitored
- [ ] Inference speed benchmarked

## Remember

- Start with baselines
- Validate before training
- Log everything
- Monitor for overfitting
- Profile memory and speed
- Document all experiments
