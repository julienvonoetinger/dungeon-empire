// Code-native UI vectors from the approved local HTML proposal. No dungeon art.
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '..');
const html = fs.readFileSync(path.join(root, 'docs/reference/interface-review/v1/index.html'), 'utf8');
const out = path.join(root, 'assets/ui/black-gold');
fs.mkdirSync(out, { recursive: true });
const gradients = [...html.matchAll(/<linearGradient[\s\S]*?<\/linearGradient>/g)].map(m => m[0]).join('');
for (const m of html.matchAll(/<symbol id="([^"]+)" viewBox="([^"]+)">([\s\S]*?)<\/symbol>/g)) {
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="${m[2]}"><defs>${gradients}</defs>${m[3].replaceAll('currentColor','#efbf66')}</svg>\n`;
  fs.writeFileSync(path.join(out, `${m[1]}.svg`), svg);
}
for (const [name, top, bottom, border, inner] of [
  ['panel','#292726','#11151a','#9a7b4e','#bba47c'],
  ['button','#2f2d29','#171b20','#ac8851','#e0be80'],
  ['selected','#594727','#2d271f','#f2c66d','#f8dfa2'],
  ['gold','#ffdf92','#ce8f32','#ebbd6d','#fff1b6'],
]) {
  fs.writeFileSync(path.join(out, `${name}.svg`), `<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 96 96"><defs><linearGradient id="g" x2="0" y2="1"><stop stop-color="${top}"/><stop offset="1" stop-color="${bottom}"/></linearGradient></defs><rect x="1" y="3" width="94" height="92" rx="12" fill="#060a10"/><rect x="1" y="1" width="94" height="90" rx="12" fill="url(#g)" stroke="${border}" stroke-width="2"/><rect x="5" y="5" width="86" height="82" rx="8" fill="none" stroke="${inner}" stroke-opacity=".25"/><path d="M14 3H82" stroke="${inner}" stroke-opacity=".8"/></svg>\n`);
}
console.log('Prepared native UI SVG icons and four nine-patch surfaces.');
