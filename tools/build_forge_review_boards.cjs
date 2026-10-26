#!/usr/bin/env node
// Forge UI review, pass 2: writes the Claude Design canvas artboards and an
// offline print page from ONE source, so the PDF matches the canvas.
// Mockups mirror scripts/game/game_hud.gd geometry (modes column/wide/dock,
// 64-unit placement slot, 58-unit rows/tiles, world presentation scale) and use
// the painted stone/icons exported from Godot into design-pass-2/mock-kit.
// Usage: node tools/build_forge_review_boards.cjs <canvas project dir> <print html> [<previous boards dir>]
'use strict';
const fs = require('fs');
const path = require('path');
const { pathToFileURL } = require('url');

const ROOT = path.resolve(__dirname, '..');
const PASS = 'docs/reference/interface-review/design-pass-2';
const ASSETS = JSON.parse(fs.readFileSync(path.join(ROOT, PASS, 'artifact-assets.json'), 'utf8')).assets;
const [projectDir, printHtml, previousDir] = process.argv.slice(2);
if (!projectDir || !printHtml) throw new Error('usage: build_forge_review_boards.cjs <project dir> <print html> [previous boards dir]');

// --- Godot layout constants (game_hud.gd) -----------------------------------
const WIDE_WIDTH = 252, ROW = 58, SLOT = 64, DOCK_ACTIONS = 76, COLUMN_HEIGHT = 600;
const STATES = [
  ['tools', 'Familles', 'Les quatre familles, Annuler et Observer.'],
  ['catalog', 'Variantes', 'Famille Pièges ouverte.'],
  ['placing', 'Variante active', 'Pointes armées : barre de pose et Arrêter.'],
  ['notice', 'Refus', 'Or insuffisant, affiché dans la barre de pose.'],
  ['selection', 'Sélection', 'Coffre plein sélectionné.'],
  ['raid', 'Raid', 'Observation : Bâtir, Centrer, Pause.'],
];
const SIZES = [[844, 390], [740, 360], [667, 375], [390, 844], [320, 568]];

let MODE = 'dc'; // 'dc' → canvas blob URLs, 'print' → local file URLs
function src(rel) {
  if (MODE === 'dc') {
    if (!ASSETS[rel]) throw new Error('missing uploaded asset ' + rel);
    return ASSETS[rel];
  }
  return pathToFileURL(path.join(ROOT, rel)).href;
}
const kit = (name) => src(`${PASS}/mock-kit/${name}.png`);
const esc = (text) => String(text).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');

function css() {
  return `
.f{position:relative;overflow:hidden;font-family:'Open Sans',sans-serif;font-weight:600;color:#eef0fa;background:#141a26}
.f *{box-sizing:border-box}
.ab{position:absolute}
.st{position:absolute;border-style:solid;border-width:0;border-image-source:url(${kit('stone-normal')});border-image-slice:11 fill;border-image-width:11px;border-image-repeat:stretch}
.st.sel{border-image-source:url(${kit('stone-selected')})}
.st.dis{border-image-source:url(${kit('stone-disabled')})}
.tx{text-shadow:0 1px 0 #070a10;line-height:1.36;white-space:nowrap;margin:0}
.mut{color:#b3bbcf}.gold{color:#efd08e}.lav{color:#d2b1f0}
.fx{display:flex;align-items:center}
.cl{display:flex;flex-direction:column;align-items:center;justify-content:center}
.ic{object-fit:contain;flex:none;display:block}
.cap{font-family:'Alegreya Sans',sans-serif;font-size:15px;color:#a9b1c6;margin:0 0 6px;letter-spacing:.06em;text-transform:uppercase}
`;
}

// --- Mock pieces ----------------------------------------------------------------
const box = (cls, x, y, w, h, inner, pad = 0, extra = '') =>
  `<div class="st ${cls}" style="left:${x}px;top:${y}px;width:${w}px;height:${h}px;padding:${pad}px;${extra}">${inner}</div>`;
