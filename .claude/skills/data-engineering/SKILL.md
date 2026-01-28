---
name: data-engineering
description: Data pipeline development including data loading, preprocessing, feature engineering, and data quality. Covers Pandas, Polars, and data validation patterns.
user-invocable: true
argument-hint: "[data task or pipeline]"
---

# Data Engineering Skill

You are an expert data engineer. Your role is to build robust data pipelines, ensure data quality, and create effective feature engineering workflows.

## Data Loading Patterns

### PyTorch Dataset
```python
from torch.utils.data import Dataset, DataLoader
from typing import Dict, Any, Optional
import torch

class TextDataset(Dataset):
    def __init__(
        self,
        texts: list[str],
        labels: list[int],
        tokenizer,
        max_length: int = 512,
    ):
        self.texts = texts
        self.labels = labels
        self.tokenizer = tokenizer
        self.max_length = max_length

    def __len__(self) -> int:
        return len(self.texts)

    def __getitem__(self, idx: int) -> Dict[str, torch.Tensor]:
        text = self.texts[idx]
        label = self.labels[idx]

        encoding = self.tokenizer(
            text,
            max_length=self.max_length,
            padding="max_length",
            truncation=True,
            return_tensors="pt",
        )

        return {
            "input_ids": encoding["input_ids"].squeeze(0),
            "attention_mask": encoding["attention_mask"].squeeze(0),
            "labels": torch.tensor(label, dtype=torch.long),
        }


# DataLoader with custom collate
def collate_fn(batch: list[Dict[str, torch.Tensor]]) -> Dict[str, torch.Tensor]:
    return {
        key: torch.stack([item[key] for item in batch])
        for key in batch[0].keys()
    }

dataloader = DataLoader(
    dataset,
    batch_size=32,
    shuffle=True,
    num_workers=4,
    pin_memory=True,
    collate_fn=collate_fn,
)
```

### Hugging Face Datasets
```python
from datasets import load_dataset, Dataset, DatasetDict
from datasets import Features, Value, ClassLabel

# Load from Hub
dataset = load_dataset("imdb")

# Load from files
dataset = load_dataset(
    "csv",
    data_files={"train": "train.csv", "test": "test.csv"},
)

# Create from pandas
df = pd.read_csv("data.csv")
dataset = Dataset.from_pandas(df)

# Define schema
features = Features({
    "text": Value("string"),
    "label": ClassLabel(names=["negative", "positive"]),
})
dataset = dataset.cast(features)

# Preprocessing
def preprocess(examples):
    return tokenizer(
        examples["text"],
        truncation=True,
        max_length=512,
    )

tokenized = dataset.map(
    preprocess,
    batched=True,
    num_proc=4,
    remove_columns=["text"],
)

# Save/Load processed data
tokenized.save_to_disk("processed_data")
loaded = load_from_disk("processed_data")
```

## Data Processing

### Pandas Patterns
```python
import pandas as pd
import numpy as np

# Efficient loading
df = pd.read_csv(
    "large_file.csv",
    dtype={
        "id": "int32",
        "category": "category",
        "value": "float32",
    },
    parse_dates=["timestamp"],
    usecols=["id", "category", "value", "timestamp"],
)

# Memory optimization
def optimize_dtypes(df: pd.DataFrame) -> pd.DataFrame:
    for col in df.select_dtypes(include=["int64"]).columns:
        df[col] = pd.to_numeric(df[col], downcast="integer")

    for col in df.select_dtypes(include=["float64"]).columns:
        df[col] = pd.to_numeric(df[col], downcast="float")

    for col in df.select_dtypes(include=["object"]).columns:
        if df[col].nunique() / len(df) < 0.5:
            df[col] = df[col].astype("category")

    return df

# Chunked processing
chunks = pd.read_csv("huge_file.csv", chunksize=100000)
results = []
for chunk in chunks:
    processed = process_chunk(chunk)
    results.append(processed)
df = pd.concat(results, ignore_index=True)
```

### Polars (Faster Alternative)
```python
import polars as pl

# Load data
df = pl.read_csv("data.csv")

# Lazy evaluation
lazy_df = (
    pl.scan_csv("data.csv")
    .filter(pl.col("value") > 0)
    .group_by("category")
    .agg([
        pl.col("value").mean().alias("mean_value"),
        pl.col("value").std().alias("std_value"),
        pl.count().alias("count"),
    ])
    .sort("mean_value", descending=True)
)

# Collect results
result = lazy_df.collect()

# Streaming for large files
df = pl.read_csv("huge_file.csv", rechunk=False)
```

## Feature Engineering

### Numerical Features
```python
from sklearn.preprocessing import StandardScaler, RobustScaler, PowerTransformer
from sklearn.impute import SimpleImputer, KNNImputer

# Scaling pipeline
numerical_pipeline = Pipeline([
    ("imputer", SimpleImputer(strategy="median")),
    ("scaler", RobustScaler()),  # Better for outliers
])

# Log transform for skewed features
def log_transform(df: pd.DataFrame, columns: list[str]) -> pd.DataFrame:
    for col in columns:
        df[f"{col}_log"] = np.log1p(df[col].clip(lower=0))
    return df

# Binning
df["age_bin"] = pd.cut(
    df["age"],
    bins=[0, 18, 35, 50, 65, 100],
    labels=["child", "young_adult", "adult", "middle_aged", "senior"],
)
```

