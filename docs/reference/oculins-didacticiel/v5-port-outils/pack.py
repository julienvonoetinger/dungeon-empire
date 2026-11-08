"""Pack Blender's complete frames into the existing 8x2 atlases, at the v4 registration."""
import hashlib
import io
import json
from pathlib import Path
import sys
from PIL import Image

here = Path(__file__).resolve().parent
root = here.parents[3]
renders = Path(sys.argv[1])
records = {}
prepared = {}
for role in ("mineur","menuisier","scientifique"):
    frames = renders / role
    output = root / "assets" / "previews" / f"oculin-{role}-walk"
    hashes = {}
    for view in ("se","sw","nw","ne"):
        atlas = Image.new("RGBA",(2048,512))
        for index in range(16):
            with Image.open(frames/view/f"{index:02}.png") as master:
                assert master.mode=="RGBA" and master.size==(384,384)
                box = master.getchannel("A").point(lambda a: 255 if a>8 else 0).getbbox()
                assert box and min(box[:2])>1 and max(box[2:])<383,(role,view,index,box)
                tile = master.resize((256,256),Image.Resampling.LANCZOS)
            atlas.paste(tile,(256*(index%8),256*(index//8)))
        path = output / f"walk-{view}.png"
        encoded = io.BytesIO()
        atlas.save(encoded,format="PNG")
        prepared[path] = encoded.getvalue()
        hashes[view] = hashlib.sha256(prepared[path]).hexdigest()
    records[role] = {"bounds":json.loads((frames/"bounds.json").read_text()),"atlases":hashes}
for path, data in prepared.items():
    path.write_bytes(data)
(here/"tool-bounds.json").write_text(json.dumps(records,ensure_ascii=False,indent=1)+"\n",encoding="utf-8")
