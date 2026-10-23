// Isolated appearance study using the approved offline material-mask workflow.
// Does not change the active renderer, source wireframes, materials or Godot PNGs.
const fs = require('node:fs'), path = require('node:path'), sharp = require('sharp');
const { ROOT, read, hash } = require('./painted_material_renderer.cjs');
const OUT = 'docs/reference/stone-edge-review';
// Frozen pre-promotion inputs: active assets now use B, so never read them as A.
const SOURCE = OUT + '/a-current.png';
const REPORT = OUT + '/source/faces.json';
const GUIDE = OUT + '/source/guide.svg';
const MATERIALS = OUT + '/source/materials.json';
const variants = [
  { id: 'b-soft', label: 'B · Angles adoucis', radius: 3.8, inset: .55, unevenness: .12, bevel: 2.2 },
  { id: 'c-worn', label: 'C · Bords plus irréguliers', radius: 6.4, inset: .65, unevenness: 1.05, bevel: 2.7 }
];
const add = (a,b) => a.map((v,i)=>v+b[i]);
const sub = (a,b) => a.map((v,i)=>v-b[i]);
const mul = (a,t) => a.map(v=>v*t);
const dot = (a,b) => a[0]*b[0]+a[1]*b[1];
const cross = (a,b) => a[0]*b[1]-a[1]*b[0];
const length = a => Math.hypot(...a);
const unit = a => mul(a,1/length(a));
const lerp = (a,b,t) => add(a,mul(sub(b,a),t));
const normal = a => [-a[1],a[0]];
const xy = a => a.map(v=>Number(v.toFixed(4))).join(',');
const random = n => { const x=Math.sin(n*12.9898+78.233)*43758.5453; return x-Math.floor(x); };
const polygon = p => `<polygon points="${p.map(xy).join(' ')}"/>`;
function write(file,data) { fs.mkdirSync(path.dirname(path.join(ROOT,file)),{recursive:true}); fs.writeFileSync(path.join(ROOT,file),data); }

function insetPolygon(points,distance) {
  return points.map((p,i)=>{
    const before=unit(sub(p,points[(i-1+points.length)%points.length]));
    const after=unit(sub(points[(i+1)%points.length],p));
    const a=normal(before),b=normal(after),den=1+dot(a,b);
    return den>.05 ? add(p,mul(add(a,b),distance/den)) : add(p,mul(a,distance));
  });
}

function roundedPath(points,radius,unevenness,seed) {
  const vertices=points.map((p,i)=>{
    const prev=points[(i-1+points.length)%points.length],next=points[(i+1)%points.length];
    const incoming=sub(p,prev),outgoing=sub(next,p);
    // The inside elbow remains the exact structural corner. Rounding it outward
    // would paint across a different visible wall plane.
    const convex=cross(incoming,outgoing)>0;
    const r=convex?Math.min(radius*(.8+random(seed+i)*.4),length(incoming)*.23,length(outgoing)*.23):0;
    return { p, enter:add(p,mul(unit(incoming),-r)), exit:add(p,mul(unit(outgoing),r)), r };
  });
  let d='M'+xy(vertices[0].exit);
  for(let i=0;i<vertices.length;i++) {
    const a=vertices[i].exit,b=vertices[(i+1)%vertices.length].enter,edge=sub(b,a),n=normal(unit(edge));
    if(unevenness>.2 && length(edge)>8) {
      for(let j=1;j<=3;j++) {
        const t=j/3,previous=(j-1)/3;
        const end=j===3?b:add(lerp(a,b,t),mul(n,unevenness*(.15+random(seed+i*17+j)*.8)));
        const control=add(lerp(a,b,(previous+t)/2),mul(n,unevenness*(.2+random(seed+i*31+j)*.9)));
        d+='Q'+xy(control)+' '+xy(end);
      }
    } else d+='Q'+xy(add(lerp(a,b,.5),mul(n,unevenness)))+' '+xy(b);
    const v=vertices[(i+1)%vertices.length];
    d+=v.r?'Q'+xy(v.p)+' '+xy(v.exit):'L'+xy(v.exit);
  }
  return d+'Z';
}

