from pathlib import Path
from PIL import Image
import hashlib,json
ROOT=Path(__file__).resolve().parent
dest=ROOT.parents[3]/'assets/game/introduction/invoker-follow'
data=json.loads((ROOT/'directions.json').read_text())
records=[]
for direction,entry in data['directions'].items():
    for clip,count in [('idle',1),('walk',24)]:
        cols=min(8,count)
        atlas=Image.new('RGBA',(cols*256,((count+cols-1)//cols)*256))
        for i in range(count):
            image=Image.open(ROOT.parent/entry['masters']/f'{clip}-{i:02d}.png').convert('RGBA')
            box=image.getchannel('A').point(lambda x:255 if x>16 else 0).getbbox()
            assert box and min(box[:2])>0 and max(box[2:])<384
            atlas.paste(image.resize((256,256),Image.Resampling.LANCZOS),((i%cols)*256,(i//cols)*256))
        file=dest/f'{direction}-{clip}.png'
        atlas.save(file)
        records.append(dict(file=file.name,sha256=hashlib.sha256(file.read_bytes()).hexdigest()))
(dest/'directions.json').write_text(json.dumps(data,indent=2))
(ROOT/'packed.json').write_text(json.dumps(records,indent=2))
print('FACING_PACK_OK',len(records))
