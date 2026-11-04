from pathlib import Path
from PIL import Image
out = Path(__file__).resolve().parent
repo = out.parents[3]
images = [Image.open(repo/'artifacts/wraith-master'/f'frame-{i:02d}.png').convert('RGB') for i in range(60)]
images[0].save(out/'levitation.webp',save_all=True,append_images=images[1:],duration=100,loop=0,quality=85,method=4)
with Image.open(out/'levitation.webp') as result:
    assert result.n_frames == 60
print('60 native frames, 6 seconds:', (out/'levitation.webp').stat().st_size, 'bytes')
