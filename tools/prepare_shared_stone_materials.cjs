// Reproduce the approved shared material family; never regenerate its appearance.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),sharp=require('sharp');
const root=path.resolve(__dirname,'..'),dir=path.join(root,'assets/dungeon/shared-materials');
const hash=b=>crypto.createHash('sha256').update(b).digest('hex');
async function main(){
  const recipePath='assets/dungeon/shared-materials/active-recipe.json';
  const recipeBytes=fs.readFileSync(path.join(root,recipePath));
  const recipe=JSON.parse(recipeBytes),entries={},panels=[];
  for(const [id,spec] of Object.entries(recipe.entries)){
    const atlas=fs.readFileSync(path.join(root,spec.source));
    const buffer=await sharp(atlas).extract(spec.sourceRegion).png().toBuffer();
    const digest=hash(buffer);
    if(digest!==spec.expectedSha256)throw Error(`${id}: source crop differs from the approved material`);
    const stats=await sharp(buffer).stats();
    fs.writeFileSync(path.join(dir,spec.file),buffer);
    entries[id]={file:spec.file,family:spec.family,source:spec.source,sourceSha256:hash(atlas),sourceRegion:spec.sourceRegion,sha256:digest,meanRGB:stats.channels.slice(0,3).map(c=>+c.mean.toFixed(2)),status:recipe.status};
    panels.push({id,buffer});
  }
  const catalog={id:recipe.id,status:recipe.status,approval:recipe.approval,approvedReview:recipe.approvedReview,canonicalStyle:recipe.canonicalStyle,recipe:recipePath,recipeSha256:hash(recipeBytes),purpose:'Approved stylized materials reused on fixed wireframe faces; prepared offline.',rules:['Use this exact approved source atlas and crop recipe by default.','No independent palette generation per orientation.','Preserve geometry, silhouettes, joints, anchors and projection.','Use the same material identity on a stone top and its upper facade.','Broad painted facets, sparse graphic wear and localized violet accents; no realistic grain or bark.','Godot selects finished PNGs with white modulation; no runtime appearance repair.'],renderProfile:recipe.renderProfile,entries};
  if(recipe.floorFinish)catalog.floorFinish=recipe.floorFinish;
  if(recipe.floorPattern)catalog.floorPattern=recipe.floorPattern;
  if(recipe.floorApproval)catalog.floorApproval=recipe.floorApproval;
  if(recipe.wallVariation)catalog.wallVariation=recipe.wallVariation;
  if(recipe.wallApproval)catalog.wallApproval=recipe.wallApproval;
  fs.writeFileSync(path.join(dir,'catalog.json'),JSON.stringify(catalog,null,2)+'\n');
  const height=Math.ceil(panels.length/4)*315+90;
  const body=panels.map((p,i)=>{const x=24+(i%4)*270,y=82+Math.floor(i/4)*315;return `<text x="${x}" y="${y}" fill="#cbd5e8" font-size="17">${p.id}</text><image href="data:image/png;base64,${p.buffer.toString('base64')}" x="${x}" y="${y+14}" width="248" height="248"/>`;}).join('');
  const sheet=`<svg xmlns="http://www.w3.org/2000/svg" width="1104" height="${height}"><rect width="1104" height="${height}" fill="#0b101b"/><g font-family="Arial,sans-serif"><text x="24" y="36" fill="#edf2ff" font-size="24">Gamme stylisée validée · matières communes</text>${body}<text x="24" y="${height-12}" fill="#aebad0" font-size="14">Atlas et découpes approuvés · pierre, sol, bois et fer · géométrie indépendante</text></g></svg>`;
  await sharp(Buffer.from(sheet)).png().toFile(path.join(dir,'material-board.png'));
  console.log(JSON.stringify({id:catalog.id,materials:Object.keys(entries).length,sourceCrops:'match approved hashes',recipe:recipePath}));
}
main().catch(e=>{console.error(e);process.exitCode=1;});
