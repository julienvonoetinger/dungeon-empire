// Prepare reusable opaque MATERIAL swatches; no architecture is generated here.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),sharp=require('sharp');
const root=path.resolve(__dirname,'..'),dir=path.join(root,'assets/dungeon/shared-materials');
const names={walls:['planes','fissures','layers','pits'],floors:['calm','fine-crack','worn','marks']};
const hash=b=>crypto.createHash('sha256').update(b).digest('hex');
async function main(){
  const entries={},panels=[];
  for(const [family,variants] of Object.entries(names)){
    const atlasPath=`assets/dungeon/shared-materials/${family}-atlas-v1.png`,atlas=fs.readFileSync(path.join(root,atlasPath)),meta=await sharp(atlas).metadata();
    const qw=Math.floor(meta.width/2),qh=Math.floor(meta.height/2),inset=8;
    for(let i=0;i<variants.length;i++){
      const id=`${family}-${variants[i]}`,region={left:(i%2)*qw+inset,top:Math.floor(i/2)*qh+inset,width:qw-2*inset,height:qh-2*inset};
      const buffer=await sharp(atlas).extract(region).png().toBuffer();
      fs.writeFileSync(path.join(dir,id+'.png'),buffer);
      const stats=await sharp(buffer).stats();
      entries[id]={file:`${id}.png`,family,source:atlasPath,sourceSha256:hash(atlas),sourceRegion:region,sha256:hash(buffer),meanRGB:stats.channels.slice(0,3).map(c=>+c.mean.toFixed(2)),status:'material_appearance_pending_user_review'};
      panels.push({id,buffer,family});
    }
  }
  const renderProfile={top:{color:'#424e68',brightness:.98,opacity:.94,blur:.3},floor:{color:'#3c465d',brightness:.84,opacity:.64,blur:.4},north:{color:'#252e47',brightness:.61,opacity:.92,blur:.3},west:{color:'#1e263d',brightness:.49,opacity:.9,blur:.3},east_end:{color:'#1e263d',brightness:.49,opacity:.9,blur:.3},south_end:{color:'#252e47',brightness:.61,opacity:.92,blur:.3}};
  const catalog={id:'shared-dungeon-stone-materials-v1',status:'review_pending',canonicalStyle:'assets/dungeon/gloom-kit/reference.png',purpose:'Reuse these exact source materials across approved wireframe faces and later elements. This is not a catalogue of tile sprites.',rules:['No independent palette regeneration per orientation.','Only geometry and masks define joints, silhouettes and perspective.','Use the same material identity on a stone top and its upper facade.','Floors use the calmer family; wear and fissures remain sparse.','Source crops omit the atlas dividing lines and do not contain architectural silhouettes.'],renderProfile,entries};
  Object.assign(renderProfile,{wood:{color:'#59321d',brightness:.72,saturation:.68,opacity:.92,blur:.3},metal:{color:'#252b38',brightness:.88,opacity:.75,blur:.3}});
  fs.writeFileSync(path.join(dir,'catalog.json'),JSON.stringify(catalog,null,2)+'\n');
  const doorPath='assets/dungeon/shared-materials/door-surfaces-atlas-v1.png';
  if(fs.existsSync(path.join(root,doorPath))){
    const atlas=fs.readFileSync(path.join(root,doorPath)),meta=await sharp(atlas).metadata(),qw=Math.floor(meta.width/2);
    for(const [i,id] of ['door-oak','door-iron'].entries()){
      const region={left:i*qw+8,top:8,width:qw-16,height:meta.height-16},buffer=await sharp(atlas).extract(region).png().toBuffer(),stats=await sharp(buffer).stats();
      fs.writeFileSync(path.join(dir,id+'.png'),buffer);
      entries[id]={file:id+'.png',family:'doors',source:doorPath,sourceSha256:hash(atlas),sourceRegion:region,sha256:hash(buffer),meanRGB:stats.channels.slice(0,3).map(c=>+c.mean.toFixed(2)),status:'material_appearance_pending_user_review'};
    }
    fs.writeFileSync(path.join(dir,'catalog.json'),JSON.stringify(catalog,null,2)+'\n');
  }
  const body=panels.map((p,i)=>{const x=24+(i%4)*270,y=82+Math.floor(i/4)*315;return `<text x="${x}" y="${y}" fill="#cbd5e8" font-size="17">${p.id}</text><image href="data:image/png;base64,${p.buffer.toString('base64')}" x="${x}" y="${y+14}" width="248" height="248"/>`;}).join('');
  const sheet=`<svg xmlns="http://www.w3.org/2000/svg" width="1104" height="720"><rect width="1104" height="720" fill="#0b101b"/><g font-family="Arial,sans-serif"><text x="24" y="36" fill="#edf2ff" font-size="24">Matières communes · quatre variantes de murs et quatre de sol</text>${body}<text x="24" y="702" fill="#aebad0" font-size="14">Même palette · sources générées conservées · géométrie et joints définis séparément</text></g></svg>`;
  await sharp(Buffer.from(sheet)).png().toFile(path.join(dir,'material-board.png'));
  console.log(JSON.stringify(Object.fromEntries(Object.entries(entries).map(([k,v])=>[k,v.meanRGB])),null,2));
}
main().catch(e=>{console.error(e);process.exitCode=1;});
