// Floor-only drawing proposal. Retain the original oblique camera and all solids.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
const {writeGeneratedFile}=require('./write_generated_file.cjs');
const {build,visibleEdges,drawing,cameras}=require('./prepare_ground_perspective_review.cjs');
const ROOT=path.resolve(__dirname,'..');
const OUT=path.join(ROOT,'docs/reference/ground-perspective-review/wireframe-v2-floor-only');
const camera=cameras.current;
// Visual paving study only: the joint slope echoes the original wall height
// vector (.18,.9). This is NOT a newly derived physical camera for the ground.
const slope=.18/.9;
const fmt=n=>+n.toFixed(6);
const write=(file,data)=>writeGeneratedFile(path.join(OUT,file),data);
const svg=(w,h,body)=>`<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}">${body}</svg>`;
const text=(x,y,size,value,fill='#e6edf5')=>`<text x="${x}" y="${y}" font-family="Segoe UI,Arial,sans-serif" font-size="${size}" fill="${fill}">${value}</text>`;
async function save(name,w,h,body) {
  const source=svg(w,h,body);write(name+'.svg',source);
  write(name+'.png',await sharp(Buffer.from(source)).png().toBuffer());
}
function floorOnly(before) {
  const after=structuredClone(before);
  after.edges=after.edges.filter(e=>e.kind!=='floor');
  const edge=(a,b)=>after.edges.push({a,b,kind:'floor'});
  const widths=[[.18,.35,.33,.14],[.30,.34,.32,.04],[.07,.33,.35,.25]];
  for(const [x,y] of after.cells) {
    for(let r=0;r<=3;r++)edge([x,y+r/3,0],[x+1,y+r/3,0]);
    for(let r=0;r<3;r++) {
      const Y=y+r/3,Z=y+(r+1)/3,[a,b,c]=widths[r];
      // Global coordinates keep joints continuous across cell boundaries.
      for(let repeat=Math.floor(x-slope*Z)-1;repeat<=Math.ceil(x+1-slope*Y);repeat++) {
        for(const cut of [a,a+b,a+b+c]) {
          const base=repeat+cut;
          const lo=Math.max(Y,(x-base)/slope),hi=Math.min(Z,(x+1-base)/slope);
          if(hi>lo+1e-9)edge([base+slope*lo,lo,0],[base+slope*hi,hi,0]);
        }
      }
    }
  }
  return after;
}
async function main() {
  const before=build(),after=floorOnly(before);
  const oldEdges=visibleEdges(before,camera),newEdges=visibleEdges(after,camera);
  // Scope guards at export: changing a wall or heart is not permitted here.
  const fixed=e=>e.kind!=='floor';
  if(JSON.stringify(before.faces)!==JSON.stringify(after.faces)||
    JSON.stringify(before.edges.filter(fixed))!==JSON.stringify(after.edges.filter(fixed))||
    JSON.stringify(oldEdges.filter(fixed))!==JSON.stringify(newEdges.filter(fixed)))
    throw new Error('Floor-only review changed a solid or a non-floor visible edge');
  const bg=(w,h)=>`<rect width="${w}" height="${h}" fill="#0b1019"/>`;
  let body=bg(1400,800)+text(30,38,24,'Correction — murs d’origine conservés');
  body+=text(30,66,15,'Même cadrage, mêmes murs, mêmes piliers et même repère du cœur. Seuls les joints du dallage changent.','#b2bdce');
  for(const [i,model,edges] of [[0,before,oldEdges],[1,after,newEdges]]) {
    const x=24+i*698;
    body+=text(x+14,110,20,i?'Essai : joints du sol inclinés':'Dallage actuel');
    body+=`<defs><clipPath id="panel${i}"><rect x="${x}" y="130" width="676" height="585"/></clipPath></defs><g clip-path="url(#panel${i})">`;
    body+=drawing(model,edges,camera,[x+52,235],174,1.4)+'</g>';
  }
  body+=text(38,754,15,'La salle garde ses dimensions. Les trois rangées de dalles et leur largeur sont conservées.','#b2bdce');
  body+=text(38,781,14,'Étude du dessin des joints, sans changement de caméra ni de sprites actifs.','#b2bdce');
  await save('comparison',1400,800,body);
  body=bg(1280,1400)+text(32,40,25,'Wireframe — dallage seul modifié');
  body+=text(32,69,15,'Perspective oblique d’origine · cases 1 × 1 · murs et piliers conservés','#b2bdce');
  body+=drawing(after,newEdges,camera,[64,165],192);
  body+=text(32,1370,15,'Cyan : joints du sol à évaluer. Blanc : murs d’origine. Ambre : repère du cœur inchangé.','#b2bdce');
  await save('room',1280,1400,body);
  await save('room-transparent',1280,1400,drawing(after,newEdges,camera,[64,165],192));
  // Save the original wall geometry alone as a convenient comparison overlay.
  const allSolidEdges=newEdges.filter(e=>e.kind!=='floor');
  await save('fixed-volumes',1280,1400,drawing(after,allSolidEdges,camera,[64,165],192));
  const record={status:'floor-pattern-only proposal awaiting feedback; v1 global-camera change rejected',
    generator:'tools/prepare_floor_only_wireframe_review.cjs',camera,logicalCell:[1,1],displayGroundCell:[192,192],
    change:{jointSlope:slope,horizontalRowsPerCell:3,globalMapping:'floor joint x = original x + 0.2 * y; y unchanged',
      interpretation:'stylized paving pattern on the unchanged ground, not a new physical ground projection'},
    unchanged:['All closed solid faces','All wall/pillar/heart source edges and visible segments','Camera and logical grid','Floor coverage, horizontal rows and slab widths','Production sprites/scenes'],
    scopeGuard:{fixedVisibleSegments:newEdges.filter(fixed).length,exactlyEqual:true},
    note:'Heart is the same schematic volume as the current-camera drawing from v1, not a new design or painted sprite.',
    models:{before,after},visibleEdges:{before:oldEdges,after:newEdges}};
  write('geometry.json',JSON.stringify(record,null,2)+'\n');
  console.log(JSON.stringify({output:OUT,floorSlope:fmt(slope),fixedVisibleSegments:record.scopeGuard.fixedVisibleSegments}));
}
main().catch(error=>{console.error(error);process.exitCode=1;});
