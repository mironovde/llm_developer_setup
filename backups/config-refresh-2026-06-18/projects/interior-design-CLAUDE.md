<!-- GSD:project-start source:PROJECT.md -->
## Project

**Interior Design — Floor Plan Parser & Layout Generator**

Система автоматического создания интерьерных планировок для жилых квартир из растровых планов (PNG/JPG). На вход поступает фото/скан плана квартиры → парсер извлекает контур, стены, окна, двери, мокрые точки → solver размещает мебель → renderer создаёт 2D визуализацию с предложением планировки.

Сейчас работает на одном тестовом плане (apt_713). Этот milestone фокусируется на **обобщении парсера** для надёжной работы на разных типах планировок российского и западного рынка.

**Core Value:** **Парсер должен правильно определять стены, контур квартиры и мокрые точки на ЛЮБОЙ входной схеме**. Если парсер ошибается — всё остальное (layout, рендер, мебель) работает по ошибочным данным.

### Constraints

- **Tech stack**: Python + OpenCV; разрешены ML модели (PyTorch / TensorFlow / ONNX runtime)
- **CPU-only**: целевой запуск без GPU (Mac/Linux), модели должны быть CPU-friendly или quantized
- **Latency**: парсинг одного плана < 30 секунд на M-series Mac (для интерактивного UX в будущем)
- **Determinism**: одна и та же картинка → одинаковый результат (для тестов и regression detection)
- **Dependencies**: предпочитаем malнький pip footprint; крупные ML фреймворки только если без них не обойтись
- **No network at parse time**: парсер работает offline; модели pre-downloaded
<!-- GSD:project-end -->

<!-- GSD:stack-start source:research/STACK.md -->
## Technology Stack

