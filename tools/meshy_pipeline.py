#!/usr/bin/env python3
"""Guarded, manifest-driven Meshy image-to-3D pipeline."""
from __future__ import annotations

import argparse
import base64
import hashlib
import json
import mimetypes
import os
import sys
import time
from dataclasses import asdict, replace
from datetime import datetime, timezone
from pathlib import Path
from typing import Callable

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools.meshy.client import MeshyClient, MeshyError
from tools.meshy.glb import install_download
from tools.meshy.journal import TaskJournal, TaskRecord, sanitize
from tools.meshy.manifest import AssetJob, ManifestError, load_jobs, select_jobs

ENDPOINT = "https://api.meshy.ai/openapi/v1/image-to-3d"
AI_MODEL = "meshy-t2"
MODEL_TYPE = "smart-topology"


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Safely generate selected manifest assets through Meshy")
    parser.add_argument("selectors", nargs="+", metavar="SELECTOR", help="Exact asset id, destination, or family")
    parser.add_argument("--execute", action="store_true", help="Submit/resume paid Meshy tasks")
    parser.add_argument("--force", action="store_true", help="Allow replacement of an existing destination GLB")
    parser.add_argument("--resubmit", action="store_true", help="Submit a new task instead of resuming a matching task")
    parser.add_argument("--polycount", type=int, default=10000)
    parser.add_argument("--texture-prompt", default="")
    return parser.parse_args(argv)


def hashes_for_job(job: AssetJob, polycount: int, texture_prompt: str) -> tuple[str, str]:
    source_hash = hashlib.sha256(job.source.read_bytes()).hexdigest()
    parameters = {
        "ai_model": AI_MODEL,
        "enable_pbr": True,
        "model_type": MODEL_TYPE,
        "origin_at": "bottom",
        "should_texture": True,
        "strategy": job.strategy,
        "target_formats": ["glb"],
        "target_polycount": polycount,
        "texture_prompt": texture_prompt,
    }
    encoded = json.dumps(parameters, sort_keys=True, separators=(",", ":")).encode("utf-8")
    return source_hash, hashlib.sha256(encoded).hexdigest()


def run(
    argv: list[str],
    *,
    repo_root: Path = ROOT,
    client_factory: Callable[[], MeshyClient] | None = None,
    sleep_fn: Callable[[float], None] = time.sleep,
) -> int:
    args = parse_args(argv)
    repo_root = repo_root.resolve()
    manifest_path = repo_root / "production/manifests/meshy_model_manifest.csv"
    try:
        jobs = select_jobs(load_jobs(repo_root, manifest_path), args.selectors)
    except ManifestError as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 1
    if args.polycount <= 0:
        print("ERROR: --polycount must be positive", file=sys.stderr)
        return 1
    for job in jobs:
        print(
            f"{'EXECUTE' if args.execute else 'DRY-RUN'} {job.asset_id} | "
            f"source={job.source.relative_to(repo_root)} | destination={job.destination.relative_to(repo_root)} | "
            f"model={AI_MODEL} | polycount={args.polycount}"
        )
    if not args.execute:
        print("Dry-run only: no API key read, no network request, no credits consumed.")
        return 0
    blocked = [job for job in jobs if job.destination.exists() and not args.force]
    if blocked:
        for job in blocked:
            print(f"ERROR: destination exists; pass --force to replace: {job.destination}", file=sys.stderr)
        return 1
    factory = client_factory or make_client
    try:
        client = factory()
    except Exception as error:
        print(f"ERROR: {sanitize(str(error))}", file=sys.stderr)
        return 1
    journal = TaskJournal(repo_root / ".meshy/tasks.json")
    failures = 0
    for job in jobs:
        try:
            _execute_job(job, args, client, journal, repo_root, sleep_fn)
        except Exception as error:
            failures += 1
            print(f"ERROR {job.asset_id}: {sanitize(str(error))}", file=sys.stderr)
    return 1 if failures else 0


def _execute_job(job, args, client, journal, repo_root, sleep_fn):
    source_hash, parameter_hash = hashes_for_job(job, args.polycount, args.texture_prompt)
    record = None if args.resubmit else journal.find_resumable(job.asset_id, source_hash, parameter_hash)
    now = _timestamp()
    if record is None:
        body = _request_body(job, args.polycount, args.texture_prompt)
        created = client.request("POST", ENDPOINT, body)
        task_id = str(created.get("result") or "")
        if not task_id:
            raise MeshyError("invalid_response", "Meshy submission returned no task id")
        record = TaskRecord(
            job.asset_id,
            source_hash,
            parameter_hash,
            task_id,
            job.destination.relative_to(repo_root).as_posix(),
            "submitted",
            0,
            None,
            now,
            now,
        )
        journal.upsert(record)
        print(f"submitted {job.asset_id} task={task_id}")
    else:
        print(f"resuming {job.asset_id} task={record.task_id}")
    while True:
        task = client.get_task(ENDPOINT, record.task_id)
        status = str(task.get("status") or "").upper()
        progress = task.get("progress")
        credits = task.get("consumed_credits", record.credits)
        if status == "SUCCEEDED":
            model_url = (task.get("model_urls") or {}).get("glb")
            if not model_url:
                raise MeshyError("invalid_response", "successful Meshy task returned no GLB URL")
            info = install_download(client, model_url, job.destination, args.force)
            record = replace(
                record,
                state="validated",
                progress=100,
                credits=credits,
                updated_at=_timestamp(),
                validation=asdict(info),
                error="",
            )
            journal.upsert(record)
            print(f"validated {job.destination.relative_to(repo_root)}")
            return
        if status in {"FAILED", "CANCELED"}:
            detail = task.get("task_error") or f"Meshy task {status.lower()}"
            record = replace(
                record,
                state=status.lower(),
                progress=progress,
                credits=credits,
                updated_at=_timestamp(),
                error=sanitize(json.dumps(detail, ensure_ascii=False) if not isinstance(detail, str) else detail),
            )
            journal.upsert(record)
            raise MeshyError("http", record.error or f"Meshy task {status.lower()}")
        record = replace(record, state="processing", progress=progress, credits=credits, updated_at=_timestamp())
        journal.upsert(record)
        print(f"processing {job.asset_id} progress={progress}")
        sleep_fn(5)


def _request_body(job: AssetJob, polycount: int, texture_prompt: str) -> dict:
    mime = mimetypes.guess_type(job.source.name)[0] or "image/png"
    image = base64.b64encode(job.source.read_bytes()).decode("ascii")
    body = {
        "image_url": f"data:{mime};base64,{image}",
        "model_type": MODEL_TYPE,
        "ai_model": AI_MODEL,
        "target_polycount": polycount,
        "should_texture": True,
        "enable_pbr": True,
        "target_formats": ["glb"],
        "origin_at": "bottom",
    }
    if texture_prompt:
        body["texture_prompt"] = texture_prompt
    return body


def make_client() -> MeshyClient:
    _load_env(ROOT / ".env")
    key = os.environ.get("MESHY_API_KEY", "").strip()
    if not key:
        raise RuntimeError("MESHY_API_KEY missing. Put it in .env (see .env.example).")
    return MeshyClient(key)


def _load_env(path: Path) -> None:
    if not path.is_file():
        return
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        os.environ.setdefault(key.strip(), value.strip().strip('"').strip("'"))


def _timestamp() -> str:
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


if __name__ == "__main__":
    raise SystemExit(run(sys.argv[1:]))
