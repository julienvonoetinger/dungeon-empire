"""Export the nine invocation paintings for the eight shots."""
from pathlib import Path
from PIL import Image

source = Path(__file__).resolve().parent
target = source.parents[3] / "assets/game/introduction/invocation"
target.mkdir(parents=True, exist_ok=True)
for name in ("wait", "sign", "wake", "lowered", "elder", "manifest", "gaze", "bow", "cavern"):
    with Image.open(source / f"{name}.png") as image:
        plate = image.convert("RGB")
        plate.thumbnail((1200, 1200), Image.Resampling.LANCZOS)
        plate.save(target / f"{name}.webp", quality=87, method=6)