## TL;DR (prescriptive)
## Recommended Stack
### Core ML Technologies
| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| **PyTorch** | 2.9.x (stable on macOS arm64; 2.11 is current but check MPS regressions) | Training + reference inference | Standard. Native arm64 wheels. MPS backend optional for M-series; CPU works without GPU. PyTorch 1.x (used in original CubiCasa repo) is EOL — port forward. |
| **ONNX Runtime** | 1.26.x | Production CPU inference | 2-5× faster than raw PyTorch on CPU for segmentation models. Stable arm64 macOS wheels. Deterministic. Removes PyTorch as a runtime dep once exported. |
| **segmentation-models-pytorch (smp)** | 0.5.0 | UNet/UNet++/DeepLabV3+ with 500+ encoders | Battle-tested. Lets us swap encoders (MobileNetV3-Small for speed, ResNet-34 for accuracy) without rewriting heads. Trains UNet from scratch in ~1 hour on ~50 annotated plans (M-series CPU). |
| **CubiCasa5K reference model** | repo HEAD (Apr-2019 paper; weights still hosted) | Starting backbone for wall/door/window/room segmentation | Most-cited public floor-plan model. Multi-task: walls + room boundaries + room types + icons in one pass. 5K real plans → reasonable generalization. **CC-BY-NC license.** Architecture is hourglass-style multi-task; we'll port to current PyTorch. |
| **OpenCV** | 4.10+ (already in codebase) | Pre-processing + classical vectorization step | Already used. Keep for Hough line refinement on top of ML wall mask (snap pixel mask → axis-aligned polylines). |
| **Shapely** | 2.1.x (already in codebase) | Polygon ops on parsed geometry | Already used. Required for buffer/union/clip operations on wall polygons after vectorization. |
| **scikit-image** | 0.26.x | Mask post-processing (skeletonize, label, find_contours) | `skimage.morphology.skeletonize` turns thick wall mask → 1-px centerline → much easier to vectorize. Complements OpenCV. |
| **Albumentations** | 2.0.8 | Image + mask augmentation (rotation, perspective, elastic, brightness) | Faster than imgaug/torchvision/Kornia. Native joint image+mask transforms (rotation applies same way to mask). Required for PARSE-08 (±5° robustness) and CORPUS-02 (4× orientation augmentation). |
### Vectorization & Validation Libraries
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| **NumPy** | ≥1.26, <3 | Tensors, image arrays | Foundation. Pin compatibility with PyTorch + OpenCV — NumPy 2.x is fine with PyTorch ≥2.3 and OpenCV ≥4.9. |
| **Pillow** | ≥10.4 | Image I/O fallback | OpenCV reads in BGR and chokes on some PNGs with alpha; Pillow normalizes. |
| **rasterio** | optional, only if geo-style coordinate transforms needed | — | Skip unless we add geo-anchored plans. |
| **pycocotools** | 2.0.7+ | mAP metrics for object detection (doors/windows as bboxes) | For VAL-01 if we treat doors/windows as detection rather than segmentation. |
| **torchmetrics** | 1.4+ | IoU, Dice, pixel accuracy for wall masks | Standard implementation. Lets us track per-class IoU (wall vs window vs door) without rolling our own. |
| **pydantic** | v2 (already in codebase) | Typed schemas for parsed-floorplan output | Already in codebase. Use for GT annotation schema → JSON. |
### Evaluation Metrics (floor-plan-specific)
| Metric | What it measures | Library |
|--------|-----------------|---------|
| **mIoU per class** | Pixel overlap of predicted wall/door/window mask vs GT | `torchmetrics.JaccardIndex(task="multiclass")` |
| **Junction F1** (from R2V paper) | Wall corner / T-junction precision+recall within tolerance (e.g. 10 px) | Custom — see Raster-to-Vector paper §4 |
| **Room-count accuracy** | Does parsed plan have the same #rooms as GT (after flood-fill on walls)? | Custom — `skimage.measure.label` |
| **Wet-point distance** | Euclidean distance (in cm, post-scale-calibration) between predicted vs GT kitchen/bath centroid. Target ≤ 30 cm (PARSE-07) | Custom — already on the books |
### Development Tools
| Tool | Purpose | Notes |
|------|---------|-------|
| **uv** or pip-tools | Dep lock | Project already on pip — `requirements-ml.txt` separate from `requirements.txt` to avoid forcing PyTorch on users who only run the geometric solver. |
| **Jupyter / IPython** | Mask inspection, augmentation preview | Critical for debugging ML output — `matplotlib` overlay of mask on plan is the fastest feedback loop. |
| **pytest + golden masters** | Regression on the 10-15 reference plans | Snapshot the parsed JSON; diff on every commit. Determinism required (`torch.manual_seed`, ORT `intra_op_num_threads=1` for repro). |
## Installation
# Core ML — additive to existing requirements.txt (OpenCV/Shapely/Pydantic already present)
# CubiCasa5K reference weights — manual download (not on PyPI):
#   git clone https://github.com/CubiCasa/CubiCasa5k.git
#   Download weights link from repo README → place in ./models/cubicasa/
# License reminder: CC-BY-NC 4.0. Internal/research only.
# Optional, only if we choose to use Detectron2 for door/window detection (not recommended — see below)
#   python3 -m pip install 'git+https://github.com/facebookresearch/detectron2.git'
## Alternatives Considered
| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| **CubiCasa5K (UNet-style multi-task)** | **Raster-to-Vector** (art-programmer/FloorplanTransformation) | If you specifically need vector-graph output (junctions + edges as a graph) and can absorb the older Lua/Torch heritage. The repo is from 2018, semi-maintained. Inferior multi-class accuracy vs CubiCasa. |
| **CubiCasa5K** | **Raster-to-Graph (Hu et al., EG 2024)** | If you have a GPU and your project license is GPL-3.0-compatible. R2G is the current SOTA on the CubiCasa5K benchmark — autoregressive transformer producing the graph directly. **CUDA-only** (deformable-attention CUDA kernels, no CPU fallback), Python 3.7 + Torch 1.9.1 lock-in. Too brittle for our CPU-only constraint. |
| **CubiCasa5K** | **DeepFloorplan (zlzeng)** | Don't. TensorFlow 1.10 + Python 2.7, last meaningful commit 2021. Modernizing it is more work than fine-tuning a fresh smp UNet. |
| **CubiCasa5K** | **PolyRoom / RoomFormer** | Different problem. These target **3D scan → 2D floorplan reconstruction** (input = point cloud / panorama), not raster-image parsing. Wrong tool for our input. |
| **segmentation-models-pytorch (UNet)** | **Detectron2 (Mask R-CNN)** | If we treat each room as an *instance* and need separate masks per room. For walls (a single connected class) instance segmentation is overkill. Also: Detectron2 has no PyPI wheels — `pip install detectron2` fails; must compile from source, CUDA-recommended. Heavy footprint, slow on CPU. |
| **segmentation-models-pytorch** | **Ultralytics YOLOv8/YOLO11-seg** | For door + window **detection** specifically (bounding boxes / instance masks of small objects), YOLOv8-seg trained on a few hundred labeled crops works well and is CPU-friendly via ONNX. Reasonable secondary head **alongside** the wall-segmentation UNet — not a replacement. |
| **ONNX Runtime CPU** | **PyTorch MPS (Apple GPU)** | MPS is faster than CPU on M2/M3/M4 (~2-3× for conv-heavy nets) but has known segfaults (LayerNorm crashes reported on M4 with libomp) and non-determinism. Use MPS for *training*; ship CPU/ONNX for *inference*. |
| **ONNX Runtime CPU** | **Apple MLX** | MLX is fastest on Apple Silicon but ecosystem is thin — no out-of-the-box port of CubiCasa5K. Revisit in 12 months. |
| **Albumentations** | **imgaug** | imgaug has better polygon/keypoint transform fidelity (which matters if we annotate GT as polygons, not masks). However imgaug is largely unmaintained since 2020 and 2-3× slower. Stick with Albumentations and convert polygons → masks for training. |
| **Albumentations** | **Kornia** | Kornia runs on GPU/tensor — great in a training loop, but heavier dep tree and CPU augmentation is slower than Albumentations. Use only if we move to MPS training and want differentiable augmentation. |
| **scikit-image skeletonize** | **OpenCV ximgproc.thinning** | Equivalent results; ximgproc lives in `opencv-contrib-python`, which would bloat our deps. scikit-image already pulls its weight elsewhere (label, find_contours). |
## What NOT to Use
| Avoid | Why | Use Instead |
|-------|-----|-------------|
| **DeepFloorplan (zlzeng/DeepFloorplan)** | Python 2.7 + TensorFlow 1.10 + CUDA 9.0 (2018 vintage). Last update July 2021. Migration to modern stack is more work than re-training. GPL-3.0 license additionally locks the project. | CubiCasa5K weights ported to current PyTorch, or smp UNet trained on our small annotated corpus. |
| **Raster-to-Graph (production use)** | GPL-3.0 (copyleft — incompatible if app ever needs to be closed-source). Custom CUDA deformable-attention kernels — no CPU inference path. PyTorch 1.9.1 / CUDA 11.1 lock. | CubiCasa5K-style multi-task UNet. Cite R2G as a reference for the graph-junction loss if helpful. |
| **Detectron2 for wall segmentation** | Mask R-CNN is instance segmentation — walls are one connected blob, not instances. Compile-from-source pain, CUDA-leaning, ~300 MB install. Slow on CPU (3-10 s/image at 1024px). | UNet via smp. Reserve Detectron2 (or YOLO-seg) only if needed for *door/window detection* later. |
| **Raw torchvision augmentation for masks** | `torchvision.transforms.v2` works, but mask transforms are still ergonomically rough. Slower than Albumentations on CPU. | Albumentations. |
| **MMDetection / MMSegmentation** | Heavy framework, config-driven, mostly designed for GPU clusters. Pulls in mmcv (compile from source on macOS arm64 = pain). Overkill for a project that needs ONE model fine-tuned on ~50 examples. | smp + plain PyTorch training loop. ~150 lines of code. |
| **Generic LLM (GPT-4V / Claude) as the parser** | Latency 5-20 s per image, $0.01-0.10 per call, non-deterministic, can't run offline (constraint: "No network at parse time"). | Reserve LLMs for VAL-03 only (visual sanity-check loop, where latency and non-determinism are OK). |
| **`pip install detectron2`** | No PyPI wheels exist (verified 2026-05). The command fails with "No matching distribution". | If you must use it: `pip install 'git+https://github.com/facebookresearch/detectron2.git'` after installing torch first. Or just don't. |
| **PyTorch 2.10/2.11 MPS for inference** | Known segfaults on M4 with LayerNorm + libomp ([HF forum thread](https://discuss.huggingface.co/t/segfault-during-pytorch-transformers-inference-on-apple-silicon-m4-libomp-dylib-crash-on-layernorm/160930), [pytorch/pytorch#156723](https://github.com/pytorch/pytorch/issues/156723)). Non-deterministic between runs. | ONNX Runtime CPU for inference. Use MPS only during *training* with explicit seeding. |
| **TensorFlow 1.x or 2.x** | Whole ecosystem trending PyTorch since 2022. CubiCasa5K weights are PyTorch. No reason to introduce TF. | PyTorch 2.9. |
| **Keras 3 (TF/JAX/PyTorch multi-backend)** | Adds an abstraction layer with no benefit for a small custom model. | Plain PyTorch + smp. |
## Stack Patterns by Variant
- Use CubiCasa5K **weights** directly (CC-BY-NC) — fastest path.
- Fine-tune the last decoder block on our 10-15 Russian-plan corpus → ~3× accuracy gain on PIK/Samolet styles (extrapolated from CubiCasa paper's domain-transfer numbers, MEDIUM confidence).
- Use only the CubiCasa5K **architecture** (architecture is not copyrightable).
- Replace weights with: ImageNet-pretrained encoder (via smp) → train decoder + heads from scratch on our own annotated corpus.
- Expected: need ≥200 annotated plans to match CubiCasa-weight quality. Annotation tool: `labelme` or `CVAT` (both AGPL/MIT — fine for in-house use).
- Quantize UNet to INT8 via `onnxruntime.quantization.quantize_dynamic` — 2-3× CPU speedup, ~1-2% IoU drop. Acceptable.
- Switch encoder from ResNet-34 to MobileNetV3-Small in smp — 4× faster, ~3-5% IoU drop. Acceptable for a first pass.
- Run inference at 768px instead of 1024px (the CubiCasa default) — 1.7× speedup, modest accuracy hit for typical apartment plans.
- Don't re-train from scratch. Fine-tune only the segmentation head (~200 epochs, ~30 min on M2 CPU) with 5-10 examples of the new style + heavy augmentation.
## Version Compatibility
| Package A | Compatible With | Notes |
|-----------|-----------------|-------|
| torch 2.9.x | numpy 1.26 – 2.x | NumPy 2.x supported since torch 2.3. Pin `numpy<3`. |
| torch 2.9.x | onnxruntime 1.26.x | ONNX opset 20 supported; export with `opset_version=17` for max ORT compatibility. |
| segmentation-models-pytorch 0.5.0 | torch ≥2.0 | Drops torch 1.x. 0.5.0 added native HF Hub integration for encoder weights. |
| albumentations 2.0.x | numpy ≥1.24, opencv-python ≥4.9 | 2.0 dropped Python 3.8 support and tightened OpenCV requirement. Verify with `pip check` after install. |
| albumentations 2.0.x | imgaug | Mutually exclusive — both monkey-patch some OpenCV calls. Pick one (Albumentations). |
| onnxruntime 1.26 | macOS arm64 | Native wheels available. `onnxruntime` (CPU) is what we want, NOT `onnxruntime-gpu`. |
| CubiCasa5K weights | torch 2.x | Repo as-published targets torch 1.0 with explicit `torch.load(weights, map_location='cpu')`. Port: load state-dict into a freshly-defined model class (state dict is forward-compatible to torch 2.x for the basic conv/bn/linear layers used). |
| scikit-image 0.25+ | numpy 2.x | OK since 0.23. |
## Sources
- [CubiCasa5K GitHub](https://github.com/CubiCasa/CubiCasa5k) — verified active repo, CC-BY-NC 4.0 license, PyTorch 1.0 baseline.
- [CubiCasa5K LICENSE](https://github.com/CubiCasa/CubiCasa5k/blob/master/LICENSE) — **CC-BY-NC 4.0, non-commercial only**.
- [CubiCasa5K paper (arXiv 1904.01920)](https://arxiv.org/abs/1904.01920) — multi-task architecture details, 5000 annotated plans, 80+ object categories.
- [Raster-to-Vector (art-programmer/FloorplanTransformation)](https://github.com/art-programmer/FloorplanTransformation) — original R2V code, 2018, Lua/Torch + PyTorch port. Defines junction-F1 metric.
- [Raster-to-Graph (SizheHu/Raster-to-Graph)](https://github.com/SizheHu/Raster-to-Graph) — EG 2024, GPL-3.0, CUDA-only, PyTorch 1.9.1. Verified via WebFetch 2026-05-12.
- [DeepFloorplan (zlzeng)](https://github.com/zlzeng/DeepFloorplan) — verified stale: TF 1.10 + Python 2.7, last commit 2021-07. GPL-3.0.
- [RoomFormer (CVPR 2023)](https://github.com/ywyue/RoomFormer) — 3D scan → floorplan, NOT applicable to our raster-image task.
- [PolyRoom (ECCV 2024)](https://github.com/3dv-casia/PolyRoom) — same scope as RoomFormer (scan-based), not raster.
- [segmentation-models-pytorch](https://github.com/qubvel-org/segmentation_models.pytorch) — confirmed v0.5.0 on PyPI (2026-05-12), 500+ encoders, MIT.
- [Albumentations](https://albumentations.ai/) — confirmed v2.0.8 on PyPI (2026-05-12), MIT. Geometric transforms (rotation, perspective, elastic) verified.
- [ONNX Runtime](https://onnxruntime.ai/) — confirmed v1.26.0 on PyPI (2026-05-12), native macOS arm64 wheels.
- [PyTorch on Apple Silicon notes](https://docs.pytorch.org/serve/hardware_support/apple_silicon_support.html) + [HF segfault thread](https://discuss.huggingface.co/t/segfault-during-pytorch-transformers-inference-on-apple-silicon-m4-libomp-dylib-crash-on-layernorm/160930) — basis for MPS-for-training-only recommendation.
- [Comprehensive Survey of Floor Plan Recognition (ACM 2025)](https://dl.acm.org/doi/10.1145/3747227.3747250) — current overview of the field; confirms semantic-segmentation + detection hybrid is the dominant pattern.
- PyPI version check (Bash `pip index versions ...`, 2026-05-12) — torch 2.11.0 (using 2.9.x for stability), smp 0.5.0, albumentations 2.0.8, onnxruntime 1.26.0, shapely 2.1.2, scikit-image 0.26.0.
- [detectron2 install issue (verified 2026-05-12)](https://detectron2.readthedocs.io/en/latest/tutorials/install.html) — no PyPI wheels, must build from source.
- HIGH on library versions, licenses, framework versions (verified directly).
- HIGH on "DeepFloorplan is dead" and "Raster-to-Graph is CUDA-locked" (verified via repo README + commit history).
- MEDIUM on "CubiCasa5K weights will generalize to PIK/Samolet/БТИ plans" — no public benchmark on Russian-style plans. Plan to validate empirically in early phases (PARSE-01 corpus build → run CubiCasa as-is → measure mIoU → decide whether to fine-tune).
- LOW on exact CPU latency numbers — "<30 s on M-series" is plausible (CubiCasa-style UNet quantized to INT8 is ~2-5 s/image on M2 in reported benchmarks), but should be measured on our hardware as a Phase-1 deliverable.
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

Conventions not yet established. Will populate as patterns emerge during development.
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

Architecture not yet mapped. Follow existing patterns found in the codebase.
<!-- GSD:architecture-end -->

<!-- GSD:skills-start source:skills/ -->
## Project Skills

No project skills found. Add skills to any of: `.claude/skills/`, `.agents/skills/`, `.cursor/skills/`, `.github/skills/`, or `.codex/skills/` with a `SKILL.md` index file.
<!-- GSD:skills-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd-quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd-debug` for investigation and bug fixing
- `/gsd-execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->



<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run `/gsd-profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
