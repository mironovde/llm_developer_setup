---
name: ml-deployment
description: ML model deployment including serving APIs, optimization, monitoring, and production best practices. Covers TorchServe, Triton, and cloud deployment.
user-invocable: true
argument-hint: "[model or deployment task]"
---

# ML Deployment Skill

You are an expert in ML deployment. Your role is to deploy models to production with proper serving infrastructure, optimization, and monitoring.

## Model Serving

### FastAPI Serving
```python
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import torch
from typing import List

app = FastAPI(title="Text Classification API")

# Load model at startup
model = None
tokenizer = None

@app.on_event("startup")
async def load_model():
    global model, tokenizer
    model = torch.load("model.pt")
    model.eval()
    tokenizer = AutoTokenizer.from_pretrained("tokenizer/")

class PredictionRequest(BaseModel):
    texts: List[str]
    batch_size: int = 32

class PredictionResponse(BaseModel):
    predictions: List[str]
    probabilities: List[List[float]]

@app.post("/predict", response_model=PredictionResponse)
async def predict(request: PredictionRequest):
    try:
        predictions = []
        probabilities = []

        for i in range(0, len(request.texts), request.batch_size):
            batch = request.texts[i:i + request.batch_size]

            inputs = tokenizer(
                batch,
                padding=True,
                truncation=True,
                max_length=512,
                return_tensors="pt",
            )

            with torch.no_grad():
                outputs = model(**inputs)
                probs = torch.softmax(outputs.logits, dim=-1)
                preds = probs.argmax(dim=-1)

            predictions.extend([LABELS[p] for p in preds.tolist()])
            probabilities.extend(probs.tolist())

        return PredictionResponse(
            predictions=predictions,
            probabilities=probabilities,
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/health")
async def health():
    return {"status": "healthy", "model_loaded": model is not None}
```

### TorchServe
```python
# model_handler.py
from ts.torch_handler.base_handler import BaseHandler
import torch
import json

class TextClassificationHandler(BaseHandler):
    def __init__(self):
        super().__init__()
        self.initialized = False

    def initialize(self, context):
        self.manifest = context.manifest
        model_dir = context.system_properties.get("model_dir")

        # Load model
        model_path = f"{model_dir}/model.pt"
        self.model = torch.load(model_path)
        self.model.eval()

        # Load tokenizer
        self.tokenizer = AutoTokenizer.from_pretrained(model_dir)

        self.initialized = True

    def preprocess(self, data):
        texts = [d.get("data") or d.get("body") for d in data]
        inputs = self.tokenizer(
            texts,
            padding=True,
            truncation=True,
            max_length=512,
            return_tensors="pt",
        )
        return inputs

    def inference(self, inputs):
        with torch.no_grad():
            outputs = self.model(**inputs)
            probs = torch.softmax(outputs.logits, dim=-1)
        return probs

    def postprocess(self, outputs):
        predictions = outputs.argmax(dim=-1).tolist()
        probabilities = outputs.tolist()
        return [
            {"prediction": LABELS[p], "probabilities": prob}
            for p, prob in zip(predictions, probabilities)
        ]
```

```bash
# Package model
torch-model-archiver \
    --model-name text-classifier \
    --version 1.0 \
    --model-file model.py \
    --serialized-file model.pt \
    --handler model_handler.py \
    --extra-files "tokenizer/,config.json" \
    --export-path model_store

# Start server
torchserve \
    --start \
    --model-store model_store \
    --models text-classifier=text-classifier.mar \
    --ncs
```

