---
name: ml-testing
description: ML model testing including unit tests, integration tests, model validation, and behavioral testing. Covers pytest patterns and ML-specific testing strategies.
user-invocable: true
argument-hint: "[model or component to test]"
---

# ML Testing Skill

You are an expert in ML testing. Your role is to ensure model quality through comprehensive testing including data validation, model validation, and behavioral testing.

## Testing Layers

```
          /\
         /  \        <- Integration Tests
        /----\       <- Model Validation
       /------\      <- Behavioral Tests
      /--------\     <- Unit Tests
     /----------\    <- Data Tests
    /------------\
```

## Data Testing

### Schema Validation
```python
import pytest
import pandera as pa
from pandera import Column, Check, DataFrameSchema
import pandas as pd

# Define expected schema
training_schema = DataFrameSchema({
    "text": Column(str, Check.str_length(min_value=1), nullable=False),
    "label": Column(int, Check.isin([0, 1]), nullable=False),
    "timestamp": Column(pa.DateTime, nullable=True),
})

def test_training_data_schema():
    df = pd.read_csv("data/train.csv")
    training_schema.validate(df)

def test_no_data_leakage():
    train = pd.read_csv("data/train.csv")
    test = pd.read_csv("data/test.csv")

    # Check no overlapping IDs
    train_ids = set(train["id"])
    test_ids = set(test["id"])
    assert train_ids.isdisjoint(test_ids), "Data leakage detected!"

def test_label_distribution():
    df = pd.read_csv("data/train.csv")
    distribution = df["label"].value_counts(normalize=True)

    # Check for extreme imbalance
    assert distribution.min() > 0.1, "Severe class imbalance"
    assert distribution.max() < 0.9, "Severe class imbalance"

def test_no_duplicate_samples():
    df = pd.read_csv("data/train.csv")
    duplicates = df.duplicated(subset=["text"]).sum()
    assert duplicates == 0, f"Found {duplicates} duplicate samples"
```

### Feature Tests
```python
def test_feature_ranges():
    features = load_features("data/features.parquet")

    # Check for NaN
    assert not features.isnull().any().any(), "NaN values in features"

    # Check ranges
    for col in features.select_dtypes(include=[np.number]).columns:
        assert features[col].abs().max() < 1e6, f"{col} has extreme values"

def test_feature_consistency():
    train_features = load_features("data/train_features.parquet")
    test_features = load_features("data/test_features.parquet")

    # Same columns
    assert set(train_features.columns) == set(test_features.columns)

    # Similar distributions
    for col in train_features.select_dtypes(include=[np.number]).columns:
        train_mean = train_features[col].mean()
        test_mean = test_features[col].mean()
        assert abs(train_mean - test_mean) / (train_mean + 1e-8) < 0.5, \
            f"{col} distribution differs significantly"
```

## Model Unit Tests

### Component Tests
```python
import torch
import pytest

class TestModelArchitecture:
    @pytest.fixture
    def model(self):
        return TextClassifier(vocab_size=1000, n_classes=2)

    def test_forward_pass_shape(self, model):
        batch_size, seq_len = 4, 128
        x = torch.randint(0, 1000, (batch_size, seq_len))

        output = model(x)

        assert output.shape == (batch_size, 2)

    def test_forward_pass_gradient(self, model):
        x = torch.randint(0, 1000, (4, 128))
        output = model(x)
        loss = output.sum()
        loss.backward()

        # Check gradients flow
        for param in model.parameters():
            if param.requires_grad:
                assert param.grad is not None
                assert not torch.isnan(param.grad).any()

    def test_model_determinism(self, model):
        torch.manual_seed(42)
        model.eval()

        x = torch.randint(0, 1000, (4, 128))

        output1 = model(x)
        output2 = model(x)

        assert torch.allclose(output1, output2)

    def test_batch_independence(self, model):
        model.eval()
        x = torch.randint(0, 1000, (4, 128))

        # Single sample prediction
        single_output = model(x[0:1])

        # Batch prediction
        batch_output = model(x)

        assert torch.allclose(single_output, batch_output[0:1], atol=1e-5)
```

