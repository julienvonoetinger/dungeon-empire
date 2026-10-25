// Adopt the accepted projected PNGs. Never rerun ImageGen or the review painter.
const fs=require('node:fs'),path=require('node:path'),sharp=require('sharp');
const P=require('./isometric_paint_geometry.cjs');
const REVIEW='docs/reference/isometric-decoration-review/v1';
const referenceFiles=[`${REVIEW}/selection.json`,`${REVIEW}/prepared.json`];
const read=p=>fs.readFileSync(path.join(P.ROOT,p));
function acceptedEntries(review, count) {
  const selection=JSON.parse(read(`${review}/selection.json`));
  if(selection.status!=='accepted appearance')throw Error('Decoration appearance is not accepted.');
  for(const [file,hash] of Object.entries(selection.sha256))
    if(P.hash(file)!==hash)throw Error('Accepted decoration reference changed: '+file);
  const prepared=JSON.parse(read(`${review}/prepared.json`));
  if(prepared.entries.length!==count||prepared.sourcePixelsPerCell!==256||prepared.zoom!==.75)
    throw Error('Accepted decoration scale or inventory changed.');
  return prepared.entries;
}
async function approvedDecorations() {
  // User retired all old crack motifs after adopting the new wall families.
  // Keep only the independently accepted chipped stone, at its original scale.
  const entries=acceptedEntries(REVIEW,12).filter(e=>e.motif==='chip-worn');
  if(entries.length!==3||new Set(entries.map(e=>e.id)).size!==3)
    throw Error('Active decoration inventory must contain chipped stone on three surfaces.');
  const items=[];
  for(const entry of entries) {
    const png=read(entry.file),meta=await sharp(png).metadata();
    if(meta.width!==entry.size[0]||meta.height!==entry.size[1]||!meta.hasAlpha)
      throw Error('Accepted decoration dimensions/alpha changed: '+entry.id);
    const host=P.models.find(m=>m.id===(entry.surface==='floor'?'floor':entry.surface+'-0'));
    if(!host)throw Error('Unknown decoration surface: '+entry.surface);
    items.push({id:'detail-'+entry.id,png,densityPng:{256:png},frame:entry.frame,
      bounds:host.bounds,surfaceDetail:{surface:entry.surface,motif:entry.motif},
      approvedSource:entry.file});
  }
  return items;
}
module.exports={approvedDecorations,referenceFiles};
