// Presentation and integrity evidence for the selected wall integration.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),sharp=require('sharp');
const P=require('./isometric_paint_geometry.cjs');
const OUT='docs/reference/isometric-wall-variation-review/v2-subvariants/integration';
const abs=p=>path.join(P.ROOT,p),read=p=>JSON.parse(fs.readFileSync(abs(p),'utf8').replace(/^\uFEFF/,''));
const sha=p=>crypto.createHash('sha256').update(fs.readFileSync(abs(p))).digest('hex');
const save=(p,data)=>fs.writeFileSync(abs(OUT+'/'+p),data);
const rect=region=>({left:region[0],top:region[1],width:region[2],height:region[3]});
async function main(){
 const baseline=read(OUT+'/before/assets/dungeon/isometric-kit/catalog.json'),active=read('assets/dungeon/isometric-kit/catalog.json');
 let unchanged=0;
 for(const [id,entry] of Object.entries(baseline.atlas.regions)){
  const current=active.atlas.regions[id];if(!current)throw Error('Lost old region '+id);
  const a=await sharp(abs(OUT+'/before/assets/dungeon/isometric-kit/atlas-256.png')).extract(rect(entry.region)).raw().toBuffer();
  const b=await sharp(abs('assets/dungeon/isometric-kit/atlas-256.png')).extract(rect(current.region)).raw().toBuffer();
  if(!a.equals(b))throw Error('Old region pixels changed: '+id);
  const {region:ar,...am}=entry,{region:br,...bm}=current;
  if(JSON.stringify(am)!==JSON.stringify(bm))throw Error('Old region metadata changed: '+id);
  unchanged++;
 }
 const selection=read('docs/reference/isometric-wall-variation-review/v2-subvariants/selection.json');
 for(const [file,hash] of Object.entries(selection.reviewedFiles))if(sha(file)!==hash)throw Error('Selected source changed: '+file);
 const prepared=read(OUT+'/prepared.json');
 const geom=read(OUT+'/geometry.json');
 if(geom.baseSHA256!==sha(geom.baseGeometry))throw Error('Base geometry changed');
 const terminalChecks=[];
 for(const m of geom.models){
  const base=P.models.find(p=>p.id===m.base),axis=m.id.startsWith('wall-h')?0:1;
  if(m.bounds.min[axis]!==base.bounds.min[axis]||m.bounds.max[axis]!==base.bounds.max[axis]||m.bounds.min[2]!==0||m.bounds.max[2]!==P.H)throw Error('Wall endpoint/height drift: '+m.id);
  terminalChecks.push(m.id);
 }
 // Exact same game pixels before/after, cropped to the corridor from feedback.
 const labels=['Avant — écarts de palette','Après — palette commune'];
 const w=1340,h=470,layers=[];
 let body=`<rect width="${w}" height="${h}" fill="#0b1019"/>`;
 for(const [i,file] of ['palette-v2/before/reference-seed17.png','reference-seed17.png'].entries()){
  body+=`<text x="${22+i*670}" y="37" font-size="24" fill="#e6eaf4">${labels[i]}</text>`;
  layers.push({input:await sharp(abs(OUT+'/'+file)).extract({left:60,top:300,width:550,height:330}).resize(640,384).png().toBuffer(),left:15+i*670,top:66});
 }
 await sharp(Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" style="font-family:Arial,sans-serif">${body}</svg>`)).composite(layers).png().toFile(abs(OUT+'/palette-v2/comparison.png'));
 // Show both painted projections together with their exact bright guides.
 let board='<rect width="1260" height="1080" fill="#0b1019"/><text x="20" y="32" font-size="24" fill="#e6eaf4">Murs intégrés — neuf variantes, deux orientations</text>';
 const tiles=[];
 for(const [i,id] of ['a1','a2','a3','c1','c2','c3','f1','f2','f3'].entries()){
  const x=20+(i%3)*415,y=56+Math.floor(i/3)*342;
  board+=`<text x="${x}" y="${y+22}" font-size="22" fill="#e6eaf4">${id.toUpperCase()}</text><text x="${x}" y="${y+318}" font-size="14" fill="#98a9c2">Dessous : guides communs en magenta</text>`;
  for(const [j,axis] of ['h','v'].entries())for(const [row,dir] of ['sprites','overlays'].entries()){
   const pic=await sharp(abs(OUT+'/'+dir+`/wall-${axis}-0-${id}.png`)).resize({width:180}).png().toBuffer();
   tiles.push({input:pic,left:x+j*195,top:y+36+row*125});
  }
 }
 await sharp(Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="1260" height="1080" style="font-family:Arial,sans-serif">${board}</svg>`)).composite(tiles).png().toFile(abs(OUT+'/prepared-comparison.png'));
 const focused=read(OUT+'/observations.json'),seed17=focused.find(o=>o.capture==='reference-seed17'),restored=focused.find(o=>o.capture==='reference-restored17');
 const stability=sha(OUT+'/reference-seed17.png')===sha(OUT+'/reference-restored17.png');
 if(!stability)throw Error('Seed restoration changed image');
 const evidence={date:'2026-10-25',unchangedPreviousRegions:unchanged,unchangedSelectionFiles:Object.keys(selection.reviewedFiles).length,terminalProfilesChecked:terminalChecks.length,
  preparedItems:prepared.items.length,atlas:{regions:active.spriteCount,size:[active.atlas.width,active.atlas.height],pngBytes:active.atlas.sourceBytes,rgbaBytes:active.atlas.uncompressedRGBABytes},
  seedRestorationIdentical:stability,referenceCounts:seed17.counts,sixRoomCounts:focused.find(o=>o.capture==='six-room-native').counts,
  captures:focused.length,scope:'Prepared pixel and geometry integrity plus visual capture evidence. No gameplay test suite or device profile.'};
 save('pixel-validation.json',JSON.stringify(evidence,null,2)+'\n');
 console.log(JSON.stringify(evidence));
}
main().catch(e=>{console.error(e.stack);process.exitCode=1;});