### Loss Function Tests
```python
def test_loss_function_positive():
    criterion = nn.CrossEntropyLoss()
    logits = torch.randn(4, 2)
    labels = torch.randint(0, 2, (4,))

    loss = criterion(logits, labels)

    assert loss > 0

def test_loss_decreases_with_correct_predictions():
    criterion = nn.CrossEntropyLoss()

    # Perfect predictions
    perfect_logits = torch.tensor([[10.0, -10.0], [-10.0, 10.0]])
    labels = torch.tensor([0, 1])
    perfect_loss = criterion(perfect_logits, labels)

    # Random predictions
    random_logits = torch.randn(2, 2)
    random_loss = criterion(random_logits, labels)

    assert perfect_loss < random_loss
```

## Model Validation

### Performance Tests
```python
@pytest.fixture
def trained_model():
    model = load_model("models/best_model.pt")
    model.eval()
    return model

@pytest.fixture
def test_data():
    return load_dataset("data/test.csv")

def test_minimum_accuracy(trained_model, test_data):
    predictions = predict(trained_model, test_data)
    accuracy = (predictions == test_data["labels"]).mean()

    assert accuracy >= 0.85, f"Accuracy {accuracy:.2f} below threshold"

def test_class_wise_performance(trained_model, test_data):
    predictions = predict(trained_model, test_data)

    for label in test_data["labels"].unique():
        mask = test_data["labels"] == label
        class_acc = (predictions[mask] == label).mean()

        assert class_acc >= 0.75, f"Class {label} accuracy {class_acc:.2f} below threshold"

def test_no_performance_regression(trained_model, test_data):
    current_metrics = evaluate(trained_model, test_data)

    baseline_metrics = load_baseline_metrics("metrics/baseline.json")

    assert current_metrics["accuracy"] >= baseline_metrics["accuracy"] - 0.02, \
        "Performance regression detected"
```

### Latency Tests
```python
import time

def test_inference_latency(trained_model):
    model = trained_model
    model.eval()

    # Warmup
    dummy = torch.randint(0, 1000, (1, 128))
    for _ in range(10):
        with torch.no_grad():
            model(dummy)

    # Benchmark
    latencies = []
    for _ in range(100):
        x = torch.randint(0, 1000, (1, 128))
        start = time.perf_counter()
        with torch.no_grad():
            model(x)
        latencies.append(time.perf_counter() - start)

    p50 = np.percentile(latencies, 50) * 1000
    p99 = np.percentile(latencies, 99) * 1000

    assert p50 < 10, f"P50 latency {p50:.1f}ms exceeds threshold"
    assert p99 < 50, f"P99 latency {p99:.1f}ms exceeds threshold"

def test_batch_throughput(trained_model):
    model = trained_model
    model.eval()

    batch_sizes = [1, 8, 32, 64]
    for batch_size in batch_sizes:
        x = torch.randint(0, 1000, (batch_size, 128))

        start = time.perf_counter()
        for _ in range(100):
            with torch.no_grad():
                model(x)
        elapsed = time.perf_counter() - start

        throughput = (100 * batch_size) / elapsed
        assert throughput > 100, f"Throughput {throughput:.0f} samples/s too low"
```

## Behavioral Testing

### Invariance Tests
```python
def test_invariance_to_whitespace():
    """Model should give same prediction regardless of whitespace."""
    texts = [
        "This is a great movie",
        "This  is  a  great  movie",
        "This is a great movie ",
        " This is a great movie",
    ]

    predictions = [predict(model, text) for text in texts]
    assert len(set(predictions)) == 1, "Model not invariant to whitespace"

def test_invariance_to_capitalization():
    """Model should give same prediction regardless of case."""
    texts = [
        "this is a great movie",
        "THIS IS A GREAT MOVIE",
        "This Is A Great Movie",
    ]

    predictions = [predict(model, text) for text in texts]
    assert len(set(predictions)) == 1, "Model not invariant to capitalization"
```

