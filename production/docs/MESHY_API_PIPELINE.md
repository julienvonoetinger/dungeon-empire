# Safe Meshy API Pipeline

The manifest-driven pipeline is the supported way to turn approved source images into runtime GLBs. It is dry-run by default: without `--execute`, it does not read `MESHY_API_KEY`, contact Meshy, create a journal, change a model, or consume credits.

## Credentials

Copy `.env.example` to the ignored local file `.env`, then set `MESHY_API_KEY` there. Never pass the key on the command line or commit `.env`.

## Select and preview one job

Selectors are mandatory and must exactly match an asset ID, destination, or family from `production/manifests/meshy_model_manifest.csv`.

```powershell
python tools/meshy_pipeline.py models/environment/wall_straight_controlled.glb
```

This command is free and networkless. Review the printed source, destination, model and polycount before execution.

## Execute, overwrite, or deliberately resubmit

```powershell
python tools/meshy_pipeline.py models/environment/wall_straight_controlled.glb --execute
python tools/meshy_pipeline.py models/environment/wall_straight_controlled.glb --execute --force
python tools/meshy_pipeline.py models/environment/wall_straight_controlled.glb --execute --resubmit
```

Commands containing `--execute` may consume Meshy credits. Existing GLBs are protected unless `--force` is present. A matching unfinished task is resumed automatically; `--resubmit` deliberately creates a new paid task instead.

Optional generation parameters are `--polycount N` and `--texture-prompt TEXT`. They participate in the resume hash, so changing either prevents an incompatible task from being resumed.

## Journal and recovery

Execution state is stored locally in `.meshy/tasks.json`. The file is ignored by Git and contains task identifiers, hashes, state, progress, credits, timestamps, validation metadata, and sanitized errors. It never stores image data, authorization headers, API keys, full Meshy responses, or signed download URLs.

After interruption, run the same selector and parameters with `--execute`; the matching `submitted` or `processing` task will resume. Inspect `.meshy/tasks.json` when diagnosing a failure. Do not delete it before retrying: without the recorded task ID, the pipeline cannot distinguish an interrupted submission from a task that was never submitted, which can cause duplicate credit use.

On success, the download is written to a temporary sibling, validated as GLB 2.0 with non-empty mesh data, and only then installed below `assets/models`. An invalid or truncated download is deleted while an existing destination remains untouched.
