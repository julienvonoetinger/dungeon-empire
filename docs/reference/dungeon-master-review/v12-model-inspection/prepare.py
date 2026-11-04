"""Archive supplied Meshy GLBs byte-for-byte before inspecting working copies."""
import hashlib, json, shutil, struct
from pathlib import Path

OUT=Path(__file__).parent
SOURCE=OUT.parent/'source'
SOURCE.mkdir(parents=True,exist_ok=True)
items=[('eye','C:/Users/A/Downloads/Meshy_AI_Violet_Void_Eye_1104125947_texture.glb'),
       ('volute','C:/Users/A/Downloads/Meshy_AI_Violet_Crescent_Flame_1104130018_texture.glb')]
records=[]
for kind,original in items:
    src=Path(original)
    data=src.read_bytes()
    sha=hashlib.sha256(data).hexdigest()
    dst=SOURCE/(kind+'-original.glb')
    if dst.exists():
        assert hashlib.sha256(dst.read_bytes()).hexdigest()==sha, 'Different archived source: '+kind
    else: shutil.copyfile(src,dst)
    assert dst.read_bytes()==data
    magic,version,size=struct.unpack_from('<III',data)
    assert magic==0x46546c67 and version==2 and size==len(data)
    length,chunk=struct.unpack_from('<II',data,12)
    assert chunk==0x4e4f534a
    gltf=json.loads(data[20:20+length])
    (OUT/(kind+'-gltf.json')).write_text(json.dumps(gltf,indent=2)+'\n',encoding='utf8')
    records.append(dict(id=kind,original=original,file=dst.name,bytes=len(data),sha256=sha,
        meshes=len(gltf.get('meshes',[])),skins=len(gltf.get('skins',[])),
        animations=len(gltf.get('animations',[])),materials=len(gltf.get('materials',[])),images=len(gltf.get('images',[]))))
(SOURCE/'provenance.json').write_text(json.dumps(dict(files=records),indent=2)+'\n',encoding='utf8')
print(json.dumps(records,indent=2))
