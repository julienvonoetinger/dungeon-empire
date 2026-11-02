// Prepare review plates. Both proposals keep the native stage and the same treasure.
const path = require("node:path");
const sharp = require("sharp");
const dir = __dirname;
const width = 960, height = 600;

// The first band follows the two far walls, ending where the corridor begins.
// The second follows the low front masonry and stops at the open threshold.
const bands = [
  "M 167 190 L 463 20 Q 507 -1 549 18 L 844 178 L 897 241 L 899 355 L 852 374 L 775 316 L 515 206 L 216 353 L 188 359 L 169 326 Z",
  "M 303 329 L 375 323 L 506 387 L 820 234 L 892 248 L 899 347 L 527 539 L 484 532 L 310 441 Z"
];
async function prepare() {
  const artMask = Buffer.from('<svg xmlns="http://www.w3.org/2000/svg" width="960" height="600">'+
    bands.map(d=>'<path d="'+d+'" fill="white"/>').join("")+"</svg>");
  const mask = await sharp(artMask).ensureAlpha().blur(4).png().toBuffer();
  const nativeFloor = await sharp(path.join(dir,"salle-nue.png")).removeAlpha().raw().toBuffer();
  const nativeGold = await sharp(path.join(dir,"salle-or.png")).removeAlpha().raw().toBuffer();
  for (const id of ["comptoir","sceau"]) {
    const room = await sharp(path.join(dir,"source",id+".png")).resize(width,height,{fit:"fill"})
      .ensureAlpha().png().toBuffer();
    const walls = await sharp(room).composite([{input:mask,blend:"dest-in"}]).png().toBuffer();
    const empty = await sharp(path.join(dir,"salle-nue.png")).composite([{input:walls}]).removeAlpha().raw().toBuffer();
    const raw = {width,height,channels:3};
    await sharp(empty,{raw}).webp({lossless:true}).toFile(path.join(dir,id+"-murs.webp"));
    const full = Buffer.from(empty);
    // Only the native pixels changed by the original, correctly depth-sorted hoard.
    for(let i=0;i<full.length;i+=3) {
      if (nativeGold[i]!==nativeFloor[i] || nativeGold[i+1]!==nativeFloor[i+1] || nativeGold[i+2]!==nativeFloor[i+2])
        nativeGold.copy(full,i,i,i+3);
    }
    await sharp(full,{raw}).webp({lossless:true}).toFile(path.join(dir,id+"-or.webp"));
  }
}
prepare().catch(e=>{console.error(e);process.exitCode=1;});
