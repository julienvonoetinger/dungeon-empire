"""Audit or archive superseded introduction experiments; restore their exact bytes.

Default is read-only. --apply creates and verifies a ZIP before removing files.
--restore restores the original paths and refuses to overwrite different bytes.
This is an explicit, reviewed selection, NOT an automatic unused-asset detector.
"""
import argparse
import hashlib
import json
import re
import zipfile
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REVIEW = ROOT / "docs/reference/asset-cleanup/2026-11-04"
ARCHIVE = REVIEW / "superseded-introduction.zip"
MANIFEST = REVIEW / "manifest.json"
DIRECTORIES = {
    "assets/previews/master-meshy": "Former eye and crescent model, replaced by the rigged Wraith",
    "assets/previews/energy-master": "Former procedural eye-vortex prototype",
    "assets/previews/sanctuary-painted": "First detailed sanctuary painting, superseded by the approved coherent style",
    "assets/game/introduction/invocation": "Former illustrated eight-shot cinematic, replaced by the live sanctuary",
    "assets/game/introduction/stairwell": "Rejected first staircase, replaced by stairwell-v2",
}
FILES = [
    "scenes/previews/EnergyMasterPreview.tscn", "scenes/previews/MeshyMasterPreview.tscn",
    "scenes/SanctuaryPainted.tscn",
    "scripts/previews/energy_master.gd", "scripts/previews/energy_master_preview.gd",
    "scripts/previews/meshy_master.gd", "scripts/previews/meshy_master_preview.gd",
    "scripts/game/invocation_film.gd", "scripts/game/invocation_presence.gd",
    "shaders/energy_master.gdshader", "shaders/energy_master_painted.gdshader",
    "shaders/invocation_film.gdshader", "shaders/invocation_coils.gdshader",
    "shaders/invocation_volume.gdshader", "shaders/first_ritual.gdshader",
    "assets/game/introduction/ritual-painted.webp", "assets/game/introduction/ritual-poses.webp",
    "assets/game/introduction/prologue-home.webp",
]
# Reviewed dynamic tooling: these enumerate existing scenes or accept a scene name
# from the caller, rather than requiring the archived previews to exist.
SCENE_ENUMERATORS = {
    "tools/capture_approved_heart.gd", "tools/capture_heart_self_light_integration.gd",
    "tools/capture_isometric_ritual_props.gd", "tools/capture_mobile_kit.gd",
    "tools/capture_wireframe_cells.gd", "tools/export_painted_scene_contexts.gd",
}
for name in ["village", "meeting", "embers", "stone", "veil"]:
    FILES.extend(f"assets/game/introduction/prologue-{name}{suffix}.webp" for suffix in ["", "-portrait"])


def safe_path(relative):
    path = (ROOT / relative).resolve()
    if not path.is_relative_to(ROOT) or path == ROOT:
        raise ValueError(f"Path outside workspace: {relative}")
    return path


def digest(data):
    return hashlib.sha256(data).hexdigest()


def selection():
    selected = {}
    for directory, reason in DIRECTORIES.items():
        for path in safe_path(directory).rglob("*"):
            if path.is_file():
                selected[path.relative_to(ROOT).as_posix()] = reason
    for name in FILES:
        for suffix in ["", ".import", ".uid"]:
            if safe_path(name + suffix).is_file():
                selected[name + suffix] = "Superseded introduction resource and its import/UID sidecars"
    return selected


def active_references(selected):
    """Reject live dependencies, including literal prefixes of concatenated paths.

    Historical docs and generation recipes intentionally remain outside this check.
    They can use --restore to reopen a previous experiment. No import sidecar is
    treated as a consumer of its own source.
    """
    blocked = []
    sources = [ROOT / "project.godot", ROOT / "export_presets.cfg"]
    for folder in ["scripts", "scenes", "shaders", "assets", "tools", "tests"]:
        sources.extend(p for p in (ROOT / folder).rglob("*")
                       if p.suffix in {".gd", ".tscn", ".tres", ".gdshader", ".json"})
    for source in sources:
        relative = source.relative_to(ROOT).as_posix()
        if relative in selected:
            continue
        text = source.read_text(encoding="utf-8-sig")
        for match in re.finditer(r'res://([^\s\x22\x27\)\]<>]+)', text):
            reference = match[1]
            if relative in SCENE_ENUMERATORS and reference in {"scenes", "scenes/", "scenes/%s.tscn"}:
                continue
            if relative == "tools/verify_main_menu.gd" and reference == "assets/game/introduction/prologue-%s%s.webp":
                # Its story_scenes list contains only the ten current Valdorne chapters.
                continue
            # Unresolved templates protect the whole literal prefix.
            prefix = re.split(r'[%${]', reference, maxsplit=1)[0]
            if not any(name.startswith(prefix) for name in selected):
                continue
            literal_file = safe_path(prefix).is_file()
            for name in selected:
                if name == prefix or (not literal_file and name.startswith(prefix)):
                    blocked.append({"consumer": relative, "reference": reference, "asset": name})
    return blocked


