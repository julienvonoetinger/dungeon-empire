from pathlib import Path
source=Path(r'C:/Users/A/Documents/GitHub/dungeon-empire/docs/reference/vulpin-review/v24-meshy-dead/render_fall.py')
exec(compile(source.read_text(encoding='utf-8-sig').split('scene.render.engine=')[0],str(source),'exec'))
r=pose_fall(9);p=vertices();groups={g.index:g.name for g in mesh.vertex_groups}
mins={}
for v in mesh.data.vertices:
    name=groups[max(v.groups,key=lambda g:g.weight).group]
    mins[name]=min(mins.get(name,99),p[v.index].z)
print('LOWEST',sorted(mins.items(),key=lambda kv:kv[1])[:14])
for side,names in {'R':['Bone_026','Bone_025','Bone_024'],'L':['Bone_031','Bone_030','Bone_029']}.items():
    a,b,c=[arm.matrix_world@arm.pose.bones[n].head for n in names]
    print(side,'angle',math.degrees((a-b).angle(c-b)),'fwd',a.y-c.y,'wrist',list(c))