### Directional Expectation Tests
```python
def test_sentiment_direction():
    """Adding positive words should increase positive sentiment."""
    base_text = "The movie was okay"
    positive_text = "The movie was okay, actually it was great and wonderful"

    base_prob = predict_proba(model, base_text)[1]  # Positive class
    positive_prob = predict_proba(model, positive_text)[1]

    assert positive_prob > base_prob, "Adding positive words didn't increase score"

def test_negation_handling():
    """Model should handle negation correctly."""
    positive = "I love this product"
    negated = "I do not love this product"

    positive_pred = predict(model, positive)
    negated_pred = predict(model, negated)

    assert positive_pred != negated_pred, "Model doesn't handle negation"
```

### Minimum Functionality Tests
```python
def test_obvious_positive():
    """Model should correctly classify obviously positive text."""
    texts = [
        "This is absolutely amazing! Best thing ever!",
        "I love it so much, it's perfect!",
        "Incredible, wonderful, fantastic!",
    ]

    for text in texts:
        pred = predict(model, text)
        assert pred == "positive", f"Failed on obvious positive: {text}"

def test_obvious_negative():
    """Model should correctly classify obviously negative text."""
    texts = [
        "This is terrible, worst thing ever!",
        "I hate it, absolutely horrible!",
        "Awful, disgusting, pathetic!",
    ]

    for text in texts:
        pred = predict(model, text)
        assert pred == "negative", f"Failed on obvious negative: {text}"
```

## Integration Tests

```python
@pytest.mark.integration
def test_full_pipeline():
    """Test the complete prediction pipeline."""
    # Load raw data
    raw_text = "This is a test input for the model."

    # Preprocess
    preprocessed = preprocess(raw_text)
    assert isinstance(preprocessed, dict)
    assert "input_ids" in preprocessed

    # Predict
    prediction = model.predict(preprocessed)
    assert prediction in ["positive", "negative"]

@pytest.mark.integration
def test_api_endpoint():
    """Test the prediction API endpoint."""
    response = client.post(
        "/predict",
        json={"texts": ["Test input"]},
    )

    assert response.status_code == 200
    assert "predictions" in response.json()
    assert len(response.json()["predictions"]) == 1
```

## Test Configuration

```python
# conftest.py
import pytest
import torch

@pytest.fixture(scope="session")
def device():
    return torch.device("cuda" if torch.cuda.is_available() else "cpu")

@pytest.fixture(scope="session")
def trained_model(device):
    model = load_model("models/best_model.pt")
    model = model.to(device)
    model.eval()
    return model

@pytest.fixture
def sample_batch():
    return {
        "input_ids": torch.randint(0, 1000, (4, 128)),
        "attention_mask": torch.ones(4, 128),
        "labels": torch.randint(0, 2, (4,)),
    }

# pytest.ini
[pytest]
markers =
    slow: marks tests as slow
    integration: marks tests as integration tests
    gpu: marks tests requiring GPU

testpaths = tests
python_files = test_*.py
python_functions = test_*
```

## ML Testing Checklist

### Data Tests
- [ ] Schema validation
- [ ] No data leakage
- [ ] Label distribution check
- [ ] No duplicates
- [ ] Feature ranges valid

### Model Tests
- [ ] Forward pass works
- [ ] Gradients flow correctly
- [ ] Deterministic inference
- [ ] Batch independence

### Performance Tests
- [ ] Meets accuracy threshold
- [ ] No regression from baseline
- [ ] Latency within bounds
- [ ] Throughput acceptable

### Behavioral Tests
- [ ] Invariance properties
- [ ] Directional expectations
- [ ] Minimum functionality
- [ ] Edge cases handled

## Remember

- Test data as rigorously as code
- Include behavioral tests
- Monitor for regression
- Test at multiple granularities
- Automate everything
- Document test rationale
