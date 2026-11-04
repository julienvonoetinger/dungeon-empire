from pathlib import Path
import json, hashlib
from PIL import Image
OUT=Path(__file__).resolve().parent
REPO=OUT.parents[3]
dest=REPO/'assets/game/introduction/procession'
dest.mkdir(parents=True,exist_ok=True)
reports=[]
for kind in ['invoker','oculin']:
    data=json.loads((OUT/f'{kind}.json').read_text())
    groups={}
    for frame in data['frames']: groups.setdefault(frame['clip'],[]).append(frame)
    for clip,frames in groups.items():
        cols=min(8,len(frames));rows=(len(frames)+cols-1)//cols
        atlas=Image.new('RGBA',(cols*256,rows*256))
        for index,frame in enumerate(frames):
            image=Image.open(OUT/kind/frame['file']).convert('RGBA')
            box=image.getchannel('A').point(lambda x:255 if x>16 else 0).getbbox()
            assert box and box[0]>0 and box[1]>0 and box[2]<384 and box[3]<384,(kind,clip,index,box)
            atlas.paste(image.resize((256,256),Image.Resampling.LANCZOS),((index%cols)*256,(index//cols)*256))
        path=dest/f'{kind}-{clip}.png'
        atlas.save(path)
        reports.append(dict(file=path.name,frames=len(frames),sha256=hashlib.sha256(path.read_bytes()).hexdigest(),bytes=path.stat().st_size))
(OUT/'packed.json').write_text(json.dumps(reports,indent=2))
print(json.dumps(reports,indent=2))
