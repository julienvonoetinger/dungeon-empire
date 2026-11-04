from pathlib import Path
from PIL import Image

source = Path(__file__).resolve().parent
target = source.parents[3] / "assets/game/introduction"
for scene in ("village", "stone", "veil"):
    for suffix in ("", "-portrait"):
        name = scene + suffix
        with Image.open(source / f"{name}.png") as image:
            image.thumbnail((1200, 1200), Image.Resampling.LANCZOS)
            image.convert("RGB").save(target / f"prologue-{name}.webp", quality=83, method=6)
