from pathlib import Path
from PIL import Image
import sys

root = Path(__file__).resolve().parents[4]
angle = sys.argv[1] if len(sys.argv)>1 else "assembly"
folder = "poses" if angle == "assembly" else angle
count, frames, tile, cols = (1,33,384,7) if angle == "elder" else (7,49,128,21)
atlas = Image.new("RGBA", (tile * cols, tile * ((count*frames+cols-1)//cols)))
for actor in range(count):
    for frame in range(frames):
        with Image.open(root / ("artifacts/invocation-iso/%s/%d-%02d.png" % (folder,actor,frame))) as sprite:
            bounds = sprite.getchannel("A").getbbox()
            assert sprite.size == (tile,tile) and bounds and min(bounds[:2]) > 0 and max(bounds[2:]) < tile
            index = actor * frames + frame
            atlas.paste(sprite,(tile * (index % cols), tile * (index // cols)))
atlas.save(root / ("assets/game/introduction/invocation/%s.webp" % ("elder-poses" if angle=="elder" else angle)), quality=93, method=6)
