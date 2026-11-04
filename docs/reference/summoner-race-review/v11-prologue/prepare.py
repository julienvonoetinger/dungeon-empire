from pathlib import Path
from PIL import Image

source = Path(__file__).resolve().parent
target = source.parents[3] / "assets/game/introduction"
masters = {
    "home": source.parent / "v9-prologue/village.png",
    "meeting": source / "meeting.png",
    "meeting-portrait": source / "meeting-portrait.png",
}
for name, master in masters.items():
    with Image.open(master) as image:
        image.thumbnail((1200, 1200), Image.Resampling.LANCZOS)
        image.convert("RGB").save(target / f"prologue-{name}.webp", quality=83, method=6)