### NVIDIA Triton
```python
# model.py for Triton Python backend
import triton_python_backend_utils as pb_utils
import numpy as np
import torch
from transformers import AutoTokenizer, AutoModel

class TritonPythonModel:
    def initialize(self, args):
        self.model = AutoModel.from_pretrained("model/")
        self.tokenizer = AutoTokenizer.from_pretrained("model/")
        self.model.eval()

    def execute(self, requests):
        responses = []

        for request in requests:
            input_tensor = pb_utils.get_input_tensor_by_name(request, "INPUT")
            texts = [s.decode() for s in input_tensor.as_numpy()]

            inputs = self.tokenizer(
                texts,
                padding=True,
                truncation=True,
                return_tensors="pt",
            )

            with torch.no_grad():
                outputs = self.model(**inputs)
                embeddings = outputs.last_hidden_state[:, 0, :].numpy()

            output_tensor = pb_utils.Tensor("OUTPUT", embeddings)
            responses.append(pb_utils.InferenceResponse([output_tensor]))

        return responses

    def finalize(self):
        pass
```

```
# Triton model repository structure
model_repository/
└── text_classifier/
    ├── config.pbtxt
    ├── 1/
    │   └── model.py
    └── tokenizer/
```

## Model Optimization

### Quantization
```python
import torch
from torch.quantization import quantize_dynamic, get_default_qconfig

# Dynamic quantization (easiest)
quantized_model = quantize_dynamic(
    model,
    {torch.nn.Linear, torch.nn.LSTM},
    dtype=torch.qint8,
)

# Static quantization
model.qconfig = get_default_qconfig("fbgemm")
model_prepared = torch.quantization.prepare(model)

# Calibrate with representative data
for batch in calibration_loader:
    model_prepared(batch)

model_quantized = torch.quantization.convert(model_prepared)

# Compare sizes
original_size = os.path.getsize("model.pt") / 1e6
quantized_size = os.path.getsize("model_quantized.pt") / 1e6
print(f"Size reduction: {original_size:.1f}MB -> {quantized_size:.1f}MB")
```

### ONNX Export and Optimization
```python
import torch.onnx
import onnx
from onnxruntime.quantization import quantize_dynamic, QuantType

# Export to ONNX
dummy_input = {
    "input_ids": torch.randint(0, 1000, (1, 128)),
    "attention_mask": torch.ones(1, 128, dtype=torch.long),
}

torch.onnx.export(
    model,
    (dummy_input,),
    "model.onnx",
    input_names=["input_ids", "attention_mask"],
    output_names=["logits"],
    dynamic_axes={
        "input_ids": {0: "batch_size", 1: "seq_length"},
        "attention_mask": {0: "batch_size", 1: "seq_length"},
        "logits": {0: "batch_size"},
    },
    opset_version=14,
)

# Optimize ONNX model
from onnxruntime.transformers import optimizer
optimized_model = optimizer.optimize_model(
    "model.onnx",
    model_type="bert",
    num_heads=8,
    hidden_size=256,
)
optimized_model.save_model_to_file("model_optimized.onnx")

# Quantize ONNX
quantize_dynamic(
    "model_optimized.onnx",
    "model_quantized.onnx",
    weight_type=QuantType.QInt8,
)
```

### ONNX Runtime Inference
```python
import onnxruntime as ort
import numpy as np

# Create session
session = ort.InferenceSession(
    "model_quantized.onnx",
    providers=["CUDAExecutionProvider", "CPUExecutionProvider"],
)

# Inference
inputs = {
    "input_ids": input_ids.numpy(),
    "attention_mask": attention_mask.numpy(),
}
outputs = session.run(None, inputs)
logits = outputs[0]
```

## Docker Deployment

### Dockerfile
```dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy model and code
COPY model/ ./model/
COPY src/ ./src/

# Create non-root user
RUN useradd -m appuser && chown -R appuser:appuser /app
USER appuser

EXPOSE 8000

CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### GPU Dockerfile
```dockerfile
FROM nvidia/cuda:12.1-runtime-ubuntu22.04

RUN apt-get update && apt-get install -y \
    python3.11 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

COPY model/ ./model/
COPY src/ ./src/

EXPOSE 8000

