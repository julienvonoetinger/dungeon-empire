from pathlib import Path
import json, hashlib, shutil, zipfile
from PIL import Image

root = Path(__file__).resolve().parent
data = json.loads((root / 'prompts-provenance.json').read_text(encoding='utf-8'))
out = root / 'meshy'
out.mkdir(exist_ok=True)
report = []
for entry in data['files']:
    src = Path(entry['source'])
    dst = out / entry['name']
    shutil.copy2(src, dst)
    assert src.read_bytes() == dst.read_bytes()
    with Image.open(dst) as im:
        assert im.mode == 'RGBA'
        alpha = im.getchannel('A')
        assert alpha.getextrema() == (0, 255)
        box = alpha.point(lambda x: 255 if x > 16 else 0).getbbox()
        assert box and box[0] > 0 and box[1] > 0 and box[2] < im.width and box[3] < im.height, (dst.name, box)
        report.append(dict(file=dst.name, size=list(im.size), alpha_bbox=box, bytes=dst.stat().st_size, sha256=hashlib.sha256(dst.read_bytes()).hexdigest()))
(root / 'validation.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
with zipfile.ZipFile(root / 'maitre-oculin-meshy.zip', 'w', zipfile.ZIP_DEFLATED) as archive:
    for entry in data['files']:
        archive.write(out / entry['name'], entry['name'])
    archive.write(root / 'README.txt', 'README.txt')
print(json.dumps(report, indent=2))