async function renderVariant(spec,baseline,report,materials) {
  const [width,height]=report.canvas,scale=4;
  const defs=[],layers=[],textures=new Map();
  for(const [id,face] of report.faces.entries()) {
    const p=face.points,s=materials.renderProfile[face.kind],key=face.kind+'-'+face.materialId;
    if(!textures.has(key)) {
      const png=await sharp(read('assets/dungeon/shared-materials/'+materials.entries[face.materialId].file))
        .modulate({brightness:s.brightness,saturation:s.saturation??.98}).blur(s.blur).png().toBuffer();
      textures.set(key,png);
      defs.push(`<image id="t-${key}" href="data:image/png;base64,${png.toString('base64')}" width="350" height="350" preserveAspectRatio="none"/>`);
    }
    const xs=p.map(q=>q[0]),ys=p.map(q=>q[1]);
    const minx=Math.min(...xs),miny=Math.min(...ys),spanX=Math.max(...xs)-minx,spanY=Math.max(...ys)-miny;
    const floor=face.kind==='floor',narrow=Math.min(spanX,spanY);
    // A narrow projected side must not acquire a disproportionately large bevel.
    const amount=Math.min(1,narrow/14)*(floor?.63:1);
    const stone=insetPolygon(p,spec.inset*amount);
    const d=roundedPath(stone,spec.radius*amount,spec.unevenness*amount,19+id*3);
    const span=Math.max(spanX,spanY)*1.15,tx=minx-span*.065,ty=miny-span*.065;
    const highlight=floor?'#76839b':face.kind==='top'?'#8694b2':'#52617e';
    defs.push(`<clipPath id="face-${id}">${polygon(p)}</clipPath><clipPath id="stone-${id}"><path d="${d}"/></clipPath>`);
    defs.push(`<linearGradient id="bevel-${id}" x1="0" y1="0" x2=".7" y2="1"><stop offset="0" stop-color="${highlight}" stop-opacity="${floor?.42:.75}"/><stop offset=".4" stop-color="${highlight}" stop-opacity=".16"/><stop offset=".62" stop-color="#070e1c" stop-opacity=".12"/><stop offset="1" stop-color="#070e1c" stop-opacity=".8"/></linearGradient>`);
    layers.push(`<g clip-path="url(#face-${id})"><g fill="#0c1220">${polygon(p)}</g><g clip-path="url(#stone-${id})"><path d="${d}" fill="${s.color}"/><use href="#t-${key}" transform="translate(${tx} ${ty}) scale(${span/350})" opacity="${s.opacity}"/><path d="${d}" fill="none" stroke="url(#bevel-${id})" stroke-width="${spec.bevel*amount*2}" stroke-linejoin="round"/></g></g>`);
  }
  const centerY=f=>f.points.reduce((sum,p)=>sum+p[1]/f.points.length,0);
  const accent=report.faces.filter(f=>/wall|pillar/.test(f.part)&&f.kind==='north')
    .sort((a,b)=>centerY(b)-centerY(a))[0];
  // Preserve the small existing violet scar in the end face at its original place.
  if(accent) {
    const id=report.faces.indexOf(accent),mid=accent.points.reduce((a,b)=>add(a,mul(b,1/accent.points.length)),[0,0]);
    layers.push(`<path d="M${mid[0]+3} ${mid[1]+5}l-4 -6 3 -4 -2 -3 m-1 7 -5 -2" stroke="#aa79de" stroke-width=".55" opacity=".8" fill="none" clip-path="url(#stone-${id})"/>`);
  }
  const svg=`<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width/scale} ${height/scale}"><defs>${defs.join('')}</defs><image href="data:image/png;base64,${baseline.toString('base64')}" width="${width/scale}" height="${height/scale}"/>${layers.join('')}</svg>`;
  const raw=await sharp(Buffer.from(svg)).ensureAlpha().raw().toBuffer();
  const original=await sharp(baseline).ensureAlpha().raw().toBuffer();
  // This is the user-approved offline mask method: retain the original envelope,
  // shared ports and alpha. The stone finish varies within the solid masonry.
  for(let i=3;i<raw.length;i+=4)raw[i]=original[i];
  const png=await sharp(raw,{raw:{width,height,channels:4}}).png().toBuffer();
  if(spec.id==='b-soft'&&hash(png)!=='2ad2c6cfbe32b4460440c1871d594047a7d572c6c88af64d4421fa8803ab4ea4')
    throw Error('The regenerated B differs from the approved reference; no B image was overwritten.');
  const overlay=await sharp(read(GUIDE)).resize(width,height).png().toBuffer();
  write(`${OUT}/${spec.id}.png`,png);
  write(`${OUT}/${spec.id}-overlay.png`,await sharp(png).composite([{input:overlay}]).png().toBuffer());
  return { png, spec, sha256:hash(png), alphaSha256:hash(await sharp(png).extractChannel(3).raw().toBuffer()) };
}

