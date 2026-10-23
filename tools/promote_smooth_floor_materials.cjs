// Promote the exact smooth floor proposal approved on 2026-10-23.
// Walls, wood and metal retain the active recipe. Subsequent reproduction uses
// prepare_shared_stone_materials.cjs, without depending on proposal directories.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto');
const {writeGeneratedFile}=require('./write_generated_file.cjs');
const root=path.resolve(__dirname,'..'),dir='assets/dungeon/shared-materials';
const read=p=>fs.readFileSync(path.join(root,p));
const write=(p,b)=>writeGeneratedFile(path.join(root,p),b);
const hash=b=>crypto.createHash('sha256').update(b).digest('hex');
const review='docs/reference/material-variation-review';
const sourceRecipe=review+'/rounded-smooth-floor-recipe.json';
const proposed=JSON.parse(read(sourceRecipe));
const active=JSON.parse(read(dir+'/active-recipe.json'));
const frozen=review+'/source/active-recipe-before-smooth.json';
if(!fs.existsSync(path.join(root,frozen)))write(frozen,read(dir+'/active-recipe.json'));
const atlas=dir+'/floor-smooth-atlas-v1.png';
write(atlas,read(proposed.materials.entries['smooth-floor-1'].source));
// Four complete stones per periodic C cell, drawn from the accepted eight
// samples. Boundary fragments use the SAME material on both sides.
const selection={'floors-calm':6,'floors-fine-crack':2,'floors-worn':4,'floors-marks':3};
for(const [id,n] of Object.entries(selection)){
  const m=proposed.materials.entries['smooth-floor-'+n];
  active.entries[id]={file:active.entries[id].file,family:'floors',source:atlas,sourceRegion:m.sourceRegion,expectedSha256:m.sha256};
}
active.renderProfile.floor=proposed.materials.renderProfile.floor;
active.id='shared-dungeon-stylized-smooth-floor-v3';
active.floorFinish={...proposed.floorFinish,id:'smooth-floor-rounded-v1',status:'user_approved',approval:'2026-10-23: Oui, for rounded smooth floor integration in Godot.',scope:'Ground slabs only; walls and stair treads retain B. Whole crossing stones are rounded before cell framing.'};
active.floorPattern={geometryId:JSON.parse(read('docs/reference/floor-periodic-cell.json')).id,cells:{'0:0':'floors-fine-crack','0:1':'floors-calm','0:2':'floors-fine-crack','1:0':'floors-worn','1:1':'floors-marks','1:2':'floors-worn'},scope:'One periodic prepared C floor with four whole stones. Eight-source material atlas retained; no new runtime variations.'};
active.floorApproval={date:'2026-10-23',request:'Oui',review:review+'/rounded-smooth-c-comparison.png',detail:review+'/rounded-smooth-floor-detail.png',recipe:sourceRecipe,recipeSha256:hash(read(sourceRecipe)),sourceSha256:hash(read(atlas)),selection};
write(dir+'/active-recipe.json',JSON.stringify(active,null,2)+'\n');
console.log('Promoted smooth floor recipe and source; active wall, wood and metal crops retained.');
