from pathlib import Path
source=Path(r'C:/Users/A/Documents/GitHub/dungeon-empire/docs/reference/vulpin-review/v24-meshy-dead/render_dead.py')
exec(compile(source.read_text(encoding='utf8').split("scene.render.engine=")[0],str(source),'exec'))
p=vertices()
groups={g.index:g.name for g in mesh.vertex_groups}
for group in ['Bone_000','Bone_004','Bone_021','Bone_019','Bone_018','Bone_015','Bone_009','Bone_007','Bone_014','Bone_012','Bone_024','Bone_029']:
    ids=[v.index for v in mesh.data.vertices if v.groups and groups[max(v.groups,key=lambda g:g.weight).group]==group]
    if ids: print(group,len(ids),'minmaxZ',min(p[i].z for i in ids),max(p[i].z for i in ids))
for name in ['Bone_000','Bone_021','Bone_019','Bone_018','Bone_017','Bone_016','Bone_015']:
    b=arm.pose.bones[name]
    print(name,'head',list(arm.matrix_world@b.head),'tail',list(arm.matrix_world@b.tail))
