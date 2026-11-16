"""Pack the four full-body renders at the volunteer's existing sprite scale."""
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[4]
for direction in ("ne","se","sw","nw"):
    atlas = Image.new("RGBA",(1024,768))
    for frame in range(11):
        with Image.open(root/f"artifacts/oculin-door-lockpick/frames/{direction}/{frame:02}.png") as pose:
            assert pose.size == (256,256)
            bounds = pose.getchannel("A").getbbox()
            assert bounds and min(bounds[:2]) > 0 and max(bounds[2:]) < 256
            atlas.paste(pose,(frame%4*256,frame//4*256))
    atlas.save(root/f"assets/game/introduction/messengers/lockpick-{direction}.png")
