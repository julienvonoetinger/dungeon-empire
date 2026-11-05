"""Pack the native walk atlases and render a looping review from the same frames."""
from pathlib import Path
from math import cos, radians
from PIL import Image, ImageDraw, ImageFont

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]
ROLES = {"mineur": ("Mineur", .154), "menuisier": ("Menuisier", .145),
         "scientifique": ("Scientifique", .138)}
VIEWS = ("se","sw","nw","ne")
COUNT, SIZE, FPS = 16, 256, 20
anchor = SIZE/2 + .76*cos(radians(30))*SIZE/2.55
review = [Image.new("RGB",(768,510),"#232630") for _ in range(COUNT)]
try:
    font = ImageFont.truetype("segoeuib.ttf", 20)
except OSError:
    font = ImageFont.load_default(size=20)

for index,(role,(label,half_step)) in enumerate(ROLES.items()):
    asset = f"assets/previews/oculin-{role}-walk"
    target = ROOT / asset
    target.mkdir(parents=True,exist_ok=True)
    lines = [f'[gd_resource type="SpriteFrames" load_steps={1+len(VIEWS)*(COUNT+1)} format=3]', '']
    animations = []
    for view in VIEWS:
        lines.append(f'[ext_resource type="Texture2D" path="res://{asset}/walk-{view}.png" id="{view}"]')
    for view in VIEWS:
        sheet = Image.new("RGBA",(SIZE*8,SIZE*2))
        frames = []
        for i in range(COUNT):
            with Image.open(OUT/role/"masters"/view/f"{i:02}.png") as master:
                assert master.mode == "RGBA" and master.size == (384,384)
                box = master.getchannel("A").point(lambda a: 255 if a>8 else 0).getbbox()
                assert box and min(box[:2])>1 and max(box[2:])<383,(role,view,i,box)
                frame = master.resize((SIZE,SIZE),Image.Resampling.LANCZOS)
            x,y = SIZE*(i%8),SIZE*(i//8)
            sheet.paste(frame,(x,y))
            lines.extend(['', f'[sub_resource type="AtlasTexture" id="{view}_{i}"]',
                          f'atlas = ExtResource("{view}")', f'region = Rect2({x}, {y}, {SIZE}, {SIZE})',
                          'filter_clip = true'])
            frames.append(f'{{"duration": 1.0, "texture": SubResource("{view}_{i}")}}')
            if view in ("se","nw"):
                row = 0 if view == "se" else 1
                top = 24 + row*234
                tile = review[i]
                draw = ImageDraw.Draw(tile)
                cx = index*SIZE + SIZE//2
                if row == 0:
                    draw.text((cx,20),label,font=font,fill="#eed9b7",anchor="mm")
                draw.ellipse((cx-48,top+anchor-13,cx+48,top+anchor+12),fill="#191b23")
                tile.paste(frame,(index*SIZE,top),frame)
        sheet.save(target/f"walk-{view}.png")
        animations.append('{"frames": [' + ',\n'.join(frames) +
                          f'], "loop": true, "name": &"{view}", "speed": {FPS}.0}}')
    lines.extend(['','[resource]','animations = ['+',\n'.join(animations)+']',''])
    (target/"frames.tres").write_text('\n'.join(lines),encoding='utf8')
    name = f"Oculin{label}Walk"
    scene = f'''[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/vulpin_walk_preview.gd" id="1"]
[ext_resource type="SpriteFrames" path="res://{asset}/frames.tres" id="2"]

[node name="{name}" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1")
preview_title = "Oculin {role} · Marche"
animation_frames = ExtResource("2")
pose_fps = {FPS}.0
model_travel_units_per_second = {4*half_step*FPS/COUNT:.4f}
base_playback_rate = 1.0
sprite_registration = {{
"actor_name": "{label}",
"anchor": Vector2(128, {anchor:.6f}),
"frame_size": 256.0,
"half_extent": 0.23,
"hero_scale": 0.94,
"ortho_scale": 2.55
}}
'''
    (ROOT/"scenes"/(name+".tscn")).write_text(scene,encoding='utf8')
review[0].save(OUT/"marche-equipee.webp",save_all=True,append_images=review[1:],
               duration=1000//FPS,loop=0,quality=90,method=4)

