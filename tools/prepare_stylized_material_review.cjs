// Style correction proposal only: exact existing geometry, new generated matter.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
const {ROOT,read,hash,render}=require('./painted_material_renderer.cjs');
const {makeModel}=require('./export_painted_image_catalog.cjs');
const OUT='docs/reference/stylized-material-review',SOURCE='assets/dungeon/shared-materials/proposals/stylized/atlas.png';
const guides=JSON.parse(read('docs/reference/wireframe-overlays/catalog.json'));
function write(file,data){fs.mkdirSync(path.dirname(path.join(ROOT,file)),{recursive:true});fs.writeFileSync(path.join(ROOT,file),data);}
async function main(){
  const atlas=read(SOURCE),meta=await sharp(atlas).metadata(),qw=Math.floor(meta.width/2),qh=Math.floor(meta.height/2);
  const materials=JSON.parse(read('assets/dungeon/shared-materials/catalog.json'));
  const sampling={
    'walls-planes':[0,.0,.0,.83],
    'walls-fissures':[1,.0,.0,1],
    'walls-layers':[0,.17,.12,.83],
    'walls-pits':[0,.08,.18,.80],
    'floors-calm':[2,.08,.02,.86],
    'floors-fine-crack':[2,.0,.16,.84],
    'floors-worn':[2,.16,.0,.84],
    'floors-marks':[2,.05,.10,.86],
    'door-oak':[3,.0,.0,1]
  };
  for(const [id,[quadrant,x,y,size]] of Object.entries(sampling)){
    const w=qw-16,h=qh-16,region={left:(quadrant%2)*qw+8+Math.round(x*w),top:Math.floor(quadrant/2)*qh+8+Math.round(y*h),width:Math.floor(w*size),height:Math.floor(h*size)};
    const png=await sharp(atlas).extract(region).png().toBuffer(),file='proposals/stylized/'+id+'.png';
    write('assets/dungeon/shared-materials/'+file,png);
    materials.entries[id]={...materials.entries[id],file,source:SOURCE,sourceRegion:region,sha256:hash(png)};
  }
  // Same stone value hierarchy as the active shared library. Broad painted source
  // shapes replace its microscopic grain without moving any joints or contours.
  materials.renderProfile.wood={color:'#453429',brightness:.85,saturation:.68,opacity:.94,blur:.3};
  const reports=[];
  for(const [label,id] of [['corner','cells/w09_p00_e00'],['door','doors/north']]){
    const entry=guides.entries[id],guide=read('docs/reference/wireframe-overlays/'+entry.svg).toString();
    const result=await render(makeModel(id,entry),guide,materials);
    write(OUT+'/'+label+'.png',result.png);write(OUT+'/'+label+'-overlay.png',result.overlay);
    const {faces,...report}=result.report;reports.push({...report,file:label+'.png',sha256:hash(result.png)});
  }
  write(OUT+'/recipe.json',JSON.stringify({status:'appearance_proposal',generator:'tools/prepare_stylized_material_review.cjs',source:SOURCE,sourceSha256:hash(atlas),materials,reports,scope:'Only material appearance. Existing masks, projection, geometry, outlines and bevel implementation retained; Godot assets unchanged.'},null,2)+'\n');
  const columns=[
    {name:'Actuel',subtitle:'Matières en place',folder:'assets/dungeon/painted-cells',files:['cells/w09_p00_e00.png','doors/north.png']},
    {name:'Essai précédent',subtitle:'Détails trop réalistes',folder:'docs/reference/corruption-material-review/02-fissures',files:['corner.png','door.png']},
    {name:'Nouvel essai',subtitle:'Aplats peints · détails simplifiés',folder:OUT,files:['corner.png','door.png']}
  ];
  const layers=[];let labels='';
  for(const [i,c] of columns.entries()){
    const x=8+i*428;
    labels+=`<text x="${x+14}" y="40" font-size="23" fill="#edf0fa">${c.name}</text><text x="${x+14}" y="68" font-size="16" fill="#aebcd0">${c.subtitle}</text>`;
    for(const [j,file] of c.files.entries()){
      const png=await sharp(read(c.folder+'/'+file)).resize({width:408,height:472,fit:'inside'}).toBuffer(),m=await sharp(png).metadata();
      layers.push({input:png,left:x+Math.round((416-m.width)/2),top:92+j*486});
    }
  }
  const bg=Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="1300" height="1130"><rect width="100%" height="100%" fill="#0a101b"/><g font-family="Arial,sans-serif">${labels}<text x="22" y="1090" font-size="18" fill="#c3cee0">Même géométrie · référence artistique : la maquette utilisateur uniquement</text><text x="22" y="1116" font-size="16" fill="#96a6be">Proposition de style à valider · coin de salle et porte · aucune modification des scènes Godot</text></g></svg>`);
  write(OUT+'/comparison.png',await sharp(bg).composite(layers).png().toBuffer());
  console.log(JSON.stringify({output:OUT,reports:reports.map(r=>({id:r.id,jointsMatch:r.exportedJointLayerMatchesGuide,alphaDifference:r.alphaPixelsDifferentFromModel}))}));
}
main().catch(e=>{console.error(e);process.exitCode=1;});
