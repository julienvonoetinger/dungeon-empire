// Each output comes from exactly one complete painting. Trim the empty margin
// and reduce uniformly to game resolution, retaining the original perspective.
const assert = require("node:assert/strict");
const fs = require("node:fs/promises");
const path = require("node:path");
const sharp = require("sharp");
const dir = __dirname;

async function prepare(side) {
  const source = path.join(dir, "source", side + ".png");
  const { data, info } = await sharp(source).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  let left = info.width, right = -1, top = info.height, bottom = -1;
  for (let y = 0; y < info.height; y++) {
    for (let x = 0; x < info.width; x++) {
      if (data[(y * info.width + x) * 4 + 3] < 12) continue;
      left = Math.min(left, x); right = Math.max(right, x);
      top = Math.min(top, y); bottom = Math.max(bottom, y);
    }
  }
  assert(right > left && bottom > top, "Empty painting: " + side);
  const crop = { left: Math.max(0, left - 10), top: Math.max(0, top - 10) };
  crop.width = Math.min(info.width, right + 11) - crop.left;
  crop.height = Math.min(info.height, bottom + 11) - crop.top;
  const file = "reserve-" + side + ".png";
  const png = await sharp(source).extract(crop).resize({ width: 338 }).png().toBuffer();
  const { width, height } = await sharp(png).metadata();
  await fs.writeFile(path.join(dir, file), png);
  return { file, pivot: [width / 2, Math.round(height * .66)], width, height, bytes: png.length };
}

async function main() {
  const sides = {};
  for (const side of ["N", "E", "S", "W"]) sides[side] = await prepare(side);
  await fs.writeFile(path.join(dir, "sprites.json"), JSON.stringify(sides, null, 2) + "\n");
}
main().catch(error => { console.error(error); process.exitCode = 1; });
