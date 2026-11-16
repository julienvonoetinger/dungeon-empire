const layout = require('../docs/reference/invocation-magic/autel-meshy/layout.json');

// Replace the historical altar and omit the candles from the playable ritual.
function integrateRitualAltar(scene) {
  const chunks = scene.split(/(?=^\[node )/m);
  let header = chunks.shift();
  header = header.replace(/^\[ext_resource [^\n]+id="(?:altar(?:-shadow)?|Menhir-\d(?:-shadow)?|candles|candle-dish|candle-bowl)"\]\r?\n/gm, '');
  const resources = Object.keys(layout).map(name =>
    `[ext_resource type="Texture2D" path="res://assets/game/introduction/sanctuary/autel/${name}.png" id="${name}"]`);
  header = header.trimEnd()+'\n'+resources.join('\n')+'\n\n';
  header = header.replace(/load_steps=\d+/, 'load_steps='+(header.match(/^\[ext_resource /gm).length+1));
  const nodeName = block => block.match(/^\[node name="([^"]+)"/)[1];
  const depth = block => Number(block.match(/^position = Vector2\([^,]+,\s*([^\)]+)/m)?.[1]);
  const blocks = chunks.filter(b => !/^(Menhir[1-6]|Dalle|Bougies\d+)(Ombre)?$/.test(nodeName(b)));
  function place(block, shadow=false) {
    const start = blocks.findIndex(b => nodeName(b).endsWith('Ombre'));
    const solids = blocks.findIndex((b,i) => i>start && !nodeName(b).endsWith('Ombre'));
    const next = blocks.findIndex((b,i) => i >= (shadow?start:solids) &&
      ((shadow && i>=solids) || depth(b)>depth(block)));
    blocks.splice(next<0?blocks.length:next,0,block);
  }
  for (const [name,part] of Object.entries(layout)) {
    const marker = part.crystal ? `metadata/crystal = Vector2(${part.crystal})\n` : '';
    place(`[node name="${name}" type="Sprite2D" parent="."]\nposition = Vector2(${part.position})\ntexture = ExtResource("${name}")\ncentered = false\noffset = Vector2(${part.offset})\n${marker}\n`, name.endsWith('Ombre'));
  }
  return header+blocks.join('');
}
module.exports = {integrateRitualAltar};
