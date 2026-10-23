// Focused offline continuity proposal. Does not replace active Godot PNGs.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
const R=require('./painted_material_renderer.cjs');
const {makeModel}=require('./export_painted_image_catalog.cjs');
const {ROOT,read,hash,render,parseLines}=R;
const OUT='docs/reference/wall-join-review',S=4,PITCH=256;
const isolated=JSON.parse(read('docs/reference/wireframe-overlays/catalog.json'));
const materials=JSON.parse(read('assets/dungeon/shared-materials/catalog.json'));
const studies=[
  {id:'horizontal',cells:[['w01_p00_e08',0,0],['w01_p00_e02',1,0]],crop:{left:760,top:20,width:680,height:540}},
  {id:'vertical-corner',cells:[['w08_p00_e01',0,0],['w12_p00_e00',0,1],['w04_p00_e02',1,1]],crop:{left:24,top:816,width:440,height:660}}
];
const write=(p,b)=>{fs.mkdirSync(path.dirname(path.join(ROOT,p)),{recursive:true});fs.writeFileSync(path.join(ROOT,p),b);};
const json=(p,b)=>write(p,JSON.stringify(b,null,2)+'\n');
const svg=(w,h,body)=>`<svg xmlns="http://www.w3.org/2000/svg" width="${w*S}" height="${h*S}" viewBox="0 0 ${w} ${h}">${body}</svg>`;

function dilateAlpha(rgba,width,height,radius){
  const a=new Uint8Array(width*height);for(let i=0;i<a.length;i++)a[i]=rgba[i*4+3];
  const row=new Uint8Array(a.length),out=new Uint8Array(a.length),queue=new Int32Array(Math.max(width,height));
  function pass(input,output,start,stride,count){
    let head=0,tail=0,next=0;
    for(let i=0;i<count;i++){
      while(next<=Math.min(count-1,i+radius)){
        const value=input[start+next*stride];
        while(tail>head&&input[start+queue[tail-1]*stride]<=value)tail--;
        queue[tail++]=next++;
      }
      while(queue[head]<i-radius)head++;
      output[start+i*stride]=input[start+queue[head]*stride];
    }
  }
  for(let y=0;y<height;y++)pass(a,row,y*width,1,width);
  for(let x=0;x<width;x++)pass(row,out,x,width,height);
  return out;
}

