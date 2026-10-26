// Render only this local UI proposal in a fresh, headless Chrome context.
// Does not connect to the user's browser, Godot editor or saved game.
const path = require('node:path');
const fs = require('node:fs/promises');
const { pathToFileURL } = require('node:url');
const { chromium } = require('playwright');

async function main() {
  const out = path.join(__dirname, 'captures');
  await fs.mkdir(out, { recursive: true });
  const browser = await chromium.launch({
    executablePath: process.env.UI_REVIEW_BROWSER || 'C:/Program Files/Google/Chrome/Application/chrome.exe',
    headless: true,
  });
  const observations = [];
  try {
    for (const [width, height, states] of [
      [844, 390, ['prep', 'build', 'place', 'raid', 'result']],
      [740, 360, ['prep', 'build', 'place', 'result']],
      [1280, 720, ['prep', 'build']],
    ]) {
      const page = await browser.newPage({ viewport: { width, height }, deviceScaleFactor: 1 });
      const errors = [];
      page.on('pageerror', e => errors.push(e.message));
      for (const state of states) {
        await page.goto(pathToFileURL(path.join(__dirname, 'index.html')).href + `?capture=1&state=${state}`);
        await page.locator('.world').evaluate(img => img.decode());
        await page.screenshot({ path: path.join(out, `${width}x${height}-${state}.png`) });
        observations.push(await page.evaluate(({ width, height, state, errors }) => {
          const rect = element => {
            const r = element.getBoundingClientRect();
            return { x: r.x, y: r.y, width: r.width, height: r.height };
          };
          const visible = element => !!element.getClientRects().length;
          const buttons = [...document.querySelectorAll('.game button')].filter(visible).map(el => ({
            label: el.getAttribute('aria-label') || el.textContent.trim(), ...rect(el), disabled: el.disabled,
          }));
          const panels = ['.resources', '.phase', '.utilities', '.catalog', '.placement', '.dialog']
            .map(s => document.querySelector(s)).filter(visible).map(el => ({ class: el.className, ...rect(el) }));
          return { width, height, state, errors, buttons, panels, overflowX: document.documentElement.scrollWidth > width, overflowY: document.documentElement.scrollHeight > height };
        }, { width, height, state, errors }));
      }
      await page.close();
    }
    await fs.writeFile(path.join(out, 'layout-observations.json'), JSON.stringify(observations, null, 2));
    console.log(JSON.stringify({ captures: observations.length, pageErrors: observations.flatMap(o => o.errors), overflow: observations.filter(o => o.overflowX || o.overflowY).map(o => `${o.width}x${o.height}-${o.state}`), smallButtons: observations.flatMap(o => o.buttons.filter(b => b.width < 48 || b.height < 48).map(b => `${o.width}x${o.height}-${o.state}: ${b.label} ${b.width}x${b.height}`)) }, null, 2));
  } finally { await browser.close(); }
}
main().catch(e => { console.error(e); process.exitCode = 1; });
