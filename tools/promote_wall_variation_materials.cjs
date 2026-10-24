// One-time promotion of the reviewed A/B/C walls and selected D2 corruption.
const fs=require('node:fs'),path=require('node:path');
const {writeGeneratedFile}=require('./write_generated_file.cjs');
const R=require('./painted_material_renderer.cjs'),{read,hash,ROOT}=R;
const DIR='assets/dungeon/shared-materials',REVIEW='docs/reference/wall-corruption-review-v2';
const write=(p,b)=>writeGeneratedFile(path.join(ROOT,p),b);
const active=JSON.parse(read(DIR+'/active-recipe.json'));
const frozen=REVIEW+'/source/active-recipe-before-wall-integration.json';
if(!fs.existsSync(path.join(ROOT,frozen)))write(frozen,read(DIR+'/active-recipe.json'));
const base=JSON.parse(read(REVIEW+'/source/previous-recipe.json')).materials;
const selected=JSON.parse(read(REVIEW+'/selection.json'));
if(selected.variant!=='D2')throw Error('Expected selected D2 appearance');
const atlas=DIR+'/wall-variation-atlas-v1.png';
write(atlas,read(selected.material.source));
const sources={quiet:base.entries['wall-review-quiet'],calm:base.entries['variation-wall-6'],weathered:base.entries['variation-wall-2'],chip:base.entries['wall-review-chip'],softchip:base.entries['variation-wall-3'],scar:base.entries['variation-wall-1'],d2:selected.material};
for(const [name,m]of Object.entries(sources))active.entries['wall-var-'+name]={file:'wall-var-'+name+'.png',family:'walls',source:atlas,sourceRegion:m.sourceRegion,expectedSha256:m.sha256};
// Non-wall masonry (arches/end faces) uses the same palette, without a forced glow.
for(const [id,name]of Object.entries({'walls-planes':'quiet','walls-fissures':'weathered','walls-layers':'calm','walls-pits':'softchip'}))active.entries[id]={...active.entries['wall-var-'+name],file:active.entries[id].file};
active.id='shared-dungeon-wall-variants-d2-v4';
active.wallVariation={id:'wall-variants-abcd2-v1',styles:['A','B','C','D2'],materials:Object.fromEntries(Object.keys(sources).map(n=>[n,'wall-var-'+n])),drawAccent:false,policy:'Complete local stone faces; common quiet boundary stones. Interior A/B/C/D2 changes only. D2 has one unfolded top/facade paint patch.',selection:'Grid-coordinate hash, base weights 8 calm / 4 weathered / 3 chipped / 1 D2. Adjacent D2 candidates keep only the lower hash.',review:'docs/reference/wall-variation-review/comparison.png',corruptionReview:REVIEW+'/comparison.png',approval:'2026-10-23: D2, then Go for integration.'};
active.wallApproval={date:'2026-10-23',request:['D2','Go'],selection:REVIEW+'/selection.json',selectionSha256:hash(read(REVIEW+'/selection.json')),sourceSha256:hash(read(atlas))};
write(DIR+'/active-recipe.json',JSON.stringify(active,null,2)+'\n');
console.log('Promoted exact A/B/C and D2 wall crops; floor, wood and metal recipes retained.');