async function comparison(images,{detail=false}={}) {
  const W=1512,H=detail?532:1000,layers=[];
  const columns=[['A · Version actuelle','Contours droits'],['B · Angles adoucis','Arrondi discret · bords réguliers'],['C · Bords plus irréguliers','Coins usés · taille moins régulière']];
  let labels='';
  for(let i=0;i<3;i++) {
    const x=24+i*496;
    labels+=`<rect x="${x}" y="94" width="472" height="${detail?352:836}" rx="16" fill="#101827" stroke="${i===1?'#586d8c':'#263246'}"/><text x="${x+18}" y="130" fill="#e5ebf5" font-size="24">${columns[i][0]}</text><text x="${x+18}" y="158" fill="#a9b7cd" font-size="17">${columns[i][1]}</text>`;
    if(detail) {
      const png=await sharp(images[i]).extract({left:34,top:55,width:1066,height:470}).resize(444,196).png().toBuffer();
      layers.push({input:png,left:x+14,top:203});
    } else {
      layers.push({input:await sharp(images[i]).resize(426,493).png().toBuffer(),left:x+23,top:184});
      const png=await sharp(images[i]).extract({left:34,top:55,width:1066,height:470}).resize(444,196).png().toBuffer();
      layers.push({input:png,left:x+14,top:710});
    }
  }
  const bg=Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}"><rect width="100%" height="100%" fill="#080d16"/><g font-family="Arial,sans-serif"><text x="28" y="43" font-size="29" fill="#eef1f9">Adoucir les pierres — coin supérieur gauche</text><text x="28" y="72" font-size="17" fill="#a9b7cd">Mêmes matières, même perspective et même enveloppe de case</text>${labels}<text x="28" y="${H-24}" font-size="17" fill="#a9b7cd">Propositions à comparer · finitions des pierres uniquement · raccords internes à revoir avant intégration</text></g></svg>`);
  write(`${OUT}/${detail?'details':'comparison'}.png`,await sharp(bg).composite(layers).png().toBuffer());
}

async function main() {
  const baseline=read(SOURCE),report=JSON.parse(read(REPORT)),materials=JSON.parse(read(MATERIALS));
  // Do this before any write: frozen metadata alone cannot freeze active PNGs.
  for(const [id,entry] of Object.entries(materials.entries)) {
    if(hash(read('assets/dungeon/shared-materials/'+entry.file))!==entry.sha256)
      throw Error(`Material ${id} differs from the approved comparison. Restore its recorded crop before reproducing this historical review.`);
  }
  write(OUT+'/a-current.png',baseline);
  const outputs=[];
  for(const spec of variants)outputs.push(await renderVariant(spec,baseline,report,materials));
  const images=[baseline,...outputs.map(r=>r.png)];
  await comparison(images);await comparison(images,{detail:true});
  write(OUT+'/recipe.json',JSON.stringify({status:'b_approved',approval:'2026-10-23: ok pour B',method:'Approved deterministic offline material masks; no new texture generation.',generator:'tools/prepare_stone_edge_review.cjs',source:SOURCE,sourceSha256:hash(baseline),faces:REPORT,facesSha256:hash(read(REPORT)),guide:GUIDE,guideSha256:hash(read(GUIDE)),materials:MATERIALS,materialsSha256:hash(read(MATERIALS)),baselineAlphaSha256:hash(await sharp(baseline).extractChannel(3).raw().toBuffer()),variants:outputs.map(({png,...r})=>r),scope:'Visible stone finish changes inside original face regions. Original silhouette alpha, framing, palette, material coordinates and projection retained. Internal straight grout is allowed to be reshaped in this proposal. Frozen comparison from before promotion. User approved B; production promotion is documented in PAINTED_GODOT.md. This comparison alone does not validate every assembled adjacency.'},null,2)+'\n');
  console.log(JSON.stringify({review:OUT,variants:outputs.map(({spec,alphaSha256})=>({id:spec.id,alphaSha256}))}));
}
main().catch(e=>{console.error(e);process.exitCode=1;});