const icon = (name, size, extra = '') => `<img class="ic" src="${kit('icon-' + name)}" alt="" style="width:${size}px;height:${size}px;${extra}">`;
const text = (value, size, cls = '', extra = '') => `<p class="tx ${cls}" style="font-size:${size}px;${extra}">${esc(value).replace(/\n/g, '<br>')}</p>`;

function clock(x, y, w, h, kind, state) {
  const raid = state === 'raid';
  const building = ['catalog', 'placing', 'notice', 'selection'].includes(state);
  const value = raid ? '00:00' : '01:14';
  let title = raid ? 'RAID EN COURS' : 'PROCHAIN RAID', size = 22, note = building ? 'Délai suspendu' : '';
  if (kind === 'narrow') { title = 'RAID'; size = 12; note = ''; }
  if (kind === 'compact') { size = 16; if (building) title = 'RAID · PAUSE'; note = ''; }
  const inner = `<div class="cl" style="height:100%">${text(title, 10, 'mut')}${text(value, size, 'gold')}${note ? text(note, 10, 'mut') : ''}</div>`;
  return box('', x, y, w, h, inner, 0, 'padding:12px 10px');
}

function treasury(x, y, w, h, stacked) {
  const pair = (glyph, value, cls) => `<div class="fx" style="gap:8px">${icon(glyph, 30)}${text(value, 18, cls)}</div>`;
  const inner = stacked
    ? `<div style="display:flex;flex-direction:column;justify-content:center;gap:2px;height:100%">
        <div class="fx" style="gap:8px">${icon('coin', 30)}<div style="flex:1;text-align:right">${text('225', 18, 'gold')}</div></div>
        <div class="fx" style="gap:8px">${icon('health', 30)}<div style="flex:1;text-align:right">${text('100 %', 18)}</div></div></div>`
    : `<div class="fx" style="justify-content:space-between;height:100%">${pair('coin', '225', 'gold')}${pair('health', '100 %', '')}</div>`;
  return box('', x, y, w, h, inner, 0, 'padding:12px 14px');
}

function family(x, y, w, label, glyph, active, note) {
  const tight = w < 120;
  const pad = tight ? 10 : 14, size = tight ? 26 : 30, gap = tight ? 6 : 8;
  const words = `<div>${text(label, 13)}${note ? text(note, 11, 'lav') : ''}</div>`;
  return box(active ? 'sel' : '', x, y, w, ROW, `<div class="fx" style="gap:${gap}px;height:100%">${icon(glyph, size)}${words}</div>`, 0, `padding:12px ${pad}px`);
}

function tile(x, y, w, glyph, label, disabled) {
  const inner = `<div class="cl" style="height:100%;gap:1px;opacity:${disabled ? .45 : 1}">${icon(glyph, 24)}${text(label, 11)}</div>`;
  return box(disabled ? 'dis' : '', x, y, w, ROW, inner, 6);
}

function families(x, y, w, columns, armed) {
  const names = [['Terrain', 'pick'], ['Portes', 'door'], ['Pièges', 'spike'], ['Trésors', 'chest']];
  const cell = (w - (columns - 1) * 4) / columns;
  return names.map(([label, glyph], index) => {
    const active = armed && index === 2;
    return family(x + (index % columns) * (cell + 4), y + Math.floor(index / columns) * (ROW + 4), cell,
      active ? 'Pointes' : label, active ? 'spike' : glyph, active, active ? '35 or' : '');
  }).join('');
}

function poseBar(x, y, w, h, state, vertical) {
  const message = state === 'notice' ? 'Or insuffisant : 35 requis.' : 'Pointes · 35 or\nTouchez une case.';
  const stop = `<div class="st fx" style="position:relative;width:${vertical ? '100%' : '98px'};height:48px;flex:none;justify-content:center;gap:6px">${icon('cross', 20)}${text('Arrêter', 12)}</div>`;
  const layout = vertical ? 'flex-direction:column;justify-content:center;gap:6px' : 'gap:6px';
  const label = `<div style="flex:1;min-width:0;${vertical ? 'text-align:center' : ''}">${text(message, 11, '', 'white-space:normal')}</div>`;
  return box('sel', x, y, w, h, `<div class="fx" style="height:100%;${layout}">${label}${stop}</div>`, 8);
}

