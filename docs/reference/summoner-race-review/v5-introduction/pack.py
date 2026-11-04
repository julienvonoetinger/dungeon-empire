from pathlib import Path
from PIL import Image
repo = Path(__file__).resolve().parents[4]
atlas = Image.new('RGBA', (768,768))
for i in range(9):
    frame = Image.open(repo / ('artifacts/introduction/stride-%d.png' % i))
    atlas.paste(frame, ((i%3)*256,(i//3)*256))
atlas.save(repo / 'assets/game/introduction/oculin-walk.png')
