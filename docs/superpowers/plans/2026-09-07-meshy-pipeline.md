# Meshy Pipeline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Meshy image-to-3D generation manifest-driven, dry-run by default, resumable, secret-safe, and resistant to duplicate credit consumption or corrupted GLB installation.

**Architecture:** Existing Meshy scripts become reusable HTTP/task clients with dependency injection for tests. New focused Python modules own manifest parsing, journal persistence, GLB validation, and CLI orchestration; the standard library is sufficient.

**Tech Stack:** Python 3.11+, `argparse`, `csv`, `json`, `hashlib`, `urllib`, `unittest`, Meshy OpenAPI, GLB 2.0.

**Spec:** `docs/superpowers/specs/2026-09-07-pc-rendering-meshy-pipeline-design.md`

## Global Constraints

- Dry-run is the default and must perform no network request.
- A paid submission requires an explicit `--execute` flag.
- No command selects the entire manifest by omission.
- Existing GLB files are protected unless `--force` is explicitly supplied.
- `.env`, API keys, authorization headers, data URIs, and signed URLs never enter logs or journals.
- UI entries marked `2d_only_not_for_meshy` are rejected.
- Final models are installed only beneath `assets/models` after validation.
- Tests must not contact Meshy or consume credits.

---

### Task 1: Extract a reusable Meshy client

**Files:**
- Create: `tools/meshy/client.py`
- Create: `tools/meshy/__init__.py`
- Modify: `tools/meshy_image_to_3d.py`
- Modify: `tools/meshy_image_to_image.py`
- Create: `tests/python/test_meshy_client.py`

**Interfaces:**
- Produces: `MeshyClient(api_key: str, opener: Callable = urllib.request.urlopen)`
- Produces: `request(method: str, url: str, body: dict | None = None) -> dict`
- Produces: `get_task(endpoint: str, task_id: str) -> dict`
- Produces: `download(url: str, destination: Path) -> None`
- Produces: `MeshyError(kind: str, message: str, status_code: int | None = None)`

- [ ] **Step 1: Write failing client tests**

Use a fake opener to assert JSON encoding, Bearer authorization, response decoding, HTTP failure classification, and that exception messages never contain the supplied API key.

- [ ] **Step 2: Run and verify import failure**

```powershell
python -m unittest tests.python.test_meshy_client -v
```

Expected: failure because `tools.meshy.client` does not exist.

- [ ] **Step 3: Implement the client**

Move request/download behavior into `MeshyClient`. Convert HTTP, timeout, JSON, and transport failures into `MeshyError` with the kinds `auth`, `rate_limit`, `http`, `timeout`, `network`, and `invalid_response`. Sanitize key and Authorization values before formatting errors.

- [ ] **Step 4: Preserve both existing CLIs**

Have the two legacy scripts load `.env`, construct `MeshyClient`, and retain their current arguments and output behavior. Do not change default Meshy model names in this task.

- [ ] **Step 5: Run client tests and both `--help` commands**

Expected: tests pass; help exits 0 without requiring a key.

- [ ] **Step 6: Commit**

```powershell
git add tools/meshy tools/meshy_image_to_3d.py tools/meshy_image_to_image.py tests/python/test_meshy_client.py
git commit -m "Extract reusable Meshy API client"
```

### Task 2: Parse and validate manifest selections

**Files:**
- Create: `tools/meshy/manifest.py`
- Create: `tests/python/test_meshy_manifest.py`

**Interfaces:**
- Produces: immutable `AssetJob(asset_id: str, source: Path, destination: Path, strategy: str, family: str)`
- Produces: `load_jobs(repo_root: Path, manifest_path: Path) -> dict[str, AssetJob]`
- Produces: `select_jobs(jobs: dict[str, AssetJob], selectors: list[str]) -> list[AssetJob]`
- Produces: `ManifestError`

- [ ] **Step 1: Write failing manifest tests**

Use temporary CSV files to cover a valid row, duplicate identifier, missing source image, absolute destination, destination escaping `assets/models`, 2D-only strategy, empty selectors, and an unknown selector.