function catalogSheet(x, y, w, h) {
  const columns = w >= 340 ? 2 : 1;
  const inner = w - 24;
  const cardW = (inner - (columns - 1) * 4) / columns;
  const cards = [['Pointes', '35 or', 'spike', ''], ['Entrave', '30 or', 'snare', 'Niv. 2'], ['Néant', '45 or', 'void', 'Niv. 3']];
  const body = cards.map(([name, cost, glyph, lock], index) => {
    const cx = 12 + (index % columns) * (cardW + 4), cy = 12 + 48 + 6 + Math.floor(index / columns) * 76;
    const content = `<div class="fx" style="gap:10px;height:100%;${lock ? 'opacity:.62;filter:grayscale(.6)' : ''}">${icon(glyph, 30)}<div>${text(name, 13)}${text(cost, 11, 'lav')}${lock ? text(lock, 11, 'mut') : ''}</div></div>`;
    return box(lock ? 'dis' : '', cx, cy, cardW, 72, content, 0, 'padding:10px 14px');
  }).join('');
  const header = `<div class="ab fx" style="left:12px;top:12px;width:${inner}px;height:48px">${text('Pièges', 17, '', 'flex:1')}</div>` +
    box('', 12 + inner - 48, 12, 48, 48, `<div class="cl" style="height:100%">${text('‹', 16)}</div>`);
  return box('', x, y, w, h, `<div class="ab" style="inset:0;overflow:hidden">${header}${body}</div>`);
}

function selectionSheet(x, y, w, h) {
  const inner = w - 24;
  const top = `<div class="ab fx" style="left:12px;top:12px;width:${inner}px;height:48px;gap:8px">${icon('chest', 32)}<div style="flex:1">${text('Coffre', 18)}${text('150 / 150 or', 14, 'mut')}</div></div>` +
    box('', 12 + inner - 48, 12, 48, 48, `<div class="cl" style="height:100%">${icon('cross', 28)}</div>`);
  const transfer = box('', 12, 12 + 48 + 6, inner, 48, `<div class="fx" style="height:100%;justify-content:center;gap:10px">${icon('arrow', 28)}${text('Transférer l’or', 16)}</div>`);
  return box('', x, y, w, h, `<div class="ab" style="inset:0">${top}${transfer}</div>`);
}

function peekTiles(x, y, w, h, vertical) {
  if (vertical) {
    return tile(x + 4, y + 8, 56, 'pick', 'Bâtir') + tile(x + 4, y + 8 + ROW + 4, 56, 'target', 'Centrer') + tile(x + 4, y + h - 8 - ROW, 56, 'pause', 'Pause');
  }
  return tile(x + 8, y + 8, 56, 'pick', 'Bâtir') + tile(x + 8 + 60, y + 8, 56, 'target', 'Centrer') + tile(x + w - 8 - 56, y + 8, 56, 'pause', 'Pause');
}

