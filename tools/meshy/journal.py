"""Atomic, sanitized persistence for resumable Meshy tasks."""
from __future__ import annotations

import json
import os
import re
from dataclasses import asdict, dataclass, field
from pathlib import Path


@dataclass(frozen=True)
class TaskRecord:
    asset_id: str
    source_hash: str
    parameter_hash: str
    task_id: str
    destination: str
    state: str
    progress: int | float | None
    credits: int | float | None
    created_at: str
    updated_at: str
    error: str = ""
    validation: dict = field(default_factory=dict)


class TaskJournal:
    def __init__(self, path: Path):
        self.path = path
        self.records = self._load()

    def find_resumable(self, asset_id: str, source_hash: str, parameter_hash: str) -> TaskRecord | None:
        for record in reversed(self.records):
            if (
                record.asset_id == asset_id
                and record.source_hash == source_hash
                and record.parameter_hash == parameter_hash
                and record.state in {"submitted", "processing"}
            ):
                return record
        return None

    def upsert(self, record: TaskRecord) -> None:
        safe_record = TaskRecord(**{**asdict(record), "error": sanitize(record.error)})
        for index, current in enumerate(self.records):
            if (
                current.asset_id == safe_record.asset_id
                and current.source_hash == safe_record.source_hash
                and current.parameter_hash == safe_record.parameter_hash
            ):
                self.records[index] = safe_record
                break
        else:
            self.records.append(safe_record)
        self._write()

    def _load(self) -> list[TaskRecord]:
        if not self.path.is_file():
            return []
        payload = json.loads(self.path.read_text(encoding="utf-8"))
        return [TaskRecord(**item) for item in payload.get("tasks", [])]

    def _write(self) -> None:
        self.path.parent.mkdir(parents=True, exist_ok=True)
        temporary = self.path.with_suffix(self.path.suffix + ".tmp")
        payload = {"version": 1, "tasks": [asdict(record) for record in self.records]}
        with temporary.open("w", encoding="utf-8", newline="\n") as handle:
            json.dump(payload, handle, ensure_ascii=False, indent=2, sort_keys=True)
            handle.write("\n")
            handle.flush()
            os.fsync(handle.fileno())
        temporary.replace(self.path)


def sanitize(text: str) -> str:
    value = str(text or "")
    value = re.sub(r"msy_[A-Za-z0-9._-]+", "[REDACTED_KEY]", value)
    value = re.sub(r"(?:Authorization:\s*)?Bearer\s+\S+", "[REDACTED_AUTH]", value, flags=re.IGNORECASE)
    data_uri_pattern = "data:" + r"image/[^;\s]+;base64,[A-Za-z0-9+/=]+"
    value = re.sub(data_uri_pattern, "[REDACTED_IMAGE]", value, flags=re.IGNORECASE)
    value = re.sub(r"(https?://[^\s?]+)\?[^\s]+", r"\1?[REDACTED_QUERY]", value)
    return value