- [ ] **Step 2: Run and verify import failure**

- [ ] **Step 3: Implement strict parsing**

Resolve source paths relative to `production/meshy_assets` and destination paths relative to the repository. Reject traversal after calling `Path.resolve()`. Treat the existing `meshy_model_manifest.csv` columns as the canonical schema.

- [ ] **Step 4: Implement explicit selection**

Allow exact asset ID, exact destination, or exact family selectors. An empty selector list raises `ManifestError("at least one explicit asset selector is required")`.

- [ ] **Step 5: Run tests**

Expected: every manifest case passes without network access.

- [ ] **Step 6: Commit**

```powershell
git add tools/meshy/manifest.py tests/python/test_meshy_manifest.py
git commit -m "Validate Meshy manifest selections"
```

### Task 3: Add a sanitized resumable task journal

**Files:**
- Create: `tools/meshy/journal.py`
- Create: `tests/python/test_meshy_journal.py`
- Modify: `.gitignore`

**Interfaces:**
- Produces: `TaskRecord` dataclass with asset ID, source hash, parameter hash, task ID, destination, state, progress, credits, timestamps, and sanitized error
- Produces: `TaskJournal(path: Path)`
- Produces: `find_resumable(asset_id: str, source_hash: str, parameter_hash: str) -> TaskRecord | None`
- Produces: `upsert(record: TaskRecord) -> None`

- [ ] **Step 1: Write failing journal tests**

Cover atomic write, reload, matching resume lookup, mismatch rejection, state transition persistence, and removal of strings matching `msy_`, `Bearer `, `data:image/`, and URL query tokens.

- [ ] **Step 2: Run and verify import failure**

- [ ] **Step 3: Implement JSON journal persistence**

Write UTF-8 JSON to a sibling `.tmp` file, flush and close it, then replace the journal atomically. Sanitize all error text before persistence. Store no full API response.

- [ ] **Step 4: Ignore local state**

Add `.meshy/` to `.gitignore`; use `.meshy/tasks.json` as the default journal.

- [ ] **Step 5: Run tests and scan the fixture journal**

Assert none of the forbidden secret patterns occur in serialized output.

- [ ] **Step 6: Commit**

```powershell
git add tools/meshy/journal.py tests/python/test_meshy_journal.py .gitignore
git commit -m "Add resumable sanitized Meshy journal"
```

### Task 4: Validate and atomically install GLB downloads

**Files:**
- Create: `tools/meshy/glb.py`
- Create: `tests/python/test_meshy_glb.py`

**Interfaces:**
- Produces: `validate_glb(path: Path) -> GlbInfo`
- Produces: `install_download(client: MeshyClient, url: str, destination: Path, force: bool) -> GlbInfo`
- Produces: `GlbInfo(version: int, declared_length: int, chunk_count: int, has_json: bool, has_meshes: bool)`
- Produces: `GlbValidationError`

- [ ] **Step 1: Write failing binary-fixture tests**

Construct minimal GLB bytes in memory using `struct.pack`. Cover wrong magic, unsupported version, declared-length mismatch, missing JSON chunk, malformed JSON, JSON without meshes, truncated chunk, existing destination without force, and valid atomic installation.

- [ ] **Step 2: Run and verify import failure**

- [ ] **Step 3: Implement GLB parsing**

Validate the 12-byte header (`b"glTF"`, version 2, exact declared file length), iterate chunk headers safely, decode the JSON chunk, and require a non-empty `meshes` array.

- [ ] **Step 4: Implement atomic installation**

Download to `<destination>.download`, validate it, and use `Path.replace()` only after success. On failure, remove only the known temporary sibling and preserve the destination.

- [ ] **Step 5: Run tests**

Expected: all malformed fixtures are rejected and the valid fixture installs atomically.

- [ ] **Step 6: Commit**

```powershell
git add tools/meshy/glb.py tests/python/test_meshy_glb.py
git commit -m "Validate Meshy GLB downloads"
```

### Task 5: Implement the guarded orchestrator CLI

**Files:**
- Create: `tools/meshy_pipeline.py`
- Create: `tests/python/test_meshy_pipeline.py`