/** One mock frame, at real size (1 CSS px = 1 HUD unit = 1 screen px here). */
function mock(w, h, state) {
  const mode = h > w ? 'dock' : h >= COLUMN_HEIGHT ? 'column' : 'wide';
  if (mode === 'column') throw new Error('column mode is not mocked in this pass');
  // World presentation: one cell = 192 base units * (short side / 720).
  const scale = Math.min(w, h) / 720;
  const raid = state === 'raid', armed = state === 'placing' || state === 'notice';
  const parts = [];
  let world;
  if (mode === 'wide') {
    const W = raid ? 64 : Math.min(WIDE_WIDTH, w * .5), X = w - W;
    world = { x: 0, y: 0, w: w - W, h };
    if (raid) {
      parts.push(clock(X, 0, W, 60, 'narrow', state));
      parts.push(box('', X, 60, W, h - 60, ''), peekTiles(X, 60, W, h - 60, true));
    } else {
      const cw = Math.round(W * .43);
      parts.push(clock(X, 0, cw, 86, 'full', state), treasury(X + cw, 0, W - cw, 86, true));
      if (state === 'catalog') parts.push(catalogSheet(X, 86, W, h - 86));
      else if (state === 'selection') parts.push(selectionSheet(X, 86, W, h - 86));
      else {
        const panel = Math.min(2 * ROW + 4 + 4 + ROW + 16, h - 86 - SLOT), py = h - panel;
        parts.push(box('', X, py, W, panel, ''), families(X + 8, py + 8, W - 16, 2, armed));
        const tw = (W - 16 - 4) / 2;
        parts.push(tile(X + 8, py + 8 + 2 * ROW + 8, tw, 'undo', 'Annuler', true), tile(X + 8 + tw + 4, py + 8 + 2 * ROW + 8, tw, 'eye', 'Observer'));
        if (armed) parts.push(poseBar(X, py - SLOT, W, SLOT, state, false));
      }
    }
  } else {
    const cw = Math.min(170, Math.max(120, w * .38));
    const limit = Math.max(ROW + 64, h * .55) - ROW;
    let panel = 2 * ROW + 4 + 16, slot = SLOT;
    if (raid) { panel = ROW + 16; slot = 0; }
    if (state === 'catalog') { const cols = w >= 340 ? 2 : 1, rows = Math.ceil(3 / cols); panel = Math.min(limit, 48 + 6 + rows * 72 + (rows - 1) * 4 + 24); slot = 0; }
    if (state === 'selection') { panel = Math.min(limit, 48 + 6 + 48 + 24); slot = 0; }
    const dy = h - ROW - slot - panel;
    world = { x: 0, y: 0, w, h: dy };
    parts.push(clock(0, dy, cw, ROW, 'compact', state), treasury(cw, dy, w - cw, ROW, false));
    const py = dy + ROW + slot;
    if (armed) parts.push(poseBar(0, dy + ROW, w, SLOT, state, false));
    if (raid) parts.push(box('', 0, py, w, panel, ''), peekTiles(0, py, w, panel, false));
    else if (state === 'catalog') parts.push(catalogSheet(0, py, w, panel));
    else if (state === 'selection') parts.push(selectionSheet(0, py, w, panel));
    else {
      parts.push(box('', 0, py, w, panel, ''));
      const fw = w - 16 - DOCK_ACTIONS - 4;
      parts.push(families(8, py + 8, fw, 2, armed));
      parts.push(tile(8 + fw + 4, py + 8, DOCK_ACTIONS, 'undo', 'Annuler', true), tile(8 + fw + 4, py + 8 + ROW + 4, DOCK_ACTIONS, 'eye', 'Observer'));
    }
  }
  // The dungeon itself: same rendered world at the same presentation scale.
  // Only the 1216-unit world of the 1280 observe capture (its own rail excluded).
  const img = `<div class="ab" style="left:${(world.w / 2 - 608 * scale).toFixed(1)}px;top:${(world.h / 2 - 360 * scale).toFixed(1)}px;width:${(1216 * scale).toFixed(1)}px;height:${(720 * scale).toFixed(1)}px;overflow:hidden"><img src="${src(PASS + '/captures/1280-observe.png')}" alt="Donjon (rendu Godot)" style="display:block;width:${(1280 * scale).toFixed(1)}px;height:${(720 * scale).toFixed(1)}px;max-width:none"></div>`;
  const rock = `background:#141a26 url(${kit('rock')}) repeat;background-size:${(290 * scale).toFixed(1)}px ${(170 * scale).toFixed(1)}px`;
  return `<div class="f" style="width:${w}px;height:${h}px;${rock}"><div class="ab" style="left:0;top:0;width:${world.w}px;height:${world.h}px;overflow:hidden">${img}</div>${parts.join('')}</div>`;
}