CMD ["python3", "-m", "uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

## Monitoring

### Prometheus Metrics
```python
from prometheus_client import Counter, Histogram, Gauge, generate_latest
from fastapi import Response

# Metrics
PREDICTION_COUNT = Counter(
    "model_predictions_total",
    "Total predictions",
    ["model_name", "prediction_class"],
)

PREDICTION_LATENCY = Histogram(
    "model_prediction_latency_seconds",
    "Prediction latency",
    ["model_name"],
    buckets=[0.01, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5],
)

MODEL_CONFIDENCE = Histogram(
    "model_prediction_confidence",
    "Prediction confidence distribution",
    ["model_name"],
    buckets=[0.5, 0.6, 0.7, 0.8, 0.9, 0.95, 0.99],
)

BATCH_SIZE = Histogram(
    "model_batch_size",
    "Batch size distribution",
    ["model_name"],
)

@app.post("/predict")
async def predict(request: PredictionRequest):
    start_time = time.time()

    # Make prediction
    predictions, confidences = model.predict(request.texts)

    # Record metrics
    latency = time.time() - start_time
    PREDICTION_LATENCY.labels(model_name="text-classifier").observe(latency)
    BATCH_SIZE.labels(model_name="text-classifier").observe(len(request.texts))

    for pred, conf in zip(predictions, confidences):
        PREDICTION_COUNT.labels(
            model_name="text-classifier",
            prediction_class=pred,
        ).inc()
        MODEL_CONFIDENCE.labels(model_name="text-classifier").observe(conf)

    return {"predictions": predictions, "confidences": confidences}

@app.get("/metrics")
async def metrics():
    return Response(generate_latest(), media_type="text/plain")
```

### Data Drift Detection
```python
from evidently import ColumnMapping
from evidently.report import Report
from evidently.metric_preset import DataDriftPreset
import pandas as pd

def detect_drift(
    reference_data: pd.DataFrame,
    current_data: pd.DataFrame,
    column_mapping: ColumnMapping,
) -> dict:
    report = Report(metrics=[DataDriftPreset()])
    report.run(
        reference_data=reference_data,
        current_data=current_data,
        column_mapping=column_mapping,
    )

    result = report.as_dict()
    return {
        "dataset_drift": result["metrics"][0]["result"]["dataset_drift"],
        "drift_share": result["metrics"][0]["result"]["share_of_drifted_columns"],
        "drifted_columns": [
            col for col, drift in result["metrics"][0]["result"]["drift_by_columns"].items()
            if drift["drift_detected"]
        ],
    }
```

## A/B Testing

```python
import random
from typing import Literal

class ModelRouter:
    def __init__(self, models: dict, weights: dict):
        self.models = models
        self.weights = weights
        self.total_weight = sum(weights.values())

    def route(self, request_id: str) -> str:
        # Deterministic routing based on request ID
        hash_value = int(hashlib.md5(request_id.encode()).hexdigest(), 16)
        threshold = hash_value % self.total_weight

        cumulative = 0
        for model_name, weight in self.weights.items():
            cumulative += weight
            if threshold < cumulative:
                return model_name

        return list(self.models.keys())[0]

    def predict(self, request_id: str, inputs):
        model_name = self.route(request_id)
        model = self.models[model_name]
        return model_name, model.predict(inputs)

# Usage
router = ModelRouter(
    models={"model_a": model_a, "model_b": model_b},
    weights={"model_a": 90, "model_b": 10},  # 90/10 split
)
```

## Deployment Checklist

### Pre-deployment
- [ ] Model tested on production-like data
- [ ] Latency benchmarked
- [ ] Memory usage profiled
- [ ] Input validation implemented
- [ ] Error handling complete

### Deployment
- [ ] Health check endpoint
- [ ] Metrics endpoint
- [ ] Logging configured
- [ ] Resource limits set
- [ ] Autoscaling configured

### Post-deployment
- [ ] Monitoring dashboards
- [ ] Alerting rules
- [ ] Rollback plan
- [ ] A/B testing setup
- [ ] Drift detection enabled

## Remember

- Optimize for latency and throughput
- Monitor model performance continuously
- Plan for model updates
- Handle failures gracefully
- Document deployment procedures
- Test rollback processes
