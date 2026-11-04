"""Prepare the in-game sprite from the native transparent ImageGen painting."""
from pathlib import Path
import sys
from PIL import Image

folder = Path(__file__).resolve().parent
with Image.open(Path(sys.argv[1]) if len(sys.argv) > 1 else folder / "sovereign-master.png") as master:
    alpha = master.getchannel("A")
    assert alpha.getextrema()[0] == 0 and alpha.getextrema()[1] >= 250
    left, top, right, bottom = alpha.point(lambda v: 255 if v >= 4 else 0).getbbox()
    sprite = master.crop((left - 4, top - 4, right + 4, bottom + 4))
    sprite.thumbnail((640, 680), Image.Resampling.LANCZOS)
    sprite.save(folder.parents[3] / "assets/game/introduction/dungeon-sovereign.webp", quality=92, method=6)
