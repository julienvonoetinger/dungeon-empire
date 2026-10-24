// Flat screen-space composition guide for ImageGen, not a projected wireframe.
// It constrains only the pedestal top and socket, leaving the orb as painted art.
const path=require('node:path'),sharp=require('sharp');
const {writeGeneratedFile:write}=require('./write_generated_file.cjs');
const OUT=path.resolve(__dirname,'../docs/reference/mobile-heart-review/perspective-v2/source');
const rect=(x,y,w,h,c,r=0)=>`<rect x="${x}" y="${y}" width="${w}" height="${h}" rx="${r}" fill="${c}" stroke="#101a2e" stroke-width="8"/>`;
const pedestal=rect(230,370,760,760,'#1c2941',14)+rect(220,320,760,760,'#394761',14);
const corners=[[220,320],[806,320],[220,906],[806,906]].map(([x,y])=>rect(x,y,174,174,'#1c2941',18)+rect(x-4,y-20,174,174,'#53647f',18)).join('');
const svg=`<svg xmlns="http://www.w3.org/2000/svg" width="1280" height="1280">
${pedestal}
<circle cx="600" cy="700" r="116" fill="#28354d" stroke="#101a2e" stroke-width="14"/>
<circle cx="600" cy="700" r="48" fill="#200c36" stroke="#b75cff" stroke-width="10"/>
${corners}
<path d="M570 580 Q600 654 600 700 Q614 641 630 580Z" fill="#ba6bff"/>
<circle cx="594" cy="395" r="220" fill="#160d32" stroke="#b75cff" stroke-width="18"/>
<path d="M680 267 C472 230 414 490 606 517 C758 546 787 322 626 318 C488 310 492 458 600 449" fill="none" stroke="#56249b" stroke-width="23"/>
</svg>`;
(async()=>{write(path.join(OUT,'flat-layout.svg'),svg);write(path.join(OUT,'flat-layout.png'),await sharp(Buffer.from(svg)).png().toBuffer());})();
