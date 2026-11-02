"""Validate and package archived native ImageGen bytes; no image modification."""
from pathlib import Path
from PIL import Image
import hashlib
import json
import shutil
import zipfile

ROOT = Path(__file__).resolve().parent
ORDER = [('front', '01-front.png'), ('left', '02-left.png'),
         ('back', '03-back.png'), ('right', '04-right.png')]
provenance = json.loads((ROOT / 'provenance.json').read_text())
sources = {a['id']: a for a in provenance['assets']}
pack = ROOT / 'meshy'
pack.mkdir(exist_ok=True)
records = []
for side, filename in ORDER:
    entry = sources[side]
    source = ROOT / entry['file']
    raw = source.read_bytes()
    assert hashlib.sha256(raw).hexdigest() == entry['sha256'], side + ': source changed'
    with Image.open(source) as image:
        assert image.mode == 'RGBA', side + ': native alpha missing'
        alpha = image.getchannel('A')
        assert alpha.getextrema() == (0, 255), side + ': expected clear and opaque pixels'
        bounds = alpha.point(lambda n: 255 if n > 240 else 0).getbbox()
        assert bounds and 0 < bounds[0] < bounds[2] < image.width
        assert 0 < bounds[1] < bounds[3] < image.height
        assert alpha.histogram()[0] > image.width * image.height * .2
        assert bounds[3] - bounds[1] > image.height * .8
        assert len(raw) < 20 * 1024 * 1024
        records.append({'id': side, 'file': 'meshy/' + filename,
                        'size': list(image.size), 'solid_bounds': list(bounds),
                        'bytes': len(raw), 'sha256': entry['sha256'],
                        'native_alpha': True, 'byte_identical_to_source': True})
    shutil.copyfile(source, pack / filename)
    assert (pack / filename).read_bytes() == raw

# Native generator returned a one-pixel canvas-height difference. Preserve its
# bytes, report the difference and actual silhouette alignment transparently.
assert len({r['size'][0] for r in records}) == 1
assert max(r['size'][1] for r in records) - min(r['size'][1] for r in records) <= 1
spread = lambda index: max(r['solid_bounds'][index] for r in records) - min(r['solid_bounds'][index] for r in records)
report = {'status': 'prepared-not-reconstructed', 'records': records,
          'top_spread_pixels': spread(1), 'sole_spread_pixels': spread(3),
          'total_png_bytes': sum(r['bytes'] for r in records),
          'limits': 'Native independent illustrations, not calibrated geometry; no Meshy reconstruction or rig validation.'}
readme = ROOT / 'meshy-instructions.txt'
shutil.copyfile(readme, pack / 'README.txt')
archive = ROOT / 'oculin-meshy-pack.zip'
with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED) as bundle:
    for _, filename in ORDER:
        bundle.write(pack / filename, filename)
    bundle.write(pack / 'README.txt', 'README.txt')
with zipfile.ZipFile(archive) as bundle:
    assert set(bundle.namelist()) == {filename for _, filename in ORDER} | {'README.txt'}
    assert bundle.testzip() is None
    for _, filename in ORDER:
        assert bundle.read(filename) == (pack / filename).read_bytes()
report['zip_bytes'] = archive.stat().st_size
(ROOT / 'validation.json').write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps({k: v for k, v in report.items() if k != 'records'}, indent=2))