def asset_inventory():
    groups = defaultdict(lambda: {"files": 0, "bytes": 0})
    hashes = defaultdict(list)
    files = []
    for path in (ROOT / "assets").rglob("*"):
        if not path.is_file() or path.suffix in {".import", ".uid"}:
            continue
        relative = path.relative_to(ROOT).as_posix()
        group = "/".join(relative.split("/")[:3])
        data = path.read_bytes()
        groups[group]["files"] += 1
        groups[group]["bytes"] += len(data)
        checksum = digest(data)
        hashes[checksum].append(relative)
        files.append({"path": relative, "bytes": len(data), "sha256": checksum})
    return {"groups": dict(sorted(groups.items())),
            "files": sorted(files, key=lambda entry: entry["path"]),
            "identical_files": [names for names in hashes.values() if len(names) > 1]}


def restore():
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    with zipfile.ZipFile(ARCHIVE) as archive:
        # Preflight all entries before writing anything; never extract arbitrary ZIP paths.
        for entry in manifest["files"]:
            path = safe_path(entry["path"])
            data = archive.read(entry["path"])
            if digest(data) != entry["sha256"]:
                raise ValueError(f"Archive checksum mismatch: {path}")
            if path.exists() and digest(path.read_bytes()) != entry["sha256"]:
                raise ValueError(f"Refusing to overwrite changed file: {path}")
        for entry in manifest["files"]:
            path = safe_path(entry["path"])
            if not path.exists():
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(archive.read(entry["path"]))
    print(f"Restored {len(manifest['files'])} files to their original paths.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--apply", action="store_true")
    mode.add_argument("--restore", action="store_true")
    args = parser.parse_args()
    if args.restore:
        restore()
        return
    selected = selection()
    blocked = active_references(selected)
    entries = [{"path": name, "bytes": safe_path(name).stat().st_size,
                "sha256": digest(safe_path(name).read_bytes()), "reason": reason}
               for name, reason in sorted(selected.items())]
    summary = {"files": len(entries), "bytes": sum(e["bytes"] for e in entries),
               "blocked_references": blocked}
    print(json.dumps(summary, ensure_ascii=False, indent=2))
    if blocked:
        raise SystemExit("Live dependency found; nothing archived.")
    if not args.apply:
        return
    if not entries or ARCHIVE.exists() or MANIFEST.exists():
        raise SystemExit("Archive already exists or selection empty; nothing changed.")
    before = asset_inventory()
    REVIEW.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(ARCHIVE, "x", compression=zipfile.ZIP_DEFLATED) as archive:
        for entry in entries:
            archive.write(safe_path(entry["path"]), entry["path"])
    with zipfile.ZipFile(ARCHIVE) as archive:
        for entry in entries:
            if digest(archive.read(entry["path"])) != entry["sha256"]:
                raise ValueError("Archive verification failed; originals retained")
            if digest(safe_path(entry["path"]).read_bytes()) != entry["sha256"]:
                raise ValueError("Source changed during archive; originals retained")
    MANIFEST.write_text(json.dumps({"date": "2026-11-04", "files": entries,
                                   "archive_sha256": digest(ARCHIVE.read_bytes())},
                                  ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    # Only the explicitly inventoried individual files are removed, never a recursive tree.
    for entry in entries:
        safe_path(entry["path"]).unlink()
    for directory in DIRECTORIES:
        path = safe_path(directory)
        if path.is_dir() and not any(path.iterdir()):
            path.rmdir()
    (REVIEW / "inventory.json").write_text(json.dumps({"before": before,
        "after": asset_inventory(), "summary": summary}, indent=2) + "\n", encoding="utf-8")
    print(f"Verified archive: {ARCHIVE.relative_to(ROOT)} ({ARCHIVE.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
