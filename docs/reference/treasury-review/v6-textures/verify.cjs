const fs=require("node:fs"),path=require("node:path"),assert=require("node:assert/strict"),sharp=require("sharp");
const P=require("../../../../tools/isometric_paint_geometry.cjs");
const {rows}=require("../v5-wireframe/layouts.json"),dir=__dirname;
const cat=require("../../../../assets/dungeon/isometric-kit/catalog.json"),keys=require("./floor-keys.json");
const warm=(r,g,b)=>r-b>25 && r>1.15*b;
async function main(){
  const ids=new Set(rows.flatMap(row=>row.objects.map(o=>o.id)));
  for(const id of ids){
    const {data}=await sharp(path.join(dir,"sprites",id+".png")).ensureAlpha().raw().toBuffer({resolveWithObject:true});
    let n=0;for(let k=0;k<data.length;k+=4)if(data[k+3]>160 && warm(data[k],data[k+1],data[k+2]))n++;
    assert.equal(n,0,id+": warm pixels on masonry");
  }
  let paintedCells=0,clearSamples=0;
  for(const row of rows){
    let gold=0;
    for(let x=0;x<2;x++)for(let y=0;y<2;y++){
      const reg=cat.atlas.regions[keys[x+","+y]], [left,top,width,height]=reg.region;
      const base=await sharp(path.join(P.ROOT,"assets/dungeon/isometric-kit/atlas-256.png")).extract({left,top,width,height}).ensureAlpha().raw().toBuffer();
      const data=await sharp(path.join(dir,"sprites","sol-"+row.id+"-"+x+"-"+y+".png")).ensureAlpha().raw().toBuffer();
      let diff=0;
      for(let i=0;i<data.length;i+=4){
        assert.equal(data[i+3],base[i+3],"Original floor silhouette");
        if(data[i+3]===0)continue;
        const k=i/4,[u,v]=P.ground([reg.offset[0]+k%width+.5,reg.offset[1]+Math.floor(k/width)+.5]);
        const a=x+u,b=y+v;
        const depth={N:b,E:2-a,S:2-b,W:a}[row.side],offset=(row.side==="N"||row.side==="S"?a:b)-row.slot-.5;
        const changed=data[i]!==base[i]||data[i+1]!==base[i+1]||data[i+2]!==base[i+2];
        if(depth>=0&&depth<=.22&&Math.abs(offset)<.34){clearSamples++;assert(!changed,"Gold in entrance strip for "+row.id);}
        if(changed)diff++;
        if(warm(data[i],data[i+1],data[i+2]))gold++;
      }
      paintedCells+=Number(diff>0);
    }
    assert(gold>250,"No readable treasure on "+row.id);
  }
  assert(clearSamples>1000);
  console.log(ids.size+" stone-only modules, all 32 tile silhouettes, 8 clear entrances and "+paintedCells+" gold-painted tiles checked.");
}
main().catch(e=>{console.error(e.message);process.exitCode=1;});
