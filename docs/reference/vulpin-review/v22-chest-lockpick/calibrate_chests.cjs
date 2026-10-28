// Measured keyhole centres in the actual prepared closed-chest artwork.
// Rear-facing keyholes are hidden; infer their opposite ground offsets.
const fs=require('node:fs'),path=require('node:path');
const root=path.resolve(__dirname,'../../../..');
const source=fs.readFileSync(path.join(root,'assets/dungeon/isometric-kit/catalog.tres'),'utf8');
const entries=JSON.parse(source.match(/^entries = (.*)$/m)[1]);
const vector=name=>source.match(new RegExp('^'+name+' = Vector3\\(([^)]+)\\)','m'))[1].split(',').map(Number);
const px=vector('projection_x').map(v=>v*256),py=vector('projection_y').map(v=>v*256),height=.15;
const samples={nw:{id:'prop-chest-east',pixel:[79.5,54],regionSize:[129,91]},ne:{id:'prop-chest',pixel:[52,41],regionSize:[114,78]}};
const data={height,views:{},measurements:samples,notes:'Visible painted keyholes measured; hidden backs inferred by opposite grid offset. Not reconstructed3D.'};
const project=([x,y])=>[x*px[0]+y*px[1]+height*px[2],x*py[0]+y*py[1]+height*py[2]];
for(const [view,sample] of Object.entries(samples)){
 const e=entries[sample.id],local=sample.pixel.map((p,i)=>e.offset[i]+p/sample.regionSize[i]*e.size[i]);
 const x=local[0]-height*px[2],y=local[1]-height*py[2],det=px[0]*py[1]-px[1]*py[0];
 const grid=[(x*py[1]-y*px[1])/det,(y*px[0]-x*py[0])/det];
 data.views[view]={local,grid,inferred:false};
 const opposite={nw:'se',ne:'sw'}[view],back=grid.map(v=>-v);
 data.views[opposite]={local:project(back),grid:back,inferred:true};
}
fs.writeFileSync(path.join(__dirname,'chest-contacts.json'),JSON.stringify(data,null,2)+'\n');
console.log('CHEST_CONTACTS_OK',data.views);
