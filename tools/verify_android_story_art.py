"""Check that the APK ships each prologue painting once, in its original encoding."""

import sys
from pathlib import Path
from zipfile import ZipFile


def verify(apk: Path) -> None:
    root = Path(__file__).resolve().parents[1]
    paintings = sorted((root / "assets/game/introduction").glob("prologue-*.webp"))
    if not paintings:
        raise ValueError("No prologue paintings found")
    with ZipFile(apk) as archive:
        names = set(archive.namelist())
        for painting in paintings:
            raw = "assets/" + painting.relative_to(root).as_posix()
            if raw not in names or archive.read(raw) != painting.read_bytes():
                raise ValueError(f"{painting.name} is missing or was re-encoded")
            prefix = "assets/.godot/imported/" + painting.name + "-"
            if any(name.startswith(prefix) for name in names):
                raise ValueError(f"{painting.name} also has an imported copy")
    print(f"{len(paintings)} original prologue paintings verified in {apk.name}")


if __name__ == "__main__":
    verify(Path(sys.argv[1]))
