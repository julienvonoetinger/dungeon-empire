"""Pack the eight whole-model poses per direction on the messenger's 256px grid."""
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[4]
for direction in ("n", "ne", "e", "se", "s", "sw", "w", "nw"):
    atlas = Image.new("RGBA", (1024, 512))
    for frame in range(8):
        with Image.open(root / f"artifacts/oculin-trap-hurt/frames/{direction}/{frame:02}.png") as pose:
            assert pose.size == (256, 256)
            box = pose.getchannel("A").getbbox()
            assert box and min(box[:2]) > 0 and max(box[2:]) < 256, (direction, frame, box)
            atlas.paste(pose, (frame % 4 * 256, frame // 4 * 256))
    atlas.save(root / f"assets/game/introduction/messengers/hurt-{direction}.png")
