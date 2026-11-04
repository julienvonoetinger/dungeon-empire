from pathlib import Path
from PIL import Image

# Fixed camera at 1536 px / 14 world units; one crop for the whole timeline
# retains the summoner's foot registration and the trajectory of the rift.
root = Path(__file__).resolve().parents[4]
frames = root / 'artifacts/introduction/sprite-bake'
target = root / 'assets/game/introduction'
crop = (576, 472, 976, 808)
tile = (300, 252)
atlas = Image.new('RGBA', (tile[0]*6, tile[1]*8))
for index in range(46):
    with Image.open(frames / ('frame-%02d.png' % index)) as raw:
        bounds = raw.getchannel('A').getbbox()
        assert bounds and bounds[0]>=crop[0]+2 and bounds[1]>=crop[1]+2 and bounds[2]<=crop[2]-2 and bounds[3]<=crop[3]-2
        sprite = raw.crop(crop).resize(tile, Image.Resampling.LANCZOS)
        atlas.paste(sprite,(index%6*tile[0], index//6*tile[1]))
atlas.save(target/'ritual-poses.webp',quality=86,method=6)
