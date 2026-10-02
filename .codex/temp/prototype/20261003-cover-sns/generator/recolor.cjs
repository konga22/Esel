const fs = require('fs');
const path = require('path');
const ROOT = path.resolve(__dirname, '../../../../..');
const PAINT_DIR = path.resolve(__dirname, '../paint');
const { PNG } = require(path.join(ROOT, 'node_modules/pngjs'));
const src = PNG.sync.read(fs.readFileSync(path.join(PAINT_DIR, 'esel-paint-sage.png')));
const { width: W, height: H, data } = src;
const lum = (r, g, b) => 0.2126 * r + 0.7152 * g + 0.0722 * b;
const ls = [];
for (let i = 0; i < W * H; i++) if (data[i * 4 + 3] > 240) ls.push(lum(data[i * 4], data[i * 4 + 1], data[i * 4 + 2]));
ls.sort((a, b) => a - b);
const Lb = ls[ls.length >> 1];
const colors = {
  coral: '#EE8C76', lilac: '#BBA6D6', terracotta: '#C2643F', burgundy: '#7A2735', olive: '#6F7445',
  cream: '#E9DEC6', charcoal: '#3F4043', camel: '#C1945F', cobalt: '#2648B0',
};
const hex = (h) => [1, 3, 5].map((i) => parseInt(h.slice(i, i + 2), 16));
for (const [name, h] of Object.entries(colors)) {
  const T = hex(h);
  const out = new PNG({ width: W, height: H });
  for (let i = 0; i < W * H; i++) {
    const o = i * 4;
    const a = data[o + 3];
    if (!a) { out.data[o + 3] = 0; continue; }
    const f = lum(data[o], data[o + 1], data[o + 2]) / Lb;
    for (let k = 0; k < 3; k++) {
      const t = T[k];
      out.data[o + k] = Math.round(f <= 1 ? t * f : t + (255 - t) * Math.min(1, (f - 1) * 1.6));
    }
    out.data[o + 3] = a;
  }
  fs.writeFileSync(path.join(PAINT_DIR, `esel-paint-${name}.png`), PNG.sync.write(out));
}
console.log('Lb', Lb.toFixed(1));
