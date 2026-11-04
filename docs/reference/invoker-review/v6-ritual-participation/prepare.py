from pathlib import Path
import json, re, hashlib
from PIL import Image
OUT=Path(__file__).resolve().parent
REPO=OUT.parents[3]
# The approved wireframe supplies actual stone ground footprints (Z=0).
geometry=json.loads((REPO/'docs/reference/sanctuary-textured/v1/geometry.json').read_text())
models={m['id']:m for m in geometry['models']}
scene=(REPO/'scenes/game/InvocationSanctuary.tscn').read_text()
obstacles=[]
for block in scene.split('[node ')[1:]:
    name=re.search(r'name="([^"]+)"',block).group(1)
    if not name.startswith(('RocheApproche','Eboulis','Menhir','Paroi','Crete')) or 'Ombre' in name: continue
    texture=re.search(r'texture = ExtResource\("([^"]+)"\)',block)
    pos=re.search(r'position = Vector2\(([^,]+),([^\)]+)\)',block)
    if not texture or not pos or texture[1] not in models: continue
    model=models[texture[1]]
    points=sorted(set((round(128*(p[0]-p[1]),5),round(64*(p[0]+p[1]),5)) for f in model['faces'] for p in f['points'] if abs(p[2])<.00001))
    # Monotone convex hull of the authored base vertices.
    def cross(a,b,c): return (b[0]-a[0])*(c[1]-a[1])-(b[1]-a[1])*(c[0]-a[0])
    halves=[]
    for order in [points,list(reversed(points))]:
        half=[]
        for p in order:
            while len(half)>=2 and cross(half[-2],half[-1],p)<=0: half.pop()
            half.append(p)
        halves.append(half[:-1])
    hull=halves[0]+halves[1]
    if len(hull)<3: continue
    position=[float(pos[1]),float(pos[2])]
    obstacles.append(dict(name=name,points=[[p[0]+position[0],p[1]+position[1]] for p in hull]))
dest=REPO/'assets/game/introduction/procession'
(dest/'obstacles.json').write_text(json.dumps(obstacles,separators=(',',':')),encoding='utf8')
if (OUT/'oculin.json').exists():
    atlas=Image.new('RGBA',(8*256,6*256))
    for i in range(48):
        im=Image.open(OUT/'oculin'/f'chant-{i:02d}.png').convert('RGBA')
        box=im.getchannel('A').point(lambda a:255 if a>16 else 0).getbbox()
        assert box and box[0]>0 and box[1]>0 and box[2]<384 and box[3]<384,box
        atlas.paste(im.resize((256,256),Image.Resampling.LANCZOS),((i%8)*256,(i//8)*256))
    atlas.save(dest/'oculin-chant.png')
    (OUT/'packed.json').write_text(json.dumps(dict(sha256=hashlib.sha256((dest/'oculin-chant.png').read_bytes()).hexdigest(),frames=48,obstacles=len(obstacles)),indent=2))
print('Prepared',len(obstacles),'authored footprints')
