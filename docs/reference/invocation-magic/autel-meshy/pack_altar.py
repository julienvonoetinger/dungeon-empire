"""Split the single-camera bake into depth layers, retaining a two-pixel filter gutter."""
import json
import tempfile
from pathlib import Path
from PIL import Image, ImageChops, ImageDraw, ImageFilter

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
OUT = ROOT / "assets/game/introduction/sanctuary/autel"
OUT.mkdir(exist_ok=True)
cache = Path(tempfile.gettempdir())/"oculin-altar-bake"
image = Image.open(HERE/"autel-isometrique.png").convert("RGBA")
alpha = image.getchannel("A")
labels = Image.frombytes("L",image.size,(cache/"layers.raw").read_bytes())
# Extend closest solid labels to the antialiased silhouette.
for _ in range(3):
    missing = labels.point(lambda p: 255 if p==255 else 0)
    labels.paste(labels.filter(ImageFilter.MinFilter(3)),mask=missing)
labels = labels.point(lambda p: 0 if p==255 else p)
layout = {}
def save(name, layer, anchor, crystal=None):
    box = layer.getchannel("A").getbbox()
    box = (box[0]-2,box[1]-2,box[2]+2,box[3]+2)
    layer.crop(box).save(OUT/(name+".png"))
    # Raw pixel (384,384) is the centre of the eye in sanctuary space (-6,7).
    layout[name] = {"position":[anchor[0]-390,anchor[1]-377],
                    "offset":[box[0]-anchor[0],box[1]-anchor[1]]}
    if crystal:
        layout[name]["crystal"] = [crystal[0]-anchor[0],crystal[1]-anchor[1]]

# Physical ground anchors and visible gem centres in the camera bake.
parts = [(3,(291,337),(288,132)), (4,(477,337),(478,132)),
         (0,(384,431),None), (2,(208,454),(206,303)), (5,(560,454),(560,303)),
         (1,(275,535),(276,459)), (6,(493,535),(492,459))]
reassembled = Image.new("RGBA",image.size)
for i,anchor,crystal in parts:
    mask = labels.point(lambda v: 255 if v==i else 0)
    # Only overlap on fully opaque internal cuts under later-ordered sprites.
    later = {item[0] for item in parts[parts.index((i,anchor,crystal))+1:]}
    gutter = ImageChops.multiply(mask.filter(ImageFilter.MaxFilter(5)),labels.point(lambda v:255 if v in later else 0))
    gutter = ImageChops.multiply(gutter,alpha.point(lambda v:255 if v==255 else 0))
    layer = image.copy()
    layer.putalpha(ImageChops.multiply(alpha,ImageChops.lighter(mask,gutter)))
    reassembled.alpha_composite(layer)
    save("Dalle" if i==0 else f"Menhir{i}",layer,anchor,crystal)
assert ImageChops.difference(reassembled.convert("RGBa"),image.convert("RGBa")).getextrema()==((0,0),)*4
assert ImageChops.difference(reassembled.getchannel("A"),alpha).getbbox() is None
silhouette = Image.new("L",image.size)
draw = ImageDraw.Draw(silhouette)
for tri in json.loads((cache/"shadow.json").read_text()):
    draw.polygon([tuple(p) for p in tri],fill=255)
shadow = Image.new("RGBA",image.size,(24,16,29,0))
shadow.putalpha(silhouette.filter(ImageFilter.GaussianBlur(8)).point(lambda p:round(p*.42)))
save("DalleOmbre",shadow,(384,438))
(HERE/"layout.json").write_text(json.dumps(layout,indent=2)+"\n")