// --- Boards ------------------------------------------------------------------------
const native = (w, state) => src(`${PASS}/captures/${w}-${state}.png`);
const shot = (url, w, h, alt) => `<img src="${url}" alt="${esc(alt)}" style="display:block;width:${w}px;height:${h}px;border-radius:6px;outline:1px solid #2a3348">`;
const head = (title, sub) => `<div style="display:flex;justify-content:space-between;align-items:flex-end;gap:32px;margin-bottom:28px">
  <h1 style="margin:0;font-family:Cinzel,serif;font-size:38px;color:#efd08e">${esc(title)}</h1>
  <p style="margin:0;max-width:760px;font-size:17px;line-height:1.45;color:#b3bbcf;text-align:right">${esc(sub)}</p></div>`;
const page = (w, h, inner) => `<div style="width:${w}px;height:${h}px;box-sizing:border-box;padding:48px;background:#0d111b;color:#e6e9f4;font-family:'Alegreya Sans',sans-serif">${inner}</div>`;

function compareBoard(w, h) {
  const portrait = h > w;
  const label = (name, note) => `<div style="width:150px;flex:none"><h2 style="margin:0 0 6px;font-size:21px;color:#f3f4fa">${esc(name)}</h2><p style="margin:0;font-size:15px;line-height:1.4;color:#b3bbcf">${esc(note)}</p></div>`;
  let inner, W, H;
  if (!portrait) {
    W = 96 + 150 + 24 + w + 24 + w; H = 96 + 92 + STATES.length * (h + 52);
    inner = STATES.map(([state, name, note]) => `<div style="display:flex;gap:24px;margin-bottom:${52 - 30}px;align-items:flex-start">${label(name, note)}
      <figure style="margin:0"><p class="cap">Maquette Claude Design</p>${mock(w, h, state)}</figure>
      <figure style="margin:0"><p class="cap">Godot natif</p>${shot(native(w, state), w, h, `Capture native ${w}x${h} ${name}`)}</figure></div>`).join('');
  } else {
    W = 96 + 150 + STATES.length * (w + 24); H = 96 + 92 + 2 * (h + 60);
    const row = (title, cell) => `<div style="display:flex;gap:24px;margin-bottom:28px"><div style="width:126px;flex:none"><h2 style="margin:0;font-size:21px;color:#f3f4fa">${title}</h2></div>${STATES.map(cell).join('')}</div>`;
    inner = row('Maquette Claude Design', ([state, name]) => `<figure style="margin:0"><p class="cap">${esc(name)}</p>${mock(w, h, state)}</figure>`) +
      row('Godot natif', ([state, name]) => `<figure style="margin:0"><p class="cap">${esc(name)}</p>${shot(native(w, state), w, h, `Capture native ${w}x${h} ${name}`)}</figure>`);
  }
  const mode = portrait ? 'portrait · dock bas' : 'paysage court · rail large de 252';
  return { w: W, h: H, title: `${w}×${h} — maquette / natif`, body: page(W, H, head(`${w} × ${h} · ${mode}`, 'À taille réelle, 1 px = 1 unité d’interface. Maquette générée avec la pierre peinte et les icônes exportées de Godot ; à droite ou dessous, la capture native du même état. Le monde des maquettes est une capture 1280 réduite à l’échelle de présentation : ses anneaux paraissent plus petits que les anneaux natifs, maintenus à 32 px.') + inner) };
}