**Interfaces:**
- Consumes: `AssetJob`, `MeshyClient`, `TaskJournal`, `validate_glb`, `install_download`
- Produces CLI: `python tools/meshy_pipeline.py SELECTOR [SELECTOR ...] [--execute] [--force] [--resubmit] [--polycount N] [--texture-prompt TEXT]`
- Produces: exit 0 for successful dry-run or completed validation, non-zero for every rejected/failed job

- [ ] **Step 1: Write failing dry-run tests**

Patch the client factory with a function that fails if called. Assert default invocation prints selected source, destination, model, and polycount, performs zero network calls, and leaves journal and destination absent.

- [ ] **Step 2: Write failing execution-state tests**

Using fake client responses, cover `submitted`, repeated `processing`, `SUCCEEDED`, `FAILED`, `CANCELED`, resume from journal, refusal to duplicate a matching task, explicit `--resubmit`, and overwrite protection.

- [ ] **Step 3: Run and verify missing CLI failure**

- [ ] **Step 4: Implement argument parsing and dry-run**

Require one or more selectors positionally. Validate all jobs before creating a client. Print a stable summary and return without reading the API key unless `--execute` is supplied.

- [ ] **Step 5: Implement submit/resume flow**

Hash source bytes with SHA-256. Hash normalized non-secret parameters. Resume a matching nonterminal record unless `--resubmit` is present. Persist the Meshy task ID immediately after submission, before the first poll.

- [ ] **Step 6: Implement terminal handling**

On success, extract the GLB URL in memory, install it atomically, discard the URL, record validation metadata and credits, and mark `validated`. On failure or cancelation, save a sanitized error and return non-zero.

- [ ] **Step 7: Run all pipeline tests**

```powershell
python -m unittest discover -s tests/python -p 'test_meshy_*.py' -v
```

Expected: all tests pass with fake clients and zero network requests.

- [ ] **Step 8: Commit**

```powershell
git add tools/meshy_pipeline.py tests/python/test_meshy_pipeline.py
git commit -m "Add guarded Meshy generation pipeline"
```

### Task 6: Add operator documentation and end-to-end dry-run verification

**Files:**
- Create: `production/docs/MESHY_API_PIPELINE.md`
- Modify: `production/docs/IMAGE_TO_3D_WORKFLOW.md`
- Modify: `README.md`

**Interfaces:**
- Documents: credential setup, dry-run, explicit execution, resume, force, resubmit, journal location, validation, and recovery

- [ ] **Step 1: Document safe commands**

Include these exact patterns with a real manifest selector but no real key:

```powershell
python tools/meshy_pipeline.py models/environment/wall_straight_controlled.glb
python tools/meshy_pipeline.py models/environment/wall_straight_controlled.glb --execute
python tools/meshy_pipeline.py models/environment/wall_straight_controlled.glb --execute --force
python tools/meshy_pipeline.py models/environment/wall_straight_controlled.glb --execute --resubmit
```

Explain that the first command is free and networkless; the others may consume credits.

- [ ] **Step 2: Document recovery**

Explain how `.meshy/tasks.json` enables resume, how to inspect sanitized state, and why deleting the journal before a retry can cause duplicate submission.

- [ ] **Step 3: Run static secret scans**

```powershell
rg -n "msy_[A-Za-z0-9]+|Authorization: Bearer|data:image/.+;base64" tools tests production/docs README.md
git check-ignore .env .meshy/tasks.json
```

Expected: no real-looking key or serialized data URI; both secret/state paths are ignored.

- [ ] **Step 4: Run a real-manifest dry-run**

Run the first documented command. Expected: one selected job, no API call, no journal creation, no file modification.

- [ ] **Step 5: Run the full network-free Python suite**

Expected: all tests pass and no Meshy credits are consumed.

- [ ] **Step 6: Commit**

```powershell
git add production/docs/MESHY_API_PIPELINE.md production/docs/IMAGE_TO_3D_WORKFLOW.md README.md
git commit -m "Document the safe Meshy workflow"
```

