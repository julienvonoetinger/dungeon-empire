"""Exercise archive preflight and safe restoration without touching real assets."""
import importlib.util
import json
import tempfile
import zipfile
from pathlib import Path

repo = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("cleanup", repo / "tools/archive_intro_experiments.py")
tool = importlib.util.module_from_spec(spec)
spec.loader.exec_module(tool)
with tempfile.TemporaryDirectory(prefix="asset-archive-test-", dir=repo / "artifacts") as temporary:
    tool.ROOT = Path(temporary)
    tool.MANIFEST = tool.ROOT / "manifest.json"
    tool.ARCHIVE = tool.ROOT / "test.zip"
    for name in ["project.godot", "export_presets.cfg"]:
        (tool.ROOT / name).write_text("")
    (tool.ROOT / "scripts").mkdir()
    (tool.ROOT / "assets/old").mkdir(parents=True)
    target = "assets/old/art.png"
    (tool.ROOT / target).write_bytes(b"original pixels")
    consumer = tool.ROOT / "scripts/consumer.gd"
    consumer.write_text('const ART = preload("res://assets/old/art.png")')
    assert tool.active_references({target: "test"}), "Exact live dependency must block"
    consumer.write_text('var art = load("res://assets/old/%s.png" % name)')
    assert tool.active_references({target: "test"}), "Dynamic prefix must block"
    consumer.write_text('var art = load("res://assets/current/%s.png" % name)')
    assert not tool.active_references({target: "test"}), "Unrelated directory does not block"
    data = (tool.ROOT / target).read_bytes()
    with zipfile.ZipFile(tool.ARCHIVE, "w") as archive:
        archive.writestr(target, data)
    tool.MANIFEST.write_text(json.dumps({"files": [{"path": target, "sha256": tool.digest(data)}]}))
    (tool.ROOT / target).unlink()
    tool.restore()
    assert (tool.ROOT / target).read_bytes() == data
    tool.restore()  # Matching files are safe and idempotent.
    (tool.ROOT / target).write_bytes(b"new pixels")
    try:
        tool.restore()
        raise AssertionError("Must not overwrite changed files")
    except ValueError:
        pass
    assert (tool.ROOT / target).read_bytes() == b"new pixels"
    try:
        tool.safe_path("../outside")
        raise AssertionError("Must reject paths outside workspace")
    except ValueError:
        pass
print("ASSET_ARCHIVE_CHECK: passed")