function sourceGeometry(file,x,y){
  const input=read(file).toString(),dx=x*PITCH,dy=y*PITCH;
  const lines=parseLines(input).map(l=>`<line x1="${l.a[0]+dx}" y1="${l.a[1]+dy}" x2="${l.b[0]+dx}" y2="${l.b[1]+dy}" stroke="#ff00ff" stroke-width="${l.width}"/>`).join('');
  const polygons=[...input.matchAll(/<(?:polygon|path)\b[^>]*fill="#ffffff"[^>]*\/>/g)].flatMap(([xml])=>xml.startsWith('<polygon')?[xml.match(/points="([^"]+)"/)[1].split(' ').map(p=>p.split(',').map(Number))]:xml.match(/d="([^"]+)"/)[1].split('M').filter(Boolean).map(p=>p.replace(/Z$/,'').split('L').map(p=>p.split(',').map(Number))));
  const d=polygons.map(ps=>{const a=ps.reduce((s,p,i)=>s+p[0]*ps[(i+1)%ps.length][1]-p[1]*ps[(i+1)%ps.length][0],0);if(a<0)ps.reverse();return 'M'+ps.map(p=>[p[0]+dx,p[1]+dy].join(',')).join('L')+'Z';}).join('');
  return {lines,fill:`<path d="${d}" fill="#fff"/>`};
}

function repeatMaterials(faces){
  const ids=['walls-planes','walls-fissures','walls-layers','walls-pits'];
  for(const f of faces){
    if(!f.part.includes('wall'))continue;
    const horizontal=/north|south/.test(f.part),axis=horizontal?0:1;
    const q=((f.p[axis]%1)+1)%1,upper=f.p[2]>=.94/6-1e-5;
    const cuts=upper?[0,1.6/6,3.5/6]:[0,.7/6,2.6/6,4.5/6];
    const k=Math.max(0,cuts.filter(c=>q>=c-1e-5).length-1);
    f.materialId=ids[horizontal?(upper?[0,1,2]:[0,3,0,2])[k]:(upper?[0,3,1]:[0,2,0,3])[k]];
  }
}

async function study(spec){
  const w=304+Math.max(...spec.cells.map(c=>c[1]))*PITCH,h=352+Math.max(...spec.cells.map(c=>c[2]))*PITCH;
  const model={id:'join-review/'+spec.id,size:[w,h],anchor:[24,88],surfaces:[],floor:false,clipPaint:true,resolveMaterials:repeatMaterials};
  let fills='',lines='';const originals=[],sourceHashes={};
  for(const [key,x,y] of spec.cells){
    const id='cells/'+key,file='assets/dungeon/wireframe-cells/'+key+'.svg';
    const m=makeModel(id,isolated.entries[id]);
    model.surfaces.push(...m.surfaces.map(s=>({...s,points:s.points.map(p=>[p[0]+x,p[1]+y,p[2]])})));
    const g=sourceGeometry(file,x,y);fills+=g.fill;lines+=g.lines;
    const pngFile=OUT+'/source/'+key+'.png',png=read(pngFile);
    originals.push({input:png,left:x*PITCH*S,top:y*PITCH*S});
    sourceHashes[file]=hash(read(file));sourceHashes[pngFile]=hash(png);
  }
  // A single nonzero path rasterizes the union once. Adjacent separate SVG
  // fills would themselves leave a half-alpha line inside the whole painting.
  model.silhouette=`<path d="${[...fills.matchAll(/d="([^"]*)"/g)].map(m=>m[1]).join('')}" fill="#fff"/>`;
  const guide=svg(w,h,lines),result=await render(model,guide,materials);
  const before=await sharp({create:{width:w*S,height:h*S,channels:4,background:'#080d16'}}).composite(originals).png().toBuffer();
  const rgba=await sharp(result.png).ensureAlpha().raw().toBuffer(),tiles=[],tileRecords=[],rawTiles=[];
  // Split the completed painting using the existing cell volume and anchor.
  // Reassembly below uses ordinary source-over, like the Godot sprite display.
  for(const [key,x,y] of spec.cells){
    const baseline=read(OUT+'/source/'+key+'.png');
    const {data,info}=await sharp(baseline).ensureAlpha().raw().toBuffer({resolveWithObject:true});
    for(let py=0;py<info.height;py++)for(let px=0;px<info.width;px++){
      const to=(py*info.width+px)*4,from=((py+y*PITCH*S)*w*S+px+x*PITCH*S)*4;
      for(let c=0;c<3;c++)data[to+c]=rgba[from+c];
    }
    const overlap=dilateAlpha(data,info.width,info.height,8);let filterGuardPixels=0;
    // A two-reference-pixel overlap INSIDE the common solid stone protects
    // independently mipmapped sprites. Every duplicated pixel has the same RGB.
    // Never extend the outer silhouette; use the common visible painting.
    for(let py=0;py<info.height;py++)for(let px=0;px<info.width;px++){
      const i=(py*info.width+px)*4+3,global=((py+y*PITCH*S)*w*S+px+x*PITCH*S)*4+3;
      if(rgba[global]===255&&overlap[py*info.width+px]>data[i]){data[i]=overlap[py*info.width+px];filterGuardPixels++;}
    }
    rawTiles.push({key,x,y,data,info,changedAlphaPixels:0,filterGuardPixels});
  }
  let sharedCoveragePixels=0;
  // Two half-covered adjacent pixels source-over to .75, not 1. At a shared
  // border give one cell the complete geometric coverage instead of retaining
  // two semi-transparent fragments. Colors already come from the same painting.
  for(let py=0;py<h*S;py++)for(let px=0;px<w*S;px++){
    const members=[];
    for(const tile of rawTiles){
      const tx=px-tile.x*PITCH*S,ty=py-tile.y*PITCH*S;
      if(tx<0||ty<0||tx>=tile.info.width||ty>=tile.info.height)continue;
      const i=(ty*tile.info.width+tx)*4+3,a=tile.data[i];if(a)members.push({tile,i,a});
    }
    if(members.length<2)continue;
    const target=rgba[(py*w*S+px)*4+3];
    const combined=255*(1-members.reduce((v,m)=>v*(1-m.a/255),1));
    if(Math.abs(combined-target)<.5)continue;
    members.sort((a,b)=>b.a-a.a);
    for(let i=0;i<members.length;i++){
      const m=members[i],alpha=i===0?target:0;
      if(m.a!==alpha){m.tile.data[m.i]=alpha;m.tile.changedAlphaPixels++;}
    }
    sharedCoveragePixels++;
  }
  for(const {key,x,y,data,info,changedAlphaPixels,filterGuardPixels} of rawTiles){
    const png=await sharp(data,{raw:info}).png().toBuffer(),file=`${OUT}/${spec.id}/${key}.png`;
    write(file,png);tiles.push({input:png,left:x*PITCH*S,top:y*PITCH*S});
    tileRecords.push({file,cell:[x,y],sha256:hash(png),alphaSha256:hash(await sharp(png).extractChannel(3).raw().toBuffer()),changedAlphaPixels,filterGuardPixels});
  }
  const joined=await sharp({create:{width:w*S,height:h*S,channels:4,background:{r:0,g:0,b:0,alpha:0}}}).composite(tiles).png().toBuffer();
  const after=await sharp(joined).flatten({background:'#080d16'}).png().toBuffer();
  const joinedRaw=await sharp(joined).ensureAlpha().raw().toBuffer();
  let alphaPixelsDifferentFromWhole=0,maxAlphaDifference=0;
  for(let i=3;i<rgba.length;i+=4){const d=Math.abs(rgba[i]-joinedRaw[i]);if(d)alphaPixelsDifferentFromWhole++;maxAlphaDifference=Math.max(maxAlphaDifference,d);}
  write(`${OUT}/${spec.id}-before.png`,before);write(`${OUT}/${spec.id}-after.png`,after);
  write(`${OUT}/${spec.id}-whole.png`,result.png);write(`${OUT}/${spec.id}-overlay.png`,result.overlay);
  const cropBefore=await sharp(before).extract(spec.crop).png().toBuffer(),cropAfter=await sharp(after).extract(spec.crop).png().toBuffer();
  write(`${OUT}/${spec.id}-detail-before.png`,cropBefore);write(`${OUT}/${spec.id}-detail-after.png`,cropAfter);
  json(`${OUT}/${spec.id}-report.json`,{...result.report,sourceHashes,tiles:tileRecords,sharedCoveragePixels,filterGuardSourcePixels:8,reassembly:{alphaPixelsDifferentFromWhole,maxAlphaDifference},scope:'Two focused assemblies. Shared border pixels use common RGB, interior overlap for mipmaps and single-cell alpha ownership on nonopaque contour pixels. Common whole-stone painting, existing cell positions and volumes. Not a replacement for the production catalog.'});
  console.log(JSON.stringify({study:spec.id,faces:result.report.faces.length,tiles:tiles.length,alphaDifference:result.report.alphaPixelsDifferentFromModel}));
  return {before:cropBefore,after:cropAfter};
}

async function main(){
  const outputs=[];for(const spec of studies)outputs.push(await study(spec));
  const W=1500,H=1540,layers=[];let labels='';
  for(const [i,out] of outputs.entries()){
    const y=100+i*710;
    labels+=`<text x="28" y="${y-18}" fill="#d4deef" font-size="24">${i?'Raccord vertical et retour d’angle':'Raccord horizontal'}</text>`;
    for(const [j,k] of ['before','after'].entries()){
      const thumb=await sharp(out[k]).resize({width:704,height:630,fit:'inside'}).png().toBuffer();
      const meta=await sharp(thumb).metadata(),x=24+j*750;
      labels+=`<text x="${x+12}" y="${y+24}" fill="#a9bbd5" font-size="20">${j?'Après — pierre entière puis découpe':'Avant — fragments indépendants'}</text>`;
      layers.push({input:thumb,left:x+Math.floor((704-meta.width)/2),top:y+48});
    }
  }
  const bg=Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}"><rect width="100%" height="100%" fill="#080d16"/><g font-family="Arial"><text x="28" y="40" fill="#eef2fa" font-size="30">Continuité des pierres · proposition de correction</text>${labels}<text x="28" y="${H-20}" fill="#a9bbd5" font-size="17">Mêmes volumes, mêmes matières et finition B · PNG séparés réassemblés</text></g></svg>`);
  write(OUT+'/comparison.png',await sharp(bg).composite(layers).png().toBuffer());
}
main().catch(e=>{console.error(e.stack);process.exitCode=1;});
