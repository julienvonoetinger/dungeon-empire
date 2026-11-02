const fs=require("node:fs"),path=require("node:path"),sharp=require("sharp");
const {point,key}=require("./layout.cjs");
const dir=__dirname,rows=require("./layouts.json").rows,results=require("./verification.json");
const names={N:"Nord",E:"Est",S:"Sud",W:"Ouest"};
async function main(){
 const tiles=[],data={};let labels="";
 for(const [i,row] of rows.entries()){
   const {joints,mouth}=results.views[row.id];
   const ends=row.bays.map((b,j)=>j*2+(key(point(b.side,b.first))===key(row.corner)?1:0));
   data[row.id]={side:row.side,slot:row.slot,passage:row.passage,corner:row.corner,bays:row.bays,joints,mouth,ends};
   const x=6+(i%2)*495,y=8+Math.floor(i/2)*269;
   tiles.push({input:await sharp(path.join(dir,"vues",row.id+".webp")).resize(365,243).png().toBuffer(),left:x+61,top:y+24});
   labels+='<text x="'+(x+63)+'" y="'+(y+18)+'">'+names[row.side]+' · '+(row.slot+1)+'</text>';
 }
 fs.writeFileSync(path.join(dir,"review-data.js"),"const REVIEW = "+JSON.stringify(data)+";\n");
 const svg=Buffer.from('<svg xmlns="http://www.w3.org/2000/svg" width="994" height="1090"><g fill="#f0e1cb" font-family="Georgia" font-size="18">'+labels+'</g></svg>');
 await sharp({create:{width:994,height:1090,channels:3,background:"#10141f"}}).composite([...tiles,{input:svg,top:0,left:0}]).webp({quality:92}).toFile(path.join(dir,"planche.webp"));
}
main().catch(e=>{console.error(e);process.exitCode=1});
