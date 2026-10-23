// Geometry-only references for a single painted sprite review. No painted input.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
const {geometry}=require('./export_wireframe_cell_kit.cjs');
const root=path.resolve(__dirname,'..');
const directory=path.join(root,'docs/reference/painted-corner-review');
fs.mkdirSync(directory,{recursive:true});
const overlay=fs.readFileSync(path.join(root,'docs/reference/wireframe-overlays/cells/w09_p00_e00.svg'),'utf8');
const walls=geometry(9,0,0,{standalone:true}).svg;
const body=svg=>svg.replace(/^<svg[^>]*>/,'').replace(/<\/svg>\s*$/,'');
const fills=(walls.match(/<(?:polygon|path)\b[^>]*fill="#ffffff"[^>]*\/>/g)||[]).join('');
const construction='<svg xmlns="http://www.w3.org/2000/svg" width="304" height="352" viewBox="0 0 304 352">'+
  '<rect x="24" y="88" width="256" height="256" fill="#ffffff"/>'+fills+body(overlay).replaceAll('#ff00ff','#1c2a3a')+'</svg>';
fs.writeFileSync(path.join(directory,'nw-construction.svg'),construction);
async function main(){
  await sharp(Buffer.from(construction)).resize(1216,1408).png().toFile(path.join(directory,'nw-construction-4x.png'));
  await sharp(Buffer.from(overlay)).resize(1216,1408).png().toFile(path.join(directory,'nw-overlay-4x.png'));
  // Match the generated-review canvas without stretching either axis. Keep
  // the guide at (0,0), with the same small unused strip as the review tool.
  const w=1166,h=1349,scale=Math.min(w/304,h/352);
  const frame=svg=>`<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}"><g transform="scale(${scale})">${body(svg)}</g></svg>`;
  await sharp(Buffer.from(frame(construction))).png().toFile(path.join(directory,'nw-construction-1166x1349.png'));
  await sharp(Buffer.from(frame(overlay))).png().toFile(path.join(directory,'nw-guide-1166x1349.png'));
  console.log('Prepared aligned construction and magenta overlay at 1216x1408. Logical origin: (96,352), cell pitch:1024.');
}
main().catch(error=>{console.error(error);process.exitCode=1;});
