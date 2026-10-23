// NW review renderer. Original one-time test retained; --materials-v2 uses
// the subsequently approved shared-material workflow on this same geometry.
// Offline review only. Does not export or modify any Godot asset catalogue.
// No input from the rejected painted v1-v4 sprites.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),sharp=require('sharp');
const {geometry}=require('./export_wireframe_cell_kit.cjs');
const richer=process.argv.includes('--materials-v2');
const root=path.resolve(__dirname,'..'),dir=path.join(root,richer?'docs/reference/nw-material-review-v2':'docs/reference/nw-mask-test');
const output=`assets/dungeon/gloom-kit/proposals/${richer?'nw-shared-materials-v2':'nw-masked-experiment'}.png`;
const guidePath='docs/reference/wireframe-overlays/cells/w09_p00_e00.svg';
const constructionPath='docs/reference/painted-corner-review/nw-construction.svg';
const read=p=>fs.readFileSync(path.join(root,p));
const guide=read(guidePath).toString(),construction=read(constructionPath).toString();
const W=304,H=352,S=4;
const lines=[...guide.matchAll(/<line\b[^>]*\/>/g)].map(([xml])=>{
  const attrs=Object.fromEntries([...xml.matchAll(/([\w-]+)="([^"]*)"/g)].map(m=>[m[1],m[2]]));
  return {a:[+attrs.x1,+attrs.y1],b:[+attrs.x2,+attrs.y2],width:+attrs['stroke-width'],xml};
});
const sub=(a,b)=>a.map((v,i)=>v-b[i]),cross=(a,b)=>a[0]*b[1]-a[1]*b[0];
const dist=(a,b)=>Math.hypot(...sub(a,b)),lerp=(a,b,t)=>a.map((v,i)=>v+(b[i]-v)*t);
const area=p=>p.reduce((s,a,i)=>s+cross(a,p[(i+1)%p.length]),0)/2;
const str=p=>p.map(a=>a.join(',')).join(' ');
const poly=(p,attrs)=>`<polygon points="${str(p)}" ${attrs}/>`;
const body=s=>s.replace(/^<svg[^>]*>/,'').replace(/<\/svg>\s*$/,'');
const svg=b=>`<svg xmlns="http://www.w3.org/2000/svg" width="${W*S}" height="${H*S}" viewBox="0 0 ${W} ${H}">${b}</svg>`;
const sha=b=>crypto.createHash('sha256').update(b).digest('hex');
const inside=(p,ps)=>{let yes=false;for(let i=0,j=ps.length-1;i<ps.length;j=i++){
  const a=ps[i],b=ps[j];if((a[1]>p[1])!==(b[1]>p[1])&&p[0]<(b[0]-a[0])*(p[1]-a[1])/(b[1]-a[1])+a[0])yes=!yes;
}return yes;};

// Split the existing visible planar drawing at intersections and enumerate
// bounded regions. This adds NO new architectural lines or joints.
const vertices=[],edges=new Set();
function vertex(p){let k=vertices.findIndex(q=>dist(p,q)<.0001);if(k<0){k=vertices.length;vertices.push(p);}return k;}
for(const l of lines){
  const d=sub(l.b,l.a),length2=d[0]**2+d[1]**2,cuts=[0,1];
  for(const m of lines){
    const e=sub(m.b,m.a),den=cross(d,e),v=sub(m.a,l.a);
    if(Math.abs(den)>1e-10){const t=cross(v,e)/den,u=cross(v,d)/den;
      if(t>1e-8&&t<1-1e-8&&u>=-1e-7&&u<=1+1e-7)cuts.push(t);
    }else if(Math.abs(cross(v,d))<.0001){for(const p of [m.a,m.b]){const q=sub(p,l.a),t=(q[0]*d[0]+q[1]*d[1])/length2;if(t>0&&t<1)cuts.push(t);}}
  }
  cuts.sort((a,b)=>a-b);
  for(let i=1;i<cuts.length;i++){
    const a=vertex(lerp(l.a,l.b,cuts[i-1])),b=vertex(lerp(l.a,l.b,cuts[i]));
    if(a!==b)edges.add([a,b].sort((a,b)=>a-b).join(':'));
  }
}
const neighbours=vertices.map(()=>[]);
for(const key of edges){const [a,b]=key.split(':').map(Number);neighbours[a].push(b);neighbours[b].push(a);}
for(let i=0;i<vertices.length;i++)neighbours[i].sort((a,b)=>Math.atan2(vertices[a][1]-vertices[i][1],vertices[a][0]-vertices[i][0])-Math.atan2(vertices[b][1]-vertices[i][1],vertices[b][0]-vertices[i][0]));
const visited=new Set(),regions=[];
for(let u=0;u<vertices.length;u++)for(const v of neighbours[u]){
  if(visited.has(`${u}:${v}`))continue;
  let a=u,b=v,ps=[];
  for(let guard=0;guard<1000;guard++){
    const k=`${a}:${b}`;if(visited.has(k))break;visited.add(k);ps.push(vertices[a]);
    const ns=neighbours[b],c=ns[(ns.indexOf(a)-1+ns.length)%ns.length];a=b;b=c;
    if(a===u&&b===v)break;
  }
  if(area(ps)>1e-5)regions.push(ps);
}
const wall=geometry(9,0,0,{standalone:true}).svg;
const facades=[...wall.matchAll(/<polygon points="([^"]+)"/g)].map(m=>m[1].split(' ').map(s=>s.split(',').map(Number)));
const tops=[...wall.matchAll(/<path d="([^"]+)" fill="#ffffff"/g)].flatMap(m=>m[1].split('M').filter(Boolean).map(p=>p.replace(/Z$/,'').split('L').map(s=>s.split(',').map(Number))));
const faceNames=['north','east_end','west','south_end'];
function interior(p){const a=p[0],b=p[1],d=sub(b,a),len=Math.hypot(...d);return [(a[0]+b[0])/2-d[1]/len*.01,(a[1]+b[1])/2+d[0]/len*.01];}
const faces=regions.map((region,id)=>{
  // T-junction vertices belong to the neighbouring stone. Merge collinear
  // runs for interior bevels so they do not introduce spurious interruptions.
  const p=region.filter((b,i)=>{const a=region[(i-1+region.length)%region.length],c=region[(i+1)%region.length];return Math.abs(cross(sub(b,a),sub(c,b)))>.0001;});
  const probe=interior(p);let kind='floor';
  if(tops.some(q=>inside(probe,q)))kind='top';else {const i=facades.findIndex(q=>inside(probe,q));if(i>=0)kind=faceNames[i];}
  return {id,points:p,kind};
});

async function main(){
  fs.mkdirSync(dir,{recursive:true});
  const material=read('docs/reference/nw-mask-test/stone-material.png');
  const catalog=richer?JSON.parse(read('assets/dungeon/shared-materials/catalog.json')):null;
  const settings=richer?catalog.renderProfile:{top:{color:'#424e68',brightness:.96,opacity:.6,blur:.3},floor:{color:'#3c465d',brightness:.85,opacity:.34,blur:1.3},north:{color:'#252e47',brightness:.58,opacity:.6,blur:.3},west:{color:'#1e263d',brightness:.47,opacity:.6,blur:.3},east_end:{color:'#1e263d',brightness:.47,opacity:.6,blur:.3},south_end:{color:'#252e47',brightness:.58,opacity:.6,blur:.3}};
  const wallIds=['walls-planes','walls-fissures','walls-layers','walls-pits'],floorIds=['floors-calm','floors-fine-crack','floors-worn','floors-marks'];
  const floorCycle=[0,2,0,3,0,2,0,1,2,0,3,0,2,0,1,0,2,0,3];
  const slot=(q,upper)=>(upper?[0,1.6/6,3.5/6]:[0,.7/6,2.6/6,4.5/6]).filter(x=>q>=x-1e-6).length-1;
  for(const f of faces){
    if(!richer){f.materialId='legacy';continue;}
    const p=interior(f.points),x=(p[0]-24)/256,y=(p[1]-88)/256;
    if(f.kind==='floor'){f.materialId=floorIds[floorCycle[f.id%floorCycle.length]];continue;}
    let q,z,axis;
    if(f.kind==='top'){z=1.88/6;const wx=x+.18*z,wy=y+.9*z;axis=wy<1/6?'north':'west';q=axis==='north'?wx:wy;}
    else if(f.kind==='north'){z=(1/6-y)/.9;q=x+.18*z;axis='north';}
    else if(f.kind==='west'){z=(1/6-x)/.18;q=y+.9*z;axis='west';}
    else if(f.kind==='east_end'){z=(1-x)/.18;q=.999;axis='north';}
    else {z=(1-y)/.9;q=.999;axis='west';}
    const upper=z>=.94/6-1e-5,k=slot(q,upper);
    f.stoneIdentity=`${axis}-${upper?'upper':'lower'}-${k}`;
    f.materialId=wallIds[axis==='north'?(upper?[0,1,2]:[0,3,0,2])[k]:(upper?[0,3,1]:[0,2,0,3])[k]];
  }
  const textures={};
  for(const f of faces){const key=`${f.kind}-${f.materialId}`,s=settings[f.kind];if(textures[key])continue;
    const source=richer?read('assets/dungeon/shared-materials/'+catalog.entries[f.materialId].file):material;
    textures[key]=(await sharp(source).modulate({brightness:s.brightness,saturation:richer?.98:.88}).blur(s.blur).png().toBuffer()).toString('base64');
  }
  let defs='<defs>',paint='',bevels='';
  for(const key of Object.keys(textures))defs+=`<image id="texture-${key}" href="data:image/png;base64,${textures[key]}" width="350" height="350"/>`;
  for(const f of faces){
    const p=f.points,s=settings[f.kind],clip=`face-${f.id}`;
    defs+=`<clipPath id="${clip}">${poly(p,'')}</clipPath>`;
    const minx=Math.min(...p.map(q=>q[0])),miny=Math.min(...p.map(q=>q[1]));
    // Only material coordinates vary; geometry stays fixed. No projection of
    // painted bricks, because this source contains no masonry or contour.
    const maxx=Math.max(...p.map(q=>q[0])),maxy=Math.max(...p.map(q=>q[1])),span=richer?Math.max(maxx-minx,maxy-miny)*1.15:350,zoom=span/350;
    const tx=richer?minx-span*.065:minx-27-(f.id*13%37),ty=richer?miny-span*.065:miny-25-(f.id*19%41);
    paint+=`<g clip-path="url(#${clip})">${poly(p,`fill="${s.color}"`)}<use href="#texture-${f.kind}-${f.materialId}" transform="translate(${tx} ${ty}) scale(${zoom})" opacity="${s.opacity}"/></g>`;
    // Small interior edge highlights. No external chamfer changes or extra row.
    const highlight=f.kind==='floor'?'#76839b':f.kind==='top'?'#8694b2':'#52617e';
    for(let i=0;i<p.length;i++){
      const a=p[i],b=p[(i+1)%p.length],d=sub(b,a),len=Math.hypot(...d);if(len<4)continue;
      const n=[-d[1]/len,d[0]/len],lit=n[0]+n[1]>0;
      const inset=f.kind==='floor'?1.4:1.9,cut=Math.min(1.8,len*.08),u=d.map(v=>v/len);
      const c=a.map((v,j)=>v+n[j]*inset+u[j]*cut),e=b.map((v,j)=>v+n[j]*inset-u[j]*cut);
      if(richer){
        // Irregular painted bevel stays INSIDE the locked face. Its outer
        // architectural edge and mortar centre never move.
        const outer=[],inner=[],count=Math.max(3,Math.ceil(len/11));
        for(let j=0;j<=count;j++){const t=j/count,pt=lerp(c,e,t),r=.5+.5*Math.sin((f.id+1)*13+i*7+j*2.7),width=(f.kind==='floor'?.65:1.25)*(0.6+r);
          outer.push(pt);inner.push(pt.map((v,k)=>v+n[k]*width));}
        bevels+=poly([...outer,...inner.reverse()],`fill="${lit?highlight:'#070e1c'}" opacity="${lit?(f.kind==='floor'?.3:.55):.42}" clip-path="url(#${clip})"`);
      }else bevels+=`<line x1="${c[0]}" y1="${c[1]}" x2="${e[0]}" y2="${e[1]}" stroke="${lit?highlight:'#090f1d'}" stroke-width="${f.kind==='floor'?.7:1}" opacity="${lit?(f.kind==='floor'?.35:.55):.4}" clip-path="url(#${clip})"/>`;
    }
  }
  defs+='<filter id="violet-glow" x="-60%" y="-60%" width="220%" height="220%"><feGaussianBlur stdDeviation="1.4"/></filter></defs>';
  // Restrained local accent, entirely inside one lower north-facade stone.
  const accent='<path d="M245 122 L241 116 L244 111 L241 106 M241 116 L236 114" fill="none" stroke="#a65be8" stroke-width="2" opacity=".25" filter="url(#violet-glow)"/><path d="M245 122 L241 116 L244 111 L241 106 M241 116 L236 114" fill="none" stroke="#a578df" stroke-width=".55" opacity=".8"/>';
  const ink=lines.map(l=>l.xml.replace('#ff00ff',l.width===1.5?'#171e2e':'#0c1220')).join('');
  const drawing=svg(defs+paint+bevels+accent+ink);
  fs.writeFileSync(path.join(dir,'nw-painted-test.svg'),drawing);
  // The silhouette mask is the unchanged approved construction rendered at 4x.
  // Both fill and outline coverage belong to that reference. Native texture
  // alpha is deliberately not the silhouette in this explicitly allowed test.
  const expected=await sharp(Buffer.from(svg(body(construction)))).ensureAlpha().raw().toBuffer();
  const rendered=await sharp(Buffer.from(drawing)).ensureAlpha().raw().toBuffer();
  const alpha=Buffer.alloc(W*S*H*S),jointMask=await sharp(Buffer.from(svg(body(guide)))).ensureAlpha().raw().toBuffer();
  for(let i=0;i<alpha.length;i++){alpha[i]=expected[i*4+3];rendered[i*4+3]=alpha[i];}
  const final=await sharp(rendered,{raw:{width:W*S,height:H*S,channels:4}}).png().toBuffer();
  fs.writeFileSync(path.join(root,output),final);
  await sharp(alpha,{raw:{width:W*S,height:H*S,channels:1}}).png().toFile(path.join(dir,'silhouette-mask.png'));
  fs.writeFileSync(path.join(dir,'face-masks.svg'),svg('<defs>'+faces.map(f=>`<clipPath id="face-${f.id}">${poly(f.points,'')}</clipPath>`).join('')+'</defs>'+faces.map(f=>poly(f.points,`fill="hsl(${f.id*67%360},60%,50%)" stroke="#ffffff" stroke-width=".35"`)).join('')));
  fs.writeFileSync(path.join(dir,'locked-joints.svg'),svg(ink));
  const overlay=await sharp(Buffer.from(svg(body(guide)))).png().toBuffer();
  const combined=await sharp(final).composite([{input:overlay}]).png().toBuffer();
  fs.writeFileSync(path.join(dir,'nw-overlay.png'),combined);
  const thin=await sharp(Buffer.from(svg(body(guide).replace(/stroke-width="[^"]+"/g,'stroke-width="0.45"')))).png().toBuffer();
  await sharp(final).composite([{input:thin}]).png().toFile(path.join(dir,'nw-thin-overlay.png'));
  // Independent decode checks the exported PNG, not just the working buffer.
  const decoded=await sharp(final).ensureAlpha().raw().toBuffer();
  let alphaDifferences=0,maxAlphaDifference=0,visibleLineSamples=0,transparentLineSamples=0;
  for(let i=0;i<alpha.length;i++){const d=Math.abs(decoded[i*4+3]-expected[i*4+3]);if(d)alphaDifferences++;maxAlphaDifference=Math.max(maxAlphaDifference,d);if(jointMask[i*4+3]>250){visibleLineSamples++;if(decoded[i*4+3]===0)transparentLineSamples++;}}
  const counts=Object.fromEntries(Object.keys(settings).map(k=>[k,faces.filter(f=>f.kind===k).length]));
  const segmentTuples=text=>[...text.matchAll(/<line\b[^>]*\/>/g)].map(([l])=>['x1','y1','x2','y2','stroke-width'].map(k=>Number(l.match(new RegExp(k+'="([^"]+)"'))[1])));
  const jointsMatch=JSON.stringify(segmentTuples(fs.readFileSync(path.join(dir,'locked-joints.svg'),'utf8')))===JSON.stringify(segmentTuples(guide));
  if(!jointsMatch)throw Error('Exported joint layer differs from the source guide.');
  const report={scope:richer?'Approved shared-material method, richer appearance review on the same NW corner. No scene integration.':'Historical one-time NW masked-material experiment.',materialLibrary:richer?'assets/dungeon/shared-materials/catalog.json':null,output,canvas:[W*S,H*S],anchor:[24*S,88*S],cellPitch:256*S,guide:guidePath,guideSha256:sha(guide),materialSha256:richer?Object.fromEntries(Object.entries(catalog.entries).map(([id,e])=>[id,e.sha256])):sha(material),constructionSha256:sha(construction),sourceSegmentCount:lines.length,segmentsCopiedWithoutCoordinateChanges:true,maximumJointEndpointDisplacement:0,alphaPixelsDifferentFromConstruction:alphaDifferences,maximumAlphaDifference:maxAlphaDifference,visibleLineSamples,transparentLineSamples,faceCounts:counts,sourceSegments:lines.map(({a,b,width})=>({a,b,width})),faces,limitation:'Exact construction and raster-alpha equality are verified for this isolated sprite. They do not establish material fidelity, artistic approval, connected-tile behavior, or approval for other orientations.'};
  report.exportedJointLayerMatchesGuide=jointsMatch;
  if(richer){
    const previous=await sharp(read('assets/dungeon/gloom-kit/proposals/nw-masked-experiment.png')).ensureAlpha().raw().toBuffer();
    report.alphaPixelsDifferentFromInitialTest=0;
    for(let i=0;i<alpha.length;i++)if(previous[i*4+3]!==decoded[i*4+3])report.alphaPixelsDifferentFromInitialTest++;
    const physical=new Map();report.physicalStoneMaterialConflicts=[];
    for(const f of faces.filter(f=>f.stoneIdentity)){const prior=physical.get(f.stoneIdentity);if(prior&&prior!==f.materialId)report.physicalStoneMaterialConflicts.push(f.stoneIdentity);physical.set(f.stoneIdentity,f.materialId);}
  }
  fs.writeFileSync(path.join(dir,'validation.json'),JSON.stringify(report,null,2)+'\n');
  const panels=[{buffer:final,label:richer?'Sprite — matières variées':'Sprite — essai avec masques'},{buffer:combined,label:'Même image + wireframe magenta'}];
  const panel=(p,i)=>`<text x="${28+i*624}" y="77" font-size="19">${p.label}</text><rect x="${28+i*624}" y="98" width="600" height="695" fill="url(#check)"/><image href="data:image/png;base64,${p.buffer.toString('base64')}" x="${28+i*624}" y="98" width="600" height="695"/>`;
  const sheet=`<svg xmlns="http://www.w3.org/2000/svg" width="1280" height="860"><defs><pattern id="check" width="24" height="24" patternUnits="userSpaceOnUse"><rect width="24" height="24" fill="#101624"/><path d="M0 0H12V12H0Z M12 12H24V24H12Z" fill="#172031"/></pattern></defs><rect width="1280" height="860" fill="#0b101b"/><g font-family="Arial,sans-serif" fill="#edf2ff"><text x="28" y="35" font-size="24">Coin supérieur gauche · matière sur géométrie fixe</text>${panels.map(panel).join('')}<text x="28" y="833" fill="#acbad1" font-size="15">${richer?'Matières partagées · géométrie conservée':'Essai initial'} · aspect à valider · aucune intégration Godot</text></g></svg>`;
  await sharp(Buffer.from(sheet)).png().toFile(path.join(dir,'comparison.png'));
  if(richer){
    const beforePanels=[{buffer:read('assets/dungeon/gloom-kit/proposals/nw-masked-experiment.png'),label:'Premier essai — une matière uniforme'},{buffer:final,label:'Nouvelle version — matières variées'}];
    const comparison=sheet.replace(panels.map(panel).join(''),beforePanels.map(panel).join('')).replace('Coin supérieur gauche · matière sur géométrie fixe','Même géométrie · évolution des matières');
    await sharp(Buffer.from(comparison)).png().toFile(path.join(dir,'before-after.png'));
  }
  console.log(JSON.stringify({output,faceCounts:counts,segments:lines.length,alphaDifferences,maxAlphaDifference,transparentLineSamples,exportedJointLayerMatchesGuide:jointsMatch,alphaPixelsDifferentFromInitialTest:report.alphaPixelsDifferentFromInitialTest,physicalStoneMaterialConflicts:report.physicalStoneMaterialConflicts},null,2));
}
main().catch(e=>{console.error(e);process.exitCode=1;});
