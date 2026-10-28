import bpy,json,math
from pathlib import Path
OUT=Path('C:/Users/A/Documents/GitHub/dungeon-empire/docs/reference/vulpin-review/v13-whole-sprites');src=OUT.parent/'v9-motion-correction/build_clips.py';g={'__file__':str(src),'__name__':'pose_reference'};exec(compile(src.read_text().split('rest={')[0],str(src),'exec'),g)
data=[]
for i in range(8):
 g['pose']('walk',i/8);rig=g['rig'];data.append({'frame':i,'phase':i/8,'bones':{b.name:{'head':g['screen'](rig.matrix_world@b.head),'tail':g['screen'](rig.matrix_world@b.tail)} for b in rig.pose.bones},'feet':{s:g['screen'](rig.matrix_world@rig.pose.bones['foot.'+s].head-g['Vector']((0,0,.08))) for s in ['L','R']}})
(OUT/'guides/poses.json').write_text(json.dumps(data,indent=2));print('POSE_REFERENCES_ONLY')