function reviewBoard() {
  const W = 1440, H = 960;
  const item = (n, title, done, verified) => `<li style="display:flex;gap:16px"><span style="flex:none;width:34px;height:34px;border-radius:50%;background:#efd08e;color:#1a1220;font-weight:700;font-size:18px;display:flex;align-items:center;justify-content:center">${n}</span><div>
    <h2 style="margin:0 0 6px;font-size:22px;color:#f3f4fa">${esc(title)}</h2>
    <p style="margin:0 0 4px;font-size:17px;line-height:1.45;color:#d6dbe8">${esc(done)}</p>
    <p style="margin:0;font-size:15.5px;line-height:1.45;color:#a9b1c6">Vérifié : ${esc(verified)}</p></div></li>`;
  const rows = [['844×390', '83,9 %', '70,1 %', '70,1 %', '104 px'], ['740×360', '81,6 %', '65,9 %', '65,9 %', '96 px'], ['667×375', '—', '62,2 %', '62,2 %', '100 px'],
    ['390×844', '65,1 %', '69,4 %', '66,1 %', '58 → 104 px'], ['320×568', '57,5 %', '54,6 %', '45,0 %', '48 → 85 px']];
  const table = `<table style="border-collapse:collapse;font-size:16px;margin-top:8px">
    <tr style="color:#a9b1c6;text-align:left"><th style="padding:6px 18px 6px 0">Format</th><th style="padding:6px 18px">Monde, familles (avant)</th><th style="padding:6px 18px">Monde, familles (passe 2)</th><th style="padding:6px 18px">Monde, variantes ouvertes</th><th style="padding:6px 18px">Largeur d’une case</th></tr>
    ${rows.map((r) => `<tr style="border-top:1px solid #252d40">${r.map((c, i) => `<td style="padding:7px ${i ? 18 : 18}px 7px ${i ? 18 : 0}px;color:${i ? '#e6e9f4' : '#efd08e'}">${c}</td>`).join('')}</tr>`).join('')}</table>`;
  const body = head('Passe 2 — corrections intégrées', 'Retour de revue sur le PDF de la passe 1 : quatre points traités dans Claude Design puis dans Godot. Les anciennes planches restent au-dessus, inchangées.') +
    `<div style="display:flex;gap:48px"><ol style="margin:0;padding:0;list-style:none;display:flex;flex-direction:column;gap:22px;width:820px">
    ${item(1, 'Les quatre familles toujours accessibles', 'Paysage court (hauteur < 600) : un rail large de 252 place le timer et l’or/santé côte à côte (86 u), puis les familles en 2 × 2 de 58 u, avec Annuler/Observer dessous. La même largeur sert aux variantes et à la sélection : ouvrir le catalogue ne déplace plus la vue. Paysage haut : colonne de 136 inchangée, quatre lignes de familles.', '844×390, 740×360, 667×375 : quatre familles entières, cibles ≥ 48, aucune troncature (contrôle géométrique et session d’interactions).')}
    ${item(2, 'Un donjon lisible en portrait', 'L’étirement canvas_items/expand calait 1280 unités sur la largeur en portrait : les cases y étaient 1,78 × plus petites qu’en paysage sur le même téléphone. Le zoom de présentation compense uniquement cet étirement (petit côté = 720 unités de base) : les cases ont la taille de la référence paysage, sans dépendre de la taille du donjon et sans zoom joueur.', 'scale-before / tools à dimensions identiques (390×844, 320×568) ; paysage 16:9 et plus large inchangé (facteur 1).')}
    ${item(3, 'Maquettes au langage réel du jeu', 'Les maquettes sont générées avec la pierre peinte 9-slice, ses teintes de sélection et de désactivation, les icônes recadrées par Godot et Open Sans SemiBold : le langage visuel effectivement intégré.', 'comparaison maquette / natif à taille réelle sur 5 formats × 6 états, ci-dessous.')}
    ${item(4, 'Actions secondaires sans ambiguïté', 'Annuler et Observer sont des tuiles libellées qui ne changent jamais de sens. La pose répétée a sa propre barre, dans un emplacement réservé : variante, coût, consigne et un bouton « Arrêter » explicite. Les refus s’y affichent en français. Observation : Bâtir, Centrer, Pause libellés.', '53 contrôles d’interaction natifs sur 4 formats, dont « armer ne déplace pas la vue ».')}
    </ol><div style="flex:1;display:flex;flex-direction:column;gap:18px">
    <h2 style="margin:0;font-size:22px;color:#f3f4fa">Part du monde et taille des cases</h2>${table}
    <p style="margin:0;font-size:15.5px;line-height:1.5;color:#b3bbcf">Le paysage court cède de la largeur au rail large pour montrer les quatre familles : c’est le compromis retenu. En échange, la vue ne bouge plus à l’ouverture du catalogue, ni lorsqu’on arme une variante. En portrait, une case passe de 58 à 104 px de large : sa hauteur de 52 px rend chaque case sélectionnable au doigt.</p>
    <p style="margin:0;font-size:15.5px;line-height:1.5;color:#b3bbcf">Non vérifié : toucher réel sur téléphone, DPI et zones sûres physiques, performances. Les captures sont statiques et la session d’interactions envoie des clics synthétiques.</p></div></div>`;
  return { w: W, h: H, title: 'P2 · Revue et décisions', body: page(W, H, body) };
}

