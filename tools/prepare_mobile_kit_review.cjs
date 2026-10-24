const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
const {writeGeneratedFile:write}=require('./write_generated_file.cjs');
const root=path.resolve(__dirname,'..'),out='docs/reference/mobile-kit';
const inventory=JSON.parse(fs.readFileSync(path.join(root,out,'scene-inventory.json')));
const save=(file,data)=>write(path.join(root,out,file),data);
async function board(entries,file,columns,tileWidth,tileHeight,images){
  const width=columns*tileWidth,height=Math.ceil(entries.length/columns)*tileHeight,layers=[];
  let labels='';
  for(const [i,name] of entries.entries()){
    const x=i%columns*tileWidth,y=Math.floor(i/columns)*tileHeight;
    const image=await images(name);layers.push({input:image,left:x,top:y+30});
    labels+=`<text x="${x+12}" y="${y+21}" fill="#c9d2e5" font-size="15">${name}</text>`;
  }
  const bg=Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}"><rect width="100%" height="100%" fill="#080f1b"/><g font-family="Arial">${labels}</g></svg>`);
  save(file,await sharp(bg).composite(layers).png().toBuffer());
}
(async()=>{
  for(let page=0;page<Math.ceil(inventory.length/12);page++)await board(inventory.slice(page*12,(page+1)*12).map(i=>i.scene),`scenes-${page+1}.png`,3,400,255,
    name=>sharp(path.join(root,out,'captures',name+'-overview.png')).resize(400,225).png().toBuffer());
  const cells={north:'0--2',east:'2-0',south:'0-2',west:'-2-0'};
  await board(Object.keys(cells),'doors-native.png',2,400,430,name=>sharp(path.join(root,out,'captures',`WireframeDoorCross-doors-${name}-${cells[name]}.png`)).extract({left:440,top:160,width:400,height:400}).png().toBuffer());
  console.log('Prepared two scene boards and four doors at native display pixels.');
})().catch(e=>{console.error(e.stack);process.exitCode=1;});
