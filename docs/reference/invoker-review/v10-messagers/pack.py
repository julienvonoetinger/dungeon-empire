from pathlib import Path
from PIL import Image
root = Path(__file__).resolve().parent
dest = root.parents[3]/"assets/game/introduction/messengers"
dest.mkdir(parents=True,exist_ok=True)
for folder in sorted((root/"frames").iterdir()):
    frames = sorted(folder.glob("*.png"))
    assert len(frames)==(9 if folder.name=="turn" else 12)
    sheet = Image.new("RGBA",(4*256,3*256))
    for i,path in enumerate(frames):
        with Image.open(path) as im:
            assert im.size==(256,256)
            box=im.getchannel("A").getbbox()
            assert box and min(box[:2])>0 and max(box[2:])<256
            sheet.paste(im,(i%4*256,i//4*256))
    sheet.save(dest/(folder.name+".png"))
