// Isolated pose review: native alpha, editorial cropping and uniform resize only.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),sharp=require('sharp');
const dir=__dirname,source=path.join(dir,'source/states-original.png');
(async()=>{
  const {data,info}=await sharp(source).ensureAlpha().raw().toBuffer({resolveWithObject:true});
  const {width:w,height:h}=info,visited=new Uint8Array(w*h),components=[];
  let transparent=0;
  for(let i=0;i<w*h;i++)if(data[i*4+3]===0)transparent++;
  if(!transparent)throw Error('Missing native alpha');
  for(let i=0;i<w*h;i++){
    if(visited[i]||data[i*4+3]<=8)continue;
    const queue=[i];visited[i]=1;let l=w,t=h,r=0,b=0;
    for(let q=0;q<queue.length;q++){
      const p=queue[q],x=p%w,y=Math.floor(p/w);l=Math.min(l,x);r=Math.max(r,x);t=Math.min(t,y);b=Math.max(b,y);
      for(const [nx,ny] of [[x-1,y],[x+1,y],[x,y-1],[x,y+1]]){
        if(nx<0||ny<0||nx>=w||ny>=h)continue;
        const n=ny*w+nx;
        if(!visited[n]&&data[n*4+3]>8){visited[n]=1;queue.push(n);}
      }
    }
    if(queue.length>1000)components.push({l,t,r,b,pixels:queue.length});
  }
  if(components.length!==4)throw Error('Expected four independent silhouettes: '+JSON.stringify(components));
  const top=components.filter(c=>(c.t+c.b)/2<h/2).sort((a,b)=>a.l-b.l);
  const bottom=components.filter(c=>(c.t+c.b)/2>=h/2).sort((a,b)=>a.l-b.l);
  if(top.length!==2||bottom.length!==2)throw Error('Unexpected layout');
  const ordered=[...top,...bottom],names=['hurt','lockpick-door','lockpick-chest','dead'];
  const labels=['Dégâts','Crochetage · porte','Crochetage · coffre','Mort · pose finale'];
  const scale=106/(ordered[1].b-ordered[1].t+1),entries=[];
  for(let i=0;i<4;i++){
    const c=ordered[i],crop={left:Math.max(0,c.l-8),top:Math.max(0,c.t-8)};
    crop.width=Math.min(w,c.r+9)-crop.left;crop.height=Math.min(h,c.b+9)-crop.top;
    const width=Math.round(crop.width*scale),height=Math.round(crop.height*scale);
    if(Math.max(width,height)>152)throw Error('Subject exceeds common160px canvas');
    const image=await sharp(source).extract(crop).png().toBuffer();
    await sharp(image).png().toFile(path.join(dir,names[i]+'-detail.png'));
    const small=await sharp(image).resize(width,height,{fit:'inside'}).png().toBuffer();
    await sharp({create:{width:160,height:160,channels:4,background:'#00000000'}})
      .composite([{input:small,left:Math.floor((160-width)/2),top:Math.floor((160-height)/2)}]).png().toFile(path.join(dir,names[i]+'.png'));
    entries.push({name:names[i],label:labels[i],crop,scale,frame:[160,160],sprite:names[i]+'.png',detail:names[i]+'-detail.png'});
  }
  const svg=`<svg width="1120" height="730" xmlns="http://www.w3.org/2000/svg"><rect width="1120" height="730" fill="#101722"/><g font-family="Arial" fill="#eee8fa"><text x="30" y="40" font-size="25">Vulpin — poses de référence</text><text x="30" y="68" font-size="15" fill="#b6bfce">Dégâts, crochetage et mort · Une orientation · Animations non produites</text>${entries.map((e,i)=>{const x=30+i%2*550,y=95+Math.floor(i/2)*300;return `<rect x="${x}" y="${y}" width="530" height="280" rx="12" fill="#192331" stroke="#344355"/><text x="${x+18}" y="${y+30}" font-size="20">${e.label}</text><text x="${x+370}" y="${y+252}" font-size="13" fill="#a8b6c8">Taille de jeu indicative</text>`}).join('')}</g><text x="30" y="715" font-family="Arial" font-size="14" fill="#b6bfce">Mains libres ; outils fins uniquement pendant le crochetage. Corps sans sang. Pas d’intégration au jeu.</text></svg>`;
  const layers=[{input:Buffer.from(svg),left:0,top:0}];
  for(let i=0;i<4;i++){
    const x=30+i%2*550,y=95+Math.floor(i/2)*300;
    const large=await sharp(path.join(dir,entries[i].detail)).resize({width:300,height:215,fit:'inside'}).png().toBuffer({resolveWithObject:true});
    layers.push({input:large.data,left:x+Math.floor((330-large.info.width)/2),top:y+50+Math.floor((215-large.info.height)/2)});
    layers.push({input:path.join(dir,entries[i].sprite),left:x+365,top:y+69});
  }
  await sharp({create:{width:1120,height:730,channels:4,background:'#101722'}}).composite(layers).png().toFile(path.join(dir,'review-board.png'));
  fs.writeFileSync(path.join(dir,'poses.json'),JSON.stringify({status:'Key poses only, not animated or runtime integrated',tool:'Built-in ImageGen',source:'source/states-original.png',prompt:'source/prompt.txt',source_size:[w,h],source_sha256:crypto.createHash('sha256').update(fs.readFileSync(source)).digest('hex'),preparation:'Connected silhouettes bounded at alpha8, padding8; original alpha preserved; one uniform scale for all four small views. Frames centered for review, not registered for animation.',entries},null,2)+'\n');
  console.log(JSON.stringify({source:[w,h],silhouettes:components.length,scale,entries}));
})().catch(e=>{console.error(e);process.exitCode=1});
