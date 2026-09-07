"""Strict parser and explicit selector handling for the Meshy model manifest."""
from __future__ import annotations

import csv
from dataclasses import dataclass
from pathlib import Path


class ManifestError(ValueError):
    pass


@dataclass(frozen=True)
class AssetJob:
    asset_id: str
    source: Path
    destination: Path
    strategy: str
    family: str


REQUIRED_COLUMNS = {"mesh_output", "strategy", "families", "source_images"}


def load_jobs(repo_root: Path, manifest_path: Path) -> dict[str, AssetJob]:
    repo_root = repo_root.resolve()
    source_root = (repo_root / "production/meshy_assets").resolve()
    destination_root = (repo_root / "assets/models").resolve()
    jobs: dict[str, AssetJob] = {}
    try:
        handle = manifest_path.open("r", encoding="utf-8-sig", newline="")
    except OSError as error:
        raise ManifestError(f"cannot read manifest: {error}") from error
    with handle:
        reader = csv.DictReader(handle)
        if not reader.fieldnames or not REQUIRED_COLUMNS.issubset(reader.fieldnames):
            raise ManifestError(f"manifest requires columns: {', '.join(sorted(REQUIRED_COLUMNS))}")
        for line_number, row in enumerate(reader, start=2):
            asset_id = (row.get("mesh_output") or "").strip().replace("\\", "/")
            strategy = (row.get("strategy") or "").strip()
            family = (row.get("families") or "").strip()
            sources = [item.strip() for item in (row.get("source_images") or "").split("|") if item.strip()]
            if not asset_id or not strategy or not family or not sources:
                raise ManifestError(f"incomplete manifest row {line_number}")
            if asset_id in jobs:
                raise ManifestError(f"duplicate asset identifier: {asset_id}")
            if strategy == "2d_only_not_for_meshy":
                raise ManifestError(f"asset is marked 2D-only: {asset_id}")
            output_path = Path(asset_id)
            if output_path.is_absolute():
                raise ManifestError(f"absolute destination is forbidden: {asset_id}")
            destination = (repo_root / "assets" / output_path).resolve()
            if not _is_beneath(destination, destination_root):
                raise ManifestError(f"destination must stay beneath assets/models: {asset_id}")
            source_path = Path(sources[0])
            if source_path.is_absolute():
                raise ManifestError(f"absolute source is forbidden: {sources[0]}")
            source = (source_root / source_path).resolve()
            if not _is_beneath(source, source_root):
                raise ManifestError(f"source escapes production/meshy_assets: {sources[0]}")
            if not source.is_file():
                raise ManifestError(f"missing source image: {sources[0]}")
            jobs[asset_id] = AssetJob(asset_id, source, destination, strategy, family)
    return jobs


def select_jobs(jobs: dict[str, AssetJob], selectors: list[str]) -> list[AssetJob]:
    if not selectors:
        raise ManifestError("at least one explicit asset selector is required")
    selected: list[AssetJob] = []
    for selector in selectors:
        normalized = selector.strip().replace("\\", "/")
        matches = [
            job
            for job in jobs.values()
            if normalized in (job.asset_id, job.family, _relative_destination(job))
        ]
        if not matches:
            raise ManifestError(f"unknown asset selector: {selector}")
        for job in matches:
            if job not in selected:
                selected.append(job)
    return selected


def _relative_destination(job: AssetJob) -> str:
    parts = job.destination.parts
    try:
        index = [part.lower() for part in parts].index("assets")
    except ValueError:
        return job.destination.as_posix()
    return Path(*parts[index:]).as_posix()


def _is_beneath(path: Path, root: Path) -> bool:
    try:
        path.relative_to(root)
        return True
    except ValueError:
        return False