### Categorical Features
```python
from sklearn.preprocessing import OneHotEncoder, LabelEncoder, OrdinalEncoder
from category_encoders import TargetEncoder, CatBoostEncoder

# One-hot encoding (low cardinality)
encoder = OneHotEncoder(sparse_output=False, handle_unknown="ignore")
encoded = encoder.fit_transform(df[["category"]])

# Target encoding (high cardinality)
target_encoder = TargetEncoder(smoothing=10)
df["category_encoded"] = target_encoder.fit_transform(
    df["category"],
    df["target"],
)

# Frequency encoding
freq_map = df["category"].value_counts(normalize=True).to_dict()
df["category_freq"] = df["category"].map(freq_map)
```

### Time Features
```python
def extract_time_features(df: pd.DataFrame, col: str) -> pd.DataFrame:
    df[f"{col}_year"] = df[col].dt.year
    df[f"{col}_month"] = df[col].dt.month
    df[f"{col}_day"] = df[col].dt.day
    df[f"{col}_dayofweek"] = df[col].dt.dayofweek
    df[f"{col}_hour"] = df[col].dt.hour
    df[f"{col}_is_weekend"] = df[col].dt.dayofweek >= 5

    # Cyclical encoding
    df[f"{col}_month_sin"] = np.sin(2 * np.pi * df[col].dt.month / 12)
    df[f"{col}_month_cos"] = np.cos(2 * np.pi * df[col].dt.month / 12)

    return df
```

### Text Features
```python
from sklearn.feature_extraction.text import TfidfVectorizer, CountVectorizer

# TF-IDF
tfidf = TfidfVectorizer(
    max_features=5000,
    ngram_range=(1, 2),
    min_df=5,
    max_df=0.95,
)
tfidf_features = tfidf.fit_transform(df["text"])

# Text statistics
df["text_length"] = df["text"].str.len()
df["word_count"] = df["text"].str.split().str.len()
df["avg_word_length"] = df["text_length"] / df["word_count"]
df["unique_words"] = df["text"].str.split().apply(lambda x: len(set(x)))
```

## Data Validation

### Pandera
```python
import pandera as pa
from pandera import Column, Check, DataFrameSchema

schema = DataFrameSchema({
    "user_id": Column(int, Check.greater_than(0), nullable=False),
    "email": Column(str, Check.str_matches(r"^[\w.-]+@[\w.-]+\.\w+$")),
    "age": Column(int, Check.in_range(0, 120), nullable=True),
    "signup_date": Column(pa.DateTime, Check.less_than_or_equal_to(pd.Timestamp.now())),
    "revenue": Column(float, Check.greater_than_or_equal_to(0)),
})

# Validate
try:
    validated_df = schema.validate(df)
except pa.errors.SchemaError as e:
    print(f"Validation failed: {e}")
```

### Great Expectations
```python
import great_expectations as gx

context = gx.get_context()
datasource = context.sources.add_pandas("pandas_source")
data_asset = datasource.add_dataframe_asset("my_asset")

# Create expectations
batch = data_asset.build_batch_request(dataframe=df)
validator = context.get_validator(batch_request=batch)

validator.expect_column_values_to_not_be_null("user_id")
validator.expect_column_values_to_be_between("age", min_value=0, max_value=120)
validator.expect_column_values_to_match_regex("email", r"^[\w.-]+@[\w.-]+\.\w+$")
validator.expect_column_mean_to_be_between("revenue", min_value=0, max_value=10000)

# Save and run
validator.save_expectation_suite()
results = context.run_checkpoint(checkpoint_name="my_checkpoint")
```

## Data Splits

```python
from sklearn.model_selection import train_test_split, StratifiedKFold

# Simple split
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42, stratify=y
)

# Time-based split (for time series)
def time_based_split(df: pd.DataFrame, date_col: str, test_ratio: float = 0.2):
    df = df.sort_values(date_col)
    split_idx = int(len(df) * (1 - test_ratio))
    return df.iloc[:split_idx], df.iloc[split_idx:]

# K-Fold for cross-validation
kfold = StratifiedKFold(n_splits=5, shuffle=True, random_state=42)
for fold, (train_idx, val_idx) in enumerate(kfold.split(X, y)):
    X_train, X_val = X[train_idx], X[val_idx]
    y_train, y_val = y[train_idx], y[val_idx]
    # Train and evaluate...

# Group-based split (prevent data leakage)
from sklearn.model_selection import GroupShuffleSplit

gss = GroupShuffleSplit(n_splits=1, test_size=0.2, random_state=42)
train_idx, test_idx = next(gss.split(X, y, groups=df["user_id"]))
```

## Data Quality Checks

```python
def data_quality_report(df: pd.DataFrame) -> Dict[str, Any]:
    report = {
        "shape": df.shape,
        "memory_usage_mb": df.memory_usage(deep=True).sum() / 1e6,
        "missing_values": df.isnull().sum().to_dict(),
        "missing_pct": (df.isnull().sum() / len(df) * 100).to_dict(),
        "duplicates": df.duplicated().sum(),
        "dtypes": df.dtypes.astype(str).to_dict(),
    }

    # Numerical stats
    numerical = df.select_dtypes(include=[np.number])
    report["numerical_stats"] = numerical.describe().to_dict()

    # Categorical stats
    categorical = df.select_dtypes(include=["object", "category"])
    report["categorical_cardinality"] = {
        col: df[col].nunique() for col in categorical.columns
    }

    return report
```

## Data Pipeline Checklist

- [ ] Data schema defined and validated
- [ ] Missing values handled
- [ ] Outliers addressed
- [ ] Data types optimized
- [ ] No data leakage in splits
- [ ] Feature engineering documented
- [ ] Transformations are reversible
- [ ] Pipeline is reproducible

## Remember

- Validate data at every step
- Prevent data leakage
- Document transformations
- Version datasets
- Monitor data drift
- Profile before processing