function scaleBoard() {
  const W = 96 + 2 * 390 + 2 * 320 + 2 * 422 + 5 * 28, H = 96 + 92 + 844 + 90;
  const fig = (url, w, h, cap) => `<figure style="margin:0"><p class="cap">${esc(cap)}</p>${shot(url, w, h, cap)}</figure>`;
  const body = head('Échelle de présentation à dimensions identiques', 'Même état, même interface, même caméra centrée sur le cœur : seul le zoom de présentation change. Paysage 844×390 : facteur 1, identique.') +
    `<div style="display:flex;gap:28px;align-items:flex-start">
      ${fig(native(390, 'scale-before'), 390, 844, '390×844 · avant (×1)')}${fig(native(390, 'tools'), 390, 844, '390×844 · passe 2 (×1,78)')}
      ${fig(native(320, 'scale-before'), 320, 568, '320×568 · avant (×1)')}${fig(native(320, 'tools'), 320, 568, '320×568 · passe 2 (×1,78)')}
      ${fig(native(844, 'scale-before'), 422, 195, '844×390 · avant (×1), 50 %')}${fig(native(844, 'tools'), 422, 195, '844×390 · passe 2 (×1), 50 %')}
    </div>`;
  return { w: W, h: H, title: 'P2 · Échelle portrait', body: page(W, H, body) };
}

function interactionBoard() {
  const W = 1440 + 700, H = 96 + 92 + 230 + 470 + 120;
  const steps = [['1-variantes', 'Pièges ouvert'], ['2-armee', 'Pointes armées'], ['3-refus', 'Refus (or à 0)'], ['4-annule', 'Arrêter puis Annuler'], ['5-observer', 'Observer']];
  const strip = (tag, w, h) => `<div style="display:flex;gap:18px;margin-bottom:24px">${steps.map(([file, cap]) => `<figure style="margin:0"><p class="cap">${esc(cap)}</p>${shot(src(`${PASS}/interaction/${tag}-${file}.png`), w, h, cap)}</figure>`).join('')}</div>`;
  const body = head('Session d’interactions isolée', 'Clics synthétiques dans le vrai viewport (sélection GUI + entrée du jeu), emplacement de sauvegarde de revue supprimé ensuite ; empreinte SHA-256 de la sauvegarde du joueur identique avant/après. 53 contrôles, 0 échec. Ce n’est pas un test tactile sur téléphone.') +
    strip('844x390', 422, 195) + strip('390x844', 217, 470);
  return { w: W, h: H, title: 'P2 · Interactions', body: page(W, H, body) };
}

// --- Output ------------------------------------------------------------------------
function dcFile(board) {
  return `<!doctype html>
<html lang="fr">
<head>
<meta charset="utf-8">
<title>${esc(board.title)}</title>
<script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
<link href="https://fonts.googleapis.com/css2?family=Cinzel:wght@600;700&amp;family=Alegreya+Sans:wght@400;500;700&amp;family=Open+Sans:wght@600&amp;display=swap" rel="stylesheet">
<style>
body{margin:0}
${css()}
</style>
</helmet>
${board.body}
</x-dc>
<script type="text/x-dc" data-dc-script data-props='{"$preview":{"width":${board.w},"height":${board.h}}}'>
class Component extends DCLogic {
  renderVals() { return {}; }
}
</script>
</body>
</html>
`;
}

