const assert=require('node:assert/strict');
const path=require('node:path');
const sharp=require('sharp');
const variants=[
  ['wood','Bois ferré','Serrure mécanique'],
  ['arcane','Porte magique','Sceau de liaison'],
  ['iron','Fer renforcé','Serrure mécanique'],
  ['grille','Herse','Commande par levier'],
];
const capture=(name,angle)=>path.join(__dirname,'vues',name+'-'+angle+'.png');
async function verify(){
  for(const angle of ['ne','nw','sw','se']){
    const read=id=>sharp(capture(id,angle)).removeAlpha().raw().toBuffer();
    const [open,wood,arcane,iron,gate]=await Promise.all(['open','wood','arcane','iron','grille'].map(read));
    const differs=(a,b,i)=>Math.max(...[0,1,2].map(c=>Math.abs(a[i+c]-b[i+c])));
    let leaf=0,clear=0,bars=0,spill=0;
    for(let i=0;i<wood.length;i+=3){
      if(differs(wood,open,i)>9){
        leaf++;
        const d=differs(gate,open,i);
        if(d<2)clear++;else if(d>12)bars++;
      }else if(differs(wood,open,i)===0 && [arcane,iron,gate].some(a=>differs(a,open,i)>8))spill++;
    }
    assert(leaf>3500 && clear/leaf>.18 && bars/leaf>.40,'gate must show both the corridor and solid iron '+angle);
    // Identical RGB can occasionally occur inside the aperture by coincidence.
    assert(spill<leaf*.002,'textures leaked outside the receiver '+angle);
    console.log(angle,leaf+' visible leaf pixels; '+Math.round(clear/leaf*100)+'% identical to open corridor through the grille');
  }
}
function lettering(width,height,body){
  return Buffer.from('<svg xmlns="http://www.w3.org/2000/svg" width="'+width+'" height="'+height+'">'+body+'</svg>');
}
async function board(){
  const width=852,height=700,layers=[];
  layers.push({input:lettering(width,62,'<text x="18" y="24" font-family="Segoe UI" font-size="11" letter-spacing="2" fill="#bc9fcc">DUNGEON EMPIRE   /   TEXTURES</text><text x="17" y="52" font-family="Georgia" font-size="26" fill="#eee8f4">Quatre portes pour un même passage</text>'),left:0,top:0});
  for(const [i,[id,title,note]] of variants.entries()){
    const x=16+(i%2)*416,y=68+Math.floor(i/2)*316;
    const img=await sharp(capture(id,'ne')).extract({left:70,top:16,width:320,height:202}).resize(404,255).png().toBuffer();
    layers.push({input:img,left:x,top:y});
    const label=lettering(404,43,'<rect width="404" height="43" fill="#1b2231"/><text x="12" y="28" font-family="Georgia" font-size="23" fill="#f2eaf3">'+title+'</text><text x="392" y="26" text-anchor="end" font-family="Segoe UI" font-size="14" fill="#c5b3d2">'+note+'</text>');
    layers.push({input:label,left:x,top:y+255});
  }
  await sharp({create:{width,height,channels:3,background:'#101521'}}).composite(layers).png().toFile(path.join(__dirname,'quatre-portes.png'));
}
async function frontLocks(){
  const {profile,innerLeft,innerRight}=require('../v16-segmental-frame/prepare.cjs');
  const width=280,scale=width/(innerRight-innerLeft),height=Math.ceil(Math.max(...profile.map(p=>p[1]))*scale);
  const outline=[[innerLeft,0],...profile,[innerRight,0]].map(([x,z])=>[(x-innerLeft)*scale,height-z*scale].join(',')).join(' ');
  const mask=lettering(width,height,'<polygon points="'+outline+'" fill="white"/>');
  const layers=[];
  for(const [i,[id,title]] of [variants[0],variants[2]].entries()){
    const left=18+i*(width+20);
    const input=await sharp(path.join(__dirname,'source',id+'.png')).resize(width,height,{fit:'fill'}).ensureAlpha()
      .composite([{input:mask,blend:'dest-in'}]).png().toBuffer();
    layers.push({input,left,top:46},{input:lettering(width,40,'<text x="0" y="28" font-family="Georgia" font-size="23" fill="#f3ecf5">'+title+'</text>'),left,top:2});
  }
  await sharp({create:{width:2*width+56,height:height+64,channels:3,background:'#141b28'}}).composite(layers).png().toFile(path.join(__dirname,'verrous-centraux.png'));
}
verify().then(board).then(frontLocks).catch(e=>{console.error(e);process.exitCode=1;});
