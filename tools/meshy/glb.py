"""GLB 2.0 validation and atomic installation."""
from __future__ import annotations

import json
import struct
from dataclasses import dataclass
from pathlib import Path

from .client import MeshyClient


JSON_CHUNK = 0x4E4F534A


class GlbValidationError(ValueError):
    pass


@dataclass(frozen=True)
class GlbInfo:
    version: int
    declared_length: int
    chunk_count: int
    has_json: bool
    has_meshes: bool


def validate_glb(path: Path) -> GlbInfo:
    try:
        data = path.read_bytes()
    except OSError as error:
        raise GlbValidationError(f"cannot read GLB: {error}") from error
    if len(data) < 12:
        raise GlbValidationError("GLB header is truncated")
    magic, version, declared_length = struct.unpack_from("<4sII", data, 0)
    if magic != b"glTF":
        raise GlbValidationError("invalid GLB magic")
    if version != 2:
        raise GlbValidationError(f"unsupported GLB version: {version}")
    if declared_length != len(data):
        raise GlbValidationError("GLB declared length does not match file size")
    offset = 12
    chunk_count = 0
    document = None
    while offset < len(data):
        if len(data) - offset < 8:
            raise GlbValidationError("truncated GLB chunk header")
        chunk_length, chunk_type = struct.unpack_from("<II", data, offset)
        offset += 8
        chunk_end = offset + chunk_length
        if chunk_end > len(data):
            raise GlbValidationError("truncated GLB chunk payload")
        payload = data[offset:chunk_end]
        offset = chunk_end
        chunk_count += 1
        if chunk_type == JSON_CHUNK and document is None:
            try:
                document = json.loads(payload.decode("utf-8").rstrip(" \t\r\n\x00"))
            except (UnicodeDecodeError, json.JSONDecodeError) as error:
                raise GlbValidationError(f"malformed GLB JSON chunk: {error}") from error
    if document is None:
        raise GlbValidationError("GLB has no JSON chunk")
    meshes = document.get("meshes") if isinstance(document, dict) else None
    if not isinstance(meshes, list) or not meshes:
        raise GlbValidationError("GLB JSON has no meshes")
    return GlbInfo(version, declared_length, chunk_count, True, True)


def install_download(
    client: MeshyClient,
    url: str,
    destination: Path,
    force: bool,
) -> GlbInfo:
    if destination.exists() and not force:
        raise FileExistsError(f"destination already exists: {destination}")
    destination.parent.mkdir(parents=True, exist_ok=True)
    temporary = destination.with_suffix(destination.suffix + ".download")
    if temporary.exists():
        temporary.unlink()
    try:
        client.download(url, temporary)
        info = validate_glb(temporary)
        temporary.replace(destination)
        return info
    except Exception:
        if temporary.exists():
            temporary.unlink()
        raise