function buildBoards() {
  const boards = { 'P2-Revue.dc.html': reviewBoard(), 'P2-Echelle.dc.html': scaleBoard(), 'P2-Interactions.dc.html': interactionBoard() };
  for (const [w, h] of SIZES) boards[`P2-Compare-${w}.dc.html`] = compareBoard(w, h);
  return boards;
}

MODE = 'dc';
const dcBoards = buildBoards();
fs.mkdirSync(projectDir, { recursive: true });
for (const [name, board] of Object.entries(dcBoards)) fs.writeFileSync(path.join(projectDir, name), dcFile(board));
fs.writeFileSync(path.join(projectDir, 'p2-sizes.json'), JSON.stringify(Object.fromEntries(Object.entries(dcBoards).map(([n, b]) => [n, { w: b.w, h: b.h, title: b.title }])), null, 1));

// Print page: previous boards (verbatim markup, isolated in iframes) then pass 2.
MODE = 'print';
const printBoards = buildBoards();
const pages = [];
const blobToFile = Object.fromEntries(Object.entries(ASSETS).map(([rel, blob]) => [blob, pathToFileURL(path.join(ROOT, rel)).href]));
if (previousDir) {
  for (const [name, w, h] of [['Main.dc.html', 1440, 980], ['Paysage.dc.html', 844, 390], ['Portrait.dc.html', 390, 844], ['PortraitCatalogue.dc.html', 390, 844], ['Resultat.dc.html', 1520, 1130]]) {
    let source = fs.readFileSync(path.join(previousDir, name), 'utf8');
    source = source.replace(/\/_blob\/[0-9a-f]{32}/g, (blob) => { if (!blobToFile[blob]) throw new Error('unknown blob ' + blob); return blobToFile[blob]; });
    const helmet = (source.match(/<helmet>([\s\S]*?)<\/helmet>/) || [, ''])[1];
    const markup = source.replace(/^[\s\S]*<x-dc>/, '').replace(/<\/x-dc>[\s\S]*$/, '').replace(/<helmet>[\s\S]*?<\/helmet>/, '');
    pages.push({ w, h, html: `<!doctype html><html><head><meta charset="utf-8">${helmet}</head><body style="margin:0">${markup}</body></html>` });
  }
}
for (const board of Object.values(printBoards)) {
  pages.push({ w: board.w, h: board.h, html: `<!doctype html><html><head><meta charset="utf-8"><link href="https://fonts.googleapis.com/css2?family=Cinzel:wght@600;700&family=Alegreya+Sans:wght@400;500;700&family=Open+Sans:wght@600&display=swap" rel="stylesheet"><style>body{margin:0}${css()}</style></head><body>${board.body}</body></html>` });
}
const attr = (html) => html.replace(/&/g, '&amp;').replace(/"/g, '&quot;');
const printed = `<!doctype html><html lang="fr"><head><meta charset="utf-8"><title>Dungeon Empire — revue UI Forge</title><style>
body{margin:0;background:#0d111b}
${pages.map((p, i) => `@page p${i}{size:${p.w}px ${p.h}px;margin:0}`).join('\n')}
.pg{display:block;border:0;overflow:hidden;break-after:page}
${pages.map((p, i) => `#f${i}{page:p${i};width:${p.w}px;height:${p.h}px}`).join('\n')}
</style></head><body>
${pages.map((p, i) => `<iframe class="pg" id="f${i}" scrolling="no" srcdoc="${attr(p.html)}"></iframe>`).join('\n')}
</body></html>`;
fs.writeFileSync(printHtml, printed);
console.log(`boards: ${Object.keys(dcBoards).length} canvas artboards, ${pages.length} print pages`);
