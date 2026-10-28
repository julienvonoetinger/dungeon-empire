import bpy,math,json
from mathutils import Vector
from pathlib import Path
out=Path(r'C:/Users/A/Documents/GitHub/dungeon-empire/docs/reference/vulpin-review/v24-meshy-dead')
bpy.ops.wm.open_mainfile(filepath=str(out/'vulpin-fall-poses.blend'))
a=bpy.data.objects['SmartRigArmature'];bpy.context.scene.frame_set(10)
for side,names in {'R':['Bone_026','Bone_025','Bone_024'],'L':['Bone_031','Bone_030','Bone_029']}.items():
    p=[a.matrix_world@a.pose.bones[n].head for n in names]
    print(side,[list(x) for x in p], 'elbow',math.degrees((p[0]-p[1]).angle(p[2]-p[1])),'reach',(p[2]-p[0]).length,'fwd',p[0].y-p[2].y)
