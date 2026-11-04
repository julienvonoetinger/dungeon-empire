from pathlib import Path
from PIL import Image
import json,hashlib
ROOT=Path(__file__).resolve().parent
dest=ROOT.parents[3]/'assets/game/introduction/invoker-follow'
dest.mkdir(parents=True,exist_ok=True)
records=[]
for direction in ['ne','se','sw','nw']:
    for clip,count in [('idle',1),('walk',24)]:
        cols=min(8,count)
        atlas=Image.new('RGBA',(cols*256,((count+cols-1)//cols)*256))
        for i in range(count):
            image=Image.open(ROOT/direction/f'{clip}-{i:02d}.png').convert('RGBA')
            box=image.getchannel('A').point(lambda x:255 if x>16 else 0).getbbox()
            assert box and min(box[:2])>0 and max(box[2:])<384,(direction,clip,i,box)
            atlas.paste(image.resize((256,256),Image.Resampling.LANCZOS),((i%cols)*256,(i//cols)*256))
        file=dest/f'{direction}-{clip}.png'
        atlas.save(file)
        records.append(dict(file=file.name,sha256=hashlib.sha256(file.read_bytes()).hexdigest(),bytes=file.stat().st_size))
(ROOT/'packed.json').write_text(json.dumps(records,indent=2))
print('FOLLOW_PACK_OK',len(records))
