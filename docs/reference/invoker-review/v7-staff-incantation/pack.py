from pathlib import Path
from PIL import Image
import json, hashlib
OUT=Path(__file__).resolve().parent
REPO=OUT.parents[3]
atlas=Image.new('RGBA',(2048,1536))
for i in range(48):
    im=Image.open(OUT/'invoker'/f'chant-{i:02d}.png').convert('RGBA')
    box=im.getchannel('A').point(lambda a:255 if a>16 else 0).getbbox()
    assert box and box[0]>0 and box[1]>0 and box[2]<384 and box[3]<384,(i,box)
    atlas.paste(im.resize((256,256),Image.Resampling.LANCZOS),((i%8)*256,(i//8)*256))
dest=REPO/'assets/game/introduction/procession/invoker-chant.png'
atlas.save(dest)
(OUT/'packed.json').write_text(json.dumps(dict(frames=48,sha256=hashlib.sha256(dest.read_bytes()).hexdigest(),bytes=dest.stat().st_size),indent=2))
print('PACKED_STAFF_CHANT',dest.stat().st_size)
