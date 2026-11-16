// Trace the occluding stone on the registered 392 x 315 painted entrance.
const path = require('node:path');
const sharp = require('sharp');
const assets = path.resolve(__dirname, '../assets/game/introduction/cursed-passage');
const mouth = 'M259 131 L259 88 Q259 73 262 64 L263 58 L267 51 L274 45 L278 50 L282 47 L288 59 L292 49 L297 51 L304 58 L304 66 L309 60 Q315 66 313 83 L319 77 Q323 86 321 117 L284 137 Z';
const nearRail = 'M119 215 L329 113 L344 118 L344 135 L132 239 L117 233 Z';
const arch = 'M225 45 L236 24 L274 0 L311 0 L351 29 L370 64 L382 117 L336 145 L318 120 L282 139 L240 149 L225 140 Z';

async function main() {
  const {data, info} = await sharp(path.join(assets,'stairs.png')).ensureAlpha().raw().toBuffer({resolveWithObject:true});
  const {width,height} = info;
  // R = near railing, G = tunnel opening, B = stone arch excluding the opening.
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}">
    <rect width="100%" height="100%" fill="black"/>
    <path d="${arch} ${mouth}" fill-rule="evenodd" fill="blue"/>
    <path d="${mouth}" fill="lime"/><path d="${nearRail}" fill="red"/>
  </svg>`;
  const mask = await sharp(Buffer.from(svg)).removeAlpha().raw().toBuffer();
  for (let i=0; i<width*height; i++) {
    for (let c=0; c<3; c++) mask[3*i+c] = Math.round(mask[3*i+c] * data[4*i+3]/255);
  }
  await sharp(mask,{raw:{width,height,channels:3}}).png().toFile(path.join(assets,'occlusion.png'));
}
main().catch(error => { console.error(error); process.exitCode=1; });
